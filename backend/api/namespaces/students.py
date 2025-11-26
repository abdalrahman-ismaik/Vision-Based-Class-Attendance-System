import os
import uuid
import logging
from datetime import datetime
from flask import request
from flask_restx import Resource, reqparse
from werkzeug.datastructures import FileStorage
from PIL import Image

from backend.api import api
from backend.api.models import student_model, student_response_model
from backend.database.core import load_database, save_database
from backend.utils.files import validate_image, save_student_images
from backend.services.manager import get_pipeline
from backend.config.settings import PROCESSED_FACES_FOLDER, CLASSIFIERS_FOLDER

logger = logging.getLogger(__name__)

ns_students = api.namespace('students', description='Student management operations')

@ns_students.route('/')
class StudentList(Resource):
    """Endpoint for listing all students and registering new students."""
    
    @api.doc('list_students')
    @api.response(200, 'Success')
    def get(self):
        """Get a list of all registered students."""
        database = load_database()
        students = list(database.values())
        return {
            'count': len(students),
            'students': students
        }, 200
    
    @api.doc('register_student', 
             description='Upload one or more student face images. In Swagger UI, click "Add string item" to upload multiple files.')
    @api.expect(api.parser()
        .add_argument('student_id', type=str, required=True, location='form', help='Student ID')
        .add_argument('name', type=str, required=True, location='form', help='Student Name')
        .add_argument('email', type=str, required=False, location='form', help='Student Email')
        .add_argument('department', type=str, required=False, location='form', help='Department')
        .add_argument('year', type=int, required=False, location='form', help='Academic Year')
        .add_argument('images', type=FileStorage, required=True, location='files', action='append',
                     help='Student face images (different poses for better accuracy). Click "Add string item" below to upload multiple files.'))
    @api.response(201, 'Student registered successfully')
    @api.response(400, 'Bad request - validation error')
    @api.response(409, 'Conflict - student already exists')
    def post(self):
        """Register a new student with one or more face images (different poses)."""
        try:
            # Parse form data
            student_id = request.form.get('student_id')
            name = request.form.get('name')
            email = request.form.get('email', '')
            department = request.form.get('department', '')
            year = request.form.get('year')
            
            if not student_id or not name:
                return {'error': 'student_id and name are required'}, 400
            
            try:
                if year:
                    year = int(year)
            except ValueError:
                return {'error': 'year must be an integer'}, 400
            
            # Check if student already exists
            database = load_database()
            if student_id in database:
                return {
                    'error': 'Student already exists',
                    'student_id': student_id
                }, 409
            
            # Handle file uploads
            files = request.files.getlist('images')
            
            if not files or len(files) == 0:
                return {'error': 'At least one face image is required'}, 400
            
            # Validate and save images
            saved_paths, error = save_student_images(files, student_id)
            
            if error:
                return {'error': error}, 400
            
            # Create student record
            student_uuid = str(uuid.uuid4())
            student_data = {
                'uuid': student_uuid,
                'student_id': student_id,
                'name': name,
                'email': email,
                'department': department,
                'year': year,
                'image_paths': saved_paths,
                'num_poses': len(saved_paths),
                'registered_at': datetime.now().isoformat(),
                'processing_status': 'pending'
            }
            
            # Save to database
            database[student_id] = student_data
            save_database(database)
            
            logger.info(f"Student registered successfully: {student_id} with {len(saved_paths)} images")
            
            # Trigger background processing (optional, or return pending status)
            # For now, we'll just return success and let the user trigger processing or have a background job
            
            # Try to trigger processing immediately if pipeline is available
            try:
                pipeline = get_pipeline()
                if pipeline:
                    # We could run this in a thread, but for now let's keep it simple or use the manual trigger
                    pass
            except:
                pass
            
            return {
                'message': 'Student registered successfully',
                'student': student_data,
                'next_steps': 'Face processing will be triggered automatically or can be triggered manually via /api/students/{id}/process'
            }, 201
            
        except Exception as e:
            logger.error(f"Error registering student: {e}", exc_info=True)
            return {'error': f'Internal server error: {str(e)}'}, 500


