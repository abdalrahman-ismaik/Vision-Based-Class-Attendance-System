import os
import logging
from datetime import datetime
from flask import request
from flask_restx import Resource
from werkzeug.datastructures import FileStorage
from PIL import Image

from backend.api import api
from backend.database.core import load_database, load_classes
from backend.utils.files import validate_image
from backend.services.manager import get_pipeline
from backend.config.settings import CLASSIFIERS_FOLDER

logger = logging.getLogger(__name__)

ns_attendance = api.namespace('attendance', description='Attendance operations')

@ns_attendance.route('/mark')
class MarkAttendance(Resource):
    """Mark attendance for a student."""
    
    @api.doc('mark_attendance')
    @api.expect(api.parser()
        .add_argument('student_id', type=str, required=False, location='form', help='Student ID (optional if image provided for recognition)')
        .add_argument('course_id', type=str, required=True, location='form', help='Course ID')
        .add_argument('image', type=FileStorage, required=True, location='files', help='Face image for verification/recognition'))
    @api.response(200, 'Attendance marked successfully')
    @api.response(400, 'Bad request')
    @api.response(404, 'Student not found')
    def post(self):
        """Mark attendance using face recognition."""
        try:
            course_id = request.form.get('course_id')
            student_id = request.form.get('student_id')
            
            if not course_id:
                return {'error': 'course_id is required'}, 400
            
            if 'image' not in request.files:
                return {'error': 'Face image is required'}, 400
            
            file = request.files['image']
            is_valid, message = validate_image(file)
            if not is_valid:
                return {'error': message}, 400
            
            # Save temp file
            from backend.config.settings import UPLOAD_FOLDER
            temp_dir = os.path.join(UPLOAD_FOLDER, 'temp')
            os.makedirs(temp_dir, exist_ok=True)
            temp_path = os.path.join(temp_dir, f"attendance_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg")
            file.save(temp_path)
            
            try:
                # Get pipeline
                pipeline = get_pipeline()
                if pipeline is None:
                    return {'error': 'Face processing pipeline not available'}, 500
                
                # Load classifier if needed
                if not pipeline.classifier.is_trained:
                    classifier_path = os.path.join(CLASSIFIERS_FOLDER, 'classifier.pkl')
                    if os.path.exists(classifier_path):
                        pipeline.classifier.load(classifier_path)
                    else:
                        return {'error': 'System not ready (classifier not trained)'}, 500
                
                # Process image
                image = Image.open(temp_path).convert('RGB')
                bboxes = pipeline.face_detector.detect_faces(image)
                
                if len(bboxes) > 0:
                    # Face detected, crop it
                    bbox = bboxes[0]
                    x1, y1, x2, y2 = map(int, bbox)
                    face_image = image.crop((x1, y1, x2, y2))
                else:
                    # Fallback: Use full image if backend detection fails
                    logger.warning("Backend detection failed, using full input image as face crop")
                    face_image = image

                # Get embedding
                embedding = pipeline.embedding_generator.generate_embedding(face_image)
                
                # Identify student
                if student_id:
                    # Verify specific student
                    result = pipeline.classifier.predict_student(embedding, student_id)
                    if not result['is_match']:
                        return {'error': 'Face does not match provided student ID'}, 401
                    recognized_id = student_id
                    confidence = result['confidence']
                else:
                    # Recognize student
                    result = pipeline.classifier.predict(embedding)
                    if result['label'] == 'Unknown':
                        return {'error': 'Student not recognized'}, 401
                    recognized_id = result['label']
                    confidence = result['confidence']
                
                # Get student details
                database = load_database()
                student = database.get(recognized_id)
                
                if not student:
                    return {'error': f'Student record for {recognized_id} not found'}, 404
                
                # Record attendance (Mock implementation - should save to DB)
                timestamp = datetime.now().isoformat()
                logger.info(f"Attendance marked for {recognized_id} in {course_id} at {timestamp}")
                
                return {
                    'message': 'Attendance marked successfully',
                    'student_id': recognized_id,
                    'student_name': student['name'],
                    'course_id': course_id,
                    'timestamp': timestamp,
                    'confidence': confidence
                }, 200
                
            finally:
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                    
        except Exception as e:
            logger.error(f"Error marking attendance: {e}", exc_info=True)
            return {'error': f'Internal server error: {str(e)}'}, 500