@ns_students.route('/<string:student_id>')
@api.doc(params={'student_id': 'The student ID'})
class Student(Resource):
    """Endpoint for individual student operations."""
    
    @api.doc('get_student')
    @api.response(200, 'Success', student_response_model)
    @api.response(404, 'Student not found')
    def get(self, student_id):
        """Get details of a specific student."""
        database = load_database()
        
        if student_id not in database:
            return {'error': 'Student not found'}, 404
        
        return database[student_id], 200
    
    @api.doc('delete_student')
    @api.response(200, 'Student deleted successfully')
    @api.response(404, 'Student not found')
    def delete(self, student_id):
        """Delete a student from the system."""
        database = load_database()
        
        if student_id not in database:
            return {'error': 'Student not found'}, 404
        
        # Remove student data
        student = database[student_id]
        
        # Delete image files if exist (logic simplified, ideally delete the folder)
        # In a real app, we might want to keep them or archive them
        
        # Remove from database
        del database[student_id]
        save_database(database)
        
        logger.info(f"Student deleted: {student_id}")
        
        return {'message': 'Student deleted successfully'}, 200


@ns_students.route('/search')
class StudentSearch(Resource):
    """Search students by name."""
    
    @api.doc('search_students')
    @api.expect(api.parser().add_argument('query', type=str, required=True, location='args', help='Search query'))
    @api.response(200, 'Success')
    def get(self):
        """Search students by name."""
        query = request.args.get('query', '').lower()
        
        if not query:
            return {'error': 'Query parameter is required'}, 400
        
        database = load_database()
        results = []
        
        for student in database.values():
            if query in student['name'].lower() or query in student['student_id'].lower():
                results.append(student)
        
        return {
            'count': len(results),
            'results': results
        }, 200


@ns_students.route('/train-classifier')
class TrainClassifier(Resource):
    """Train face recognition classifier."""
    
    @api.doc('train_classifier')
    @api.response(200, 'Classifier trained successfully')
    @api.response(400, 'Not enough data to train')
    @api.response(500, 'Training failed')
    def post(self):
        """Train face recognition classifier using all processed student faces."""
        try:
            # Get pipeline
            pipeline = get_pipeline()
            if pipeline is None:
                return {'error': 'Face processing pipeline not available'}, 500
            
            # Check if we have processed data
            if not os.path.exists(PROCESSED_FACES_FOLDER):
                return {'error': 'No processed face data available. Register students first.'}, 400
            
            # Count processed students
            student_dirs = [d for d in os.listdir(PROCESSED_FACES_FOLDER) 
                           if os.path.isdir(os.path.join(PROCESSED_FACES_FOLDER, d))]
            
            if len(student_dirs) < 2:
                return {
                    'error': 'Need at least 2 students with processed faces to train classifier',
                    'current_count': len(student_dirs)
                }, 400
            
            # Train classifier
            classifier_path = os.path.join(CLASSIFIERS_FOLDER, 'face_classifier.pkl')
            
            logger.info("Starting classifier training...")
            result = pipeline.train_classifier_from_data(
                data_dir=PROCESSED_FACES_FOLDER,
                classifier_output_path=classifier_path
            )
            
            return {
                'message': 'Classifier trained successfully',
                'metrics': result['metrics'],
                'n_students': result['n_students'],
                'n_embeddings': result['n_embeddings']
            }, 200
            
        except Exception as e:
            logger.error(f"Error training classifier: {e}", exc_info=True)
            return {'error': f'Training failed: {str(e)}'}, 500


@ns_students.route('/<string:student_id>/process')
@api.doc(params={'student_id': 'The student ID'})
class ProcessStudentFace(Resource):
    """Manually trigger face processing for a student."""
    
    @api.doc('process_student_face')
    @api.response(200, 'Processing completed')
    @api.response(404, 'Student not found')
    @api.response(500, 'Processing failed')
    def post(self, student_id):
        """Manually process student faces (synchronous for debugging)."""
        try:
            database = load_database()
            if student_id not in database:
                return {'error': 'Student not found'}, 404
            
            student = database[student_id]
            image_paths = student.get('image_paths', [])
            
            # Fallback for old data format
            if not image_paths and 'image_path' in student:
                image_paths = [student['image_path']]
            
            # Filter existing paths
            existing_paths = [p for p in image_paths if os.path.exists(p)]
            
            if len(existing_paths) == 0:
                return {'error': 'No student image files found on disk'}, 404
            
            logger.info(f"Manual processing triggered for {student_id} ({len(existing_paths)} images)")
            
            # Get pipeline
            pipeline = get_pipeline()
            if pipeline is None:
                return {'error': 'Face processing pipeline not available'}, 500
            
            logger.info(f"Pipeline ready, processing {len(existing_paths)} images")
            
            # Process student images (synchronous)
            result = pipeline.process_student_images(
                image_paths=existing_paths,
                student_id=student_id,
                output_dir=PROCESSED_FACES_FOLDER,
                augment_per_image=20
            )
            
            if result:
                # Update database
                database[student_id]['processing_status'] = 'completed'
                database[student_id]['processed_at'] = datetime.now().isoformat()
                database[student_id]['num_poses_captured'] = result['num_poses_captured']
                database[student_id]['num_samples_total'] = result['num_samples_total']
                database[student_id]['embeddings_path'] = result['embeddings_path']
                save_database(database)
                
                logger.info(f"✓ Processing completed for {student_id}")
                
                return {
                    'message': 'Processing completed successfully',
                    'details': {
                        'num_poses': result['num_poses_captured'],
                        'total_samples': result['num_samples_total'],
                        'embeddings_path': result['embeddings_path']
                    }
                }, 200
            else:
                return {'error': 'Processing failed (no faces detected or other error)'}, 500
                
        except Exception as e:
            logger.error(f"Error processing student: {e}", exc_info=True)
            return {'error': f'Processing failed: {str(e)}'}, 500


@ns_students.route('/recognize')
class RecognizeFace(Resource):
    """Recognize face in uploaded image."""
    
    @api.doc('recognize_face')
    @api.expect(api.parser().add_argument('image', type=FileStorage, required=True, location='files', help='Face image to recognize'))
    @api.response(200, 'Face recognized')
    @api.response(400, 'Bad request')
    @api.response(404, 'No face detected or classifier not trained')
    def post(self):
        """Recognize a face in an uploaded image using all binary classifiers."""
        try:
            # Get pipeline
            pipeline = get_pipeline()
            if pipeline is None:
                return {'error': 'Face processing pipeline not available'}, 500
            
            # Check if classifier is trained
            if not pipeline.classifier.is_trained:
                # Try to load if exists
                classifier_path = os.path.join(CLASSIFIERS_FOLDER, 'face_classifier.pkl')
                if os.path.exists(classifier_path):
                    pipeline.classifier.load(classifier_path)
                else:
                    return {
                        'error': 'Classifier not trained yet',
                        'hint': 'POST to /api/students/train-classifier'
                    }, 404
            
            # Get image file
            if 'image' not in request.files:
                return {'error': 'No image file provided'}, 400
            
            file = request.files['image']
            
            # Validate image
            is_valid, message = validate_image(file)
            if not is_valid:
                return {'error': message}, 400
            
            # Save temporary file
            # We need UPLOAD_FOLDER from config, but we can just use tempfile or a temp dir
            # Let's import UPLOAD_FOLDER from config
            from backend.config.settings import UPLOAD_FOLDER
            temp_dir = os.path.join(UPLOAD_FOLDER, 'temp')
            os.makedirs(temp_dir, exist_ok=True)
            
            temp_filename = f"temp_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}.jpg"
            temp_path = os.path.join(temp_dir, temp_filename)
            file.save(temp_path)
            
            try:
                # Detect face and get embedding
                image = Image.open(temp_path).convert('RGB')
                bboxes = pipeline.face_detector.detect_faces(image)
                
                if len(bboxes) == 0:
                    return {'error': 'No face detected in image'}, 404
                
                # Process first face
                bbox = bboxes[0]
                x1, y1, x2, y2 = map(int, bbox)
                
                # Add margin
                w = x2 - x1
                h = y2 - y1
                margin = 0.2
                x1 = max(0, x1 - int(w * margin))
                y1 = max(0, y1 - int(h * margin))
                x2 = min(image.width, x2 + int(w * margin))
                y2 = min(image.height, y2 + int(h * margin))
                
                # Crop face
                face_image = image.crop((x1, y1, x2, y2))
                
                # Generate embedding
                embedding = pipeline.embedding_generator.generate_embedding(face_image)
                
                # Recognize using binary classifiers
                result = pipeline.classifier.predict(embedding, threshold=0.6)
                
                # Get student info if match found
                student_info = None
                if result['label'] != 'Unknown':
                    database = load_database()
                    student_info = database.get(result['label'])
                
                return {
                    'match': result['label'] != 'Unknown',
                    'student_id': result['label'],
                    'student_info': student_info,
                    'confidence': result['confidence'],
                    'threshold': result['threshold_used'],
                    'all_predictions': result.get('all_predictions', {}),
                    'bbox': [x1, y1, x2, y2]
                }, 200
                
            finally:
                # Clean up temp file
                try:
                    os.remove(temp_path)
                except:
                    pass
            
        except Exception as e:
            logger.error(f"Error recognizing face: {e}", exc_info=True)
            return {'error': f'Recognition failed: {str(e)}'}, 500