@ns_attendance.route('/class')
class ClassAttendance(Resource):
    """Take attendance for a class by recognizing a face against only that class's students."""

    @api.doc('take_class_attendance')
    @api.expect(api.parser()
        .add_argument('class_id', type=str, required=True, location='form', help='Class ID')
        .add_argument('image', type=FileStorage, required=True, location='files', help='Face image for recognition')
        .add_argument('threshold', type=float, required=False, location='form', help='Confidence threshold (0-1)'))
    @api.response(200, 'Attendance recognition complete')
    @api.response(400, 'Bad request')
    @api.response(404, 'Class or student not found')
    def post(self):
        """Take attendance for a class (recognize face among enrolled students)."""
        try:
            class_id = request.form.get('class_id')
            threshold = float(request.form.get('threshold', 0.5))
            
            if not class_id:
                return {'error': 'class_id is required'}, 400
            
            # Verify class exists
            classes = load_classes()
            if class_id not in classes:
                return {'error': 'Class not found'}, 404
            
            class_data = classes[class_id]
            enrolled_students = class_data.get('student_ids', [])
            
            if not enrolled_students:
                return {'error': 'No students enrolled in this class'}, 400
            
            if 'image' not in request.files:
                return {'error': 'Face image is required'}, 400
            
            file = request.files['image']
            is_valid, message = validate_image(file)
            if not is_valid:
                return {'error': message}, 400
            
            # Save temp file
            from backend.config.settings import UPLOAD_FOLDER
            temp_dir = os.path.join(UPLOAD_FOLDER, 'temp')
            os.makedirs(temp_dir, exist_ok=True)
            temp_path = os.path.join(temp_dir, f"class_attendance_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg")
            file.save(temp_path)
            
            try:
                # Get pipeline
                pipeline = get_pipeline()
                if pipeline is None:
                    return {'error': 'Face processing pipeline not available'}, 500
                
                # Load classifier
                if not pipeline.classifier.is_trained:
                    classifier_path = os.path.join(CLASSIFIERS_FOLDER, 'classifier.pkl')
                    if os.path.exists(classifier_path):
                        pipeline.classifier.load(classifier_path)
                    else:
                        return {'error': 'System not ready (classifier not trained)'}, 500
                
                # Process image
                image = Image.open(temp_path).convert('RGB')
                bboxes = pipeline.face_detector.detect_faces(image)
                
                if len(bboxes) > 0:
                    # Face detected, crop it
                    bbox = bboxes[0]
                    x1, y1, x2, y2 = map(int, bbox)
                    face_image = image.crop((x1, y1, x2, y2))
                else:
                    # Fallback: Use full image if backend detection fails
                    logger.warning("Backend detection failed, using full input image as face crop")
                    face_image = image

                # Get embedding
                embedding = pipeline.embedding_generator.generate_embedding(face_image)
                
                # Recognize against enrolled students only
                result = pipeline.classifier.predict(
                    embedding, 
                    allowed_student_ids=enrolled_students,
                    threshold=threshold
                )
                
                if result['label'] == 'Unknown':
                    return {
                        'match': False,
                        'message': 'Student not recognized among enrolled students',
                        'confidence': result['confidence']
                    }, 200
                
                recognized_id = result['label']
                
                # Get student details
                database = load_database()
                student = database.get(recognized_id)
                
                # Record attendance
                timestamp = datetime.now().isoformat()
                logger.info(f"Class attendance marked for {recognized_id} in {class_id}")
                
                return {
                    'match': True,
                    'student_id': recognized_id,
                    'student_name': student['name'] if student else 'Unknown',
                    'confidence': result['confidence'],
                    'timestamp': timestamp
                }, 200
                
            finally:
                if os.path.exists(temp_path):
                    os.remove(temp_path)
                    
        except Exception as e:
            logger.error(f"Error taking class attendance: {e}", exc_info=True)
            return {'error': f'Internal server error: {str(e)}'}, 500