@ns_students.route('/<string:student_id>/verify')
@api.doc(params={'student_id': 'The student ID to verify against'})
class VerifyStudentFace(Resource):
    """Verify if uploaded face matches a specific student."""
    
    @api.doc('verify_student_face')
    @api.expect(api.parser().add_argument('image', type=FileStorage, required=True, location='files', help='Face image to verify'))
    @api.response(200, 'Verification complete')
    @api.response(400, 'Bad request')
    @api.response(404, 'Student or classifier not found')
    def post(self, student_id):
        """Verify if a face matches a specific student using their binary classifier."""
        try:
            database = load_database()
            if student_id not in database:
                return {'error': 'Student not found'}, 404
            
            # Get pipeline
            pipeline = get_pipeline()
            if pipeline is None:
                return {'error': 'Face processing pipeline not available'}, 500
            
            # Check if classifier is trained
            if not pipeline.classifier.is_trained:
                # Try to load if exists
                classifier_path = os.path.join(CLASSIFIERS_FOLDER, 'face_classifier.pkl')
                if os.path.exists(classifier_path):
                    pipeline.classifier.load(classifier_path)
                else:
                    return {
                        'error': 'Classifier not trained yet',
                        'hint': 'POST to /api/students/train-classifier'
                    }, 404
            
            # Check if this student has a classifier
            if student_id not in pipeline.classifier.classifiers:
                return {
                    'error': f'No classifier found for student {student_id}',
                    'hint': 'Student may not have been included in training'
                }, 404
            
            # Get image file
            if 'image' not in request.files:
                return {'error': 'No image file provided'}, 400
            
            file = request.files['image']
            
            # Validate image
            is_valid, message = validate_image(file)
            if not is_valid:
                return {'error': message}, 400
            
            # Save temporary file
            from backend.config.settings import UPLOAD_FOLDER
            temp_dir = os.path.join(UPLOAD_FOLDER, 'temp')
            os.makedirs(temp_dir, exist_ok=True)
            
            temp_filename = f"temp_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}.jpg"
            temp_path = os.path.join(temp_dir, temp_filename)
            file.save(temp_path)
            
            try:
                # Detect face and get embedding
                image = Image.open(temp_path).convert('RGB')
                bboxes = pipeline.face_detector.detect_faces(image)
                
                if len(bboxes) == 0:
                    return {'error': 'No face detected in image'}, 404
                
                # Process first face
                bbox = bboxes[0]
                x1, y1, x2, y2 = map(int, bbox)
                
                # Add margin
                w = x2 - x1
                h = y2 - y1
                margin = 0.2
                x1 = max(0, x1 - int(w * margin))
                y1 = max(0, y1 - int(h * margin))
                x2 = min(image.width, x2 + int(w * margin))
                y2 = min(image.height, y2 + int(h * margin))
                
                # Crop face
                face_image = image.crop((x1, y1, x2, y2))
                
                # Generate embedding
                embedding = pipeline.embedding_generator.generate_embedding(face_image)
                
                # Verify against specific student
                result = pipeline.classifier.predict_student(embedding, student_id, threshold=0.5)
                
                # Get student info
                student_info = database[student_id]
                
                return {
                    'student_id': student_id,
                    'student_name': student_info.get('name'),
                    'is_match': result['is_match'],
                    'confidence': result['confidence'],
                    'threshold': result['threshold_used'],
                    'bbox': [x1, y1, x2, y2]
                }, 200
                
            finally:
                # Clean up temp file
                try:
                    os.remove(temp_path)
                except:
                    pass
            
        except Exception as e:
            logger.error(f"Error verifying face: {e}", exc_info=True)
            return {'error': f'Verification failed: {str(e)}'}, 500
