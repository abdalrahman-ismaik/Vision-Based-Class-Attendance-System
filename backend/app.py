"""
Flask Backend API for Vision-Based Class Attendance System
Provides endpoints for student registration, face recognition, and attendance tracking.
"""

from flask import Flask, request, jsonify, send_from_directory, redirect
from flask_restx import Api, Resource, fields, reqparse
from flask_cors import CORS
from werkzeug.datastructures import FileStorage
from werkzeug.utils import secure_filename
import os
import json
import uuid
from datetime import datetime
from PIL import Image
import logging
import threading
from werkzeug.datastructures import FileStorage as WerkzeugFileStorage

# Import face processing pipeline
from services.face_processing_pipeline import FaceProcessingPipeline

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize face processing pipeline (lazy loading)
_pipeline = None
_pipeline_lock = threading.Lock()

def get_pipeline():
    """Get or initialize face processing pipeline"""
    global _pipeline
    if _pipeline is None:
        with _pipeline_lock:
            if _pipeline is None:
                try:
                    logger.info("Initializing face processing pipeline...")
                    _pipeline = FaceProcessingPipeline()
                    logger.info("Face processing pipeline initialized successfully")
                except Exception as e:
                    logger.error(f"Failed to initialize pipeline: {e}")
                    _pipeline = None
    return _pipeline

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-change-in-production'
app.config['MAX_CONTENT_LENGTH'] = None  # Remove upload size limit

# Configure CORS
CORS(app, resources={r"/api/*": {"origins": "*"}})

# Configure upload folder
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
STUDENT_DATA_FOLDER = os.path.join(UPLOAD_FOLDER, 'students')
PROCESSED_FACES_FOLDER = os.path.join(os.path.dirname(__file__), 'processed_faces')
CLASSIFIERS_FOLDER = os.path.join(os.path.dirname(__file__), 'classifiers')

os.makedirs(STUDENT_DATA_FOLDER, exist_ok=True)
os.makedirs(PROCESSED_FACES_FOLDER, exist_ok=True)
os.makedirs(CLASSIFIERS_FOLDER, exist_ok=True)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['STUDENT_DATA_FOLDER'] = STUDENT_DATA_FOLDER
app.config['PROCESSED_FACES_FOLDER'] = PROCESSED_FACES_FOLDER
app.config['CLASSIFIERS_FOLDER'] = CLASSIFIERS_FOLDER

# Database file (JSON for simplicity, can be replaced with SQLite/PostgreSQL)
DATABASE_FILE = os.path.join(os.path.dirname(__file__), 'database.json')

# Allowed file extensions
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'bmp'}

# Initialize Flask-RESTX API with Swagger documentation
api = Api(
    app,
    version='1.0',
    title='Vision-Based Attendance API',
    description='API for managing students and face recognition-based attendance system',
    doc='/api/docs',  # Swagger UI will be available at /api/docs
    prefix='/api'
)

# Create namespaces
ns_students = api.namespace('students', description='Student management operations')
ns_classes = api.namespace('classes', description='Class management operations')
ns_attendance = api.namespace('attendance', description='Attendance operations')
ns_health = api.namespace('health', description='Health check operations')

# ==================== Models for Swagger Documentation ====================

student_model = api.model('Student', {
    'student_id': fields.String(required=True, description='Unique student ID', example='S12345'),
    'name': fields.String(required=True, description='Student full name', example='John Doe'),
    'email': fields.String(required=False, description='Student email', example='john.doe@university.edu'),
    'department': fields.String(required=False, description='Department', example='Computer Science'),
    'year': fields.Integer(required=False, description='Academic year', example=3),
})

student_response_model = api.model('StudentResponse', {
    'student_id': fields.String(description='Unique student ID'),
    'name': fields.String(description='Student full name'),
    'email': fields.String(description='Student email'),
    'department': fields.String(description='Department'),
    'year': fields.Integer(description='Academic year'),
    'image_path': fields.String(description='Path to student face image'),
    'registered_at': fields.String(description='Registration timestamp'),
    'uuid': fields.String(description='Internal UUID'),
})

class_model = api.model('Class', {
    'class_id': fields.String(required=True, description='Unique class ID', example='CS101'),
    'class_name': fields.String(required=True, description='Class name', example='Introduction to Computer Science'),
    'instructor': fields.String(required=False, description='Instructor name', example='Dr. Smith'),
    'semester': fields.String(required=False, description='Semester', example='Fall 2025'),
    'schedule': fields.String(required=False, description='Class schedule', example='MWF 10:00-11:00'),
})

class_response_model = api.model('ClassResponse', {
    'class_id': fields.String(description='Unique class ID'),
    'class_name': fields.String(description='Class name'),
    'instructor': fields.String(description='Instructor name'),
    'semester': fields.String(description='Semester'),
    'schedule': fields.String(description='Class schedule'),
    'student_ids': fields.List(fields.String, description='List of student IDs enrolled in the class'),
    'created_at': fields.String(description='Creation timestamp'),
    'uuid': fields.String(description='Internal UUID'),
})

# ==================== Helper Functions ====================

def allowed_file(filename):
    """Check if the uploaded file has an allowed extension."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def load_database():
    """Load the student database from JSON file."""
    if os.path.exists(DATABASE_FILE):
        try:
            with open(DATABASE_FILE, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            logger.warning("Database file is corrupted. Starting fresh.")
            return {}
    return {}


def save_database(data):
    """Save the student database to JSON file."""
    with open(DATABASE_FILE, 'w') as f:
        json.dump(data, f, indent=2)


def load_classes():
    """Load the classes database from JSON file."""
    classes_file = os.path.join(os.path.dirname(__file__), 'classes.json')
    if os.path.exists(classes_file):
        try:
            with open(classes_file, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            logger.warning("Classes file is corrupted. Starting fresh.")
            return {}
    return {}


def save_classes(data):
    """Save the classes database to JSON file."""
    classes_file = os.path.join(os.path.dirname(__file__), 'classes.json')
    with open(classes_file, 'w') as f:
        json.dump(data, f, indent=2)


def validate_image(file):
    """Validate the uploaded image file."""
    if not file:
        return False, "No file provided"
    
    if file.filename == '':
        return False, "No file selected"
    
    if not allowed_file(file.filename):
        return False, f"Invalid file type. Allowed types: {', '.join(ALLOWED_EXTENSIONS)}"
    
    return True, "Valid"


def save_student_images(files, student_id):
    """Save multiple student face images to the uploads folder."""
    # Create student-specific folder
    student_folder = os.path.join(app.config['STUDENT_DATA_FOLDER'], student_id)
    os.makedirs(student_folder, exist_ok=True)
    
    saved_paths = []
    errors = []
    
    for idx, file in enumerate(files, 1):
        # Generate unique filename
        ext = file.filename.rsplit('.', 1)[1].lower()
        filename = f"{student_id}_pose{idx}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.{ext}"
        filepath = os.path.join(student_folder, filename)
        
        # Save the file
        file.save(filepath)
        
        # Validate it's a valid image
        try:
            img = Image.open(filepath)
            img.verify()
            logger.info(f"Image {idx} saved successfully: {filepath}")
            saved_paths.append(filepath)
        except Exception as e:
            os.remove(filepath)
            logger.error(f"Invalid image file {idx}: {e}")
            errors.append(f"Image {idx}: {str(e)}")
    
    if len(saved_paths) == 0:
        return None, "No valid images could be saved: " + "; ".join(errors)
    
    return saved_paths, None


# ==================== API Endpoints ====================

@ns_health.route('/status')
class HealthCheck(Resource):
    """Health check endpoint."""
    
    @api.doc('health_check')
    def get(self):
        """Check if the API is running."""
        pipeline = get_pipeline()
        pipeline_status = 'initialized' if pipeline is not None else 'not_initialized'
        
        return {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0',
            'pipeline_status': pipeline_status
        }, 200


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
        """Register a new student with one or more face images (different poses).
        
        Swagger UI Instructions:
        - Fill in student details (student_id, name, etc.)
        - Click "Choose File" to select first image
        - Click "Add string item" button to add more file upload fields
        - Upload multiple images from different angles for better accuracy
        
        Note: The backend automatically handles multiple files sent with the same 'images' field name."""
        try:
            # Get form data
            student_id = request.form.get('student_id')
            name = request.form.get('name')
            email = request.form.get('email', '')
            department = request.form.get('department', '')
            year = request.form.get('year', type=int)
            
            # Validate required fields
            if not student_id or not name:
                return {'error': 'student_id and name are required'}, 400
            
            # Get image files - getlist() handles both single and multiple files
            files = request.files.getlist('images')
            
            # Filter out empty files (Swagger UI sometimes sends empty file objects)
            files = [f for f in files if f and f.filename]
            
            if not files or len(files) == 0:
                return {'error': 'No image files provided. Please select at least one image file.'}, 400
            
            logger.info(f"Received {len(files)} image file(s) for student {student_id}")
            
            # Validate all images
            for idx, file in enumerate(files, 1):
                is_valid, message = validate_image(file)
                if not is_valid:
                    return {'error': f'Image {idx}: {message}'}, 400
            
            # Check if student already exists
            database = load_database()
            if student_id in database:
                return {
                    'error': 'Student already exists',
                    'student_id': student_id
                }, 409
            
            # Save all images
            image_paths, error = save_student_images(files, student_id)
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
                'image_paths': image_paths,  # Now stores list of paths
                'num_poses': len(image_paths),
                'registered_at': datetime.now().isoformat(),
                'processing_status': 'pending'
            }
            
            # Save to database
            database[student_id] = student_data
            save_database(database)
            
            logger.info(f"Student registered successfully: {student_id}")
            
            # Process face in background thread
            def process_face_background():
                try:
                    logger.info(f"Background processing started for {student_id}")
                    
                    # Reload database to ensure we have latest
                    db = load_database()
                    
                    pipeline = get_pipeline()
                    if pipeline is None:
                        logger.error(f"Pipeline not available for {student_id}")
                        db[student_id]['processing_status'] = 'failed'
                        db[student_id]['processing_error'] = 'Pipeline initialization failed'
                        save_database(db)
                        return
                    
                    logger.info(f"Pipeline initialized, starting face processing for {student_id}")
                    
                    # Process student images (multiple poses)
                    result = pipeline.process_student_images(
                        image_paths=image_paths,
                        student_id=student_id,
                        output_dir=app.config['PROCESSED_FACES_FOLDER'],
                        augment_per_image=20
                    )
                    
                    # Reload database again before updating
                    db = load_database()
                    
                    if result:
                        # Update database with processing results
                        db[student_id]['processing_status'] = 'completed'
                        db[student_id]['processed_at'] = datetime.now().isoformat()
                        db[student_id]['num_poses_captured'] = result['num_poses_captured']
                        db[student_id]['num_samples_total'] = result['num_samples_total']
                        db[student_id]['embeddings_path'] = result['embeddings_path']
                        save_database(db)
                        logger.info(f"✓ Face processing completed for {student_id}: {result['num_samples_total']} samples from {result['num_poses_captured']} poses")
                        
                        # Trigger classifier training
                        try:
                            logger.info("Starting classifier training...")
                            classifier_path = os.path.join(app.config['CLASSIFIERS_FOLDER'], 'classifier.pkl')
                            train_result = pipeline.train_classifier_from_data(
                                data_dir=app.config['PROCESSED_FACES_FOLDER'],
                                classifier_output_path=classifier_path
                            )
                            logger.info(f"✓ Classifier training completed. Accuracy: {train_result['metrics'].get('average_test_accuracy', 0):.2f}")
                        except ValueError as ve:
                            logger.warning(f"Skipping classifier training: {ve}")
                        except Exception as e:
                            logger.error(f"Classifier training failed: {e}")

                    else:
                        db[student_id]['processing_status'] = 'failed'
                        db[student_id]['processing_error'] = 'No face detected'
                        save_database(db)
                        logger.warning(f"✗ Face processing failed for {student_id}: No face detected")
                    
                except Exception as e:
                    logger.error(f"✗ Error processing face for {student_id}: {e}", exc_info=True)
                    try:
                        db = load_database()
                        db[student_id]['processing_status'] = 'failed'
                        db[student_id]['processing_error'] = str(e)
                        save_database(db)
                    except:
                        pass
            
            # Start background processing
            thread = threading.Thread(target=process_face_background, daemon=True)
            thread.start()
            logger.info(f"Background thread started for {student_id}")
            
            return {
                'message': 'Student registered successfully. Face processing started in background.',
                'student': student_data
            }, 201
            
        except Exception as e:
            logger.error(f"Error registering student: {e}")
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
        
        # Delete image file if exists
        if 'image_path' in student and os.path.exists(student['image_path']):
            try:
                os.remove(student['image_path'])
                # Remove folder if empty
                folder = os.path.dirname(student['image_path'])
                if os.path.exists(folder) and not os.listdir(folder):
                    os.rmdir(folder)
            except Exception as e:
                logger.warning(f"Could not delete image file: {e}")
        
        # Remove from database
        del database[student_id]
        save_database(database)
        
        logger.info(f"Student deleted: {student_id}")
        
        return {
            'message': 'Student deleted successfully',
            'student_id': student_id
        }, 200


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
            if not os.path.exists(app.config['PROCESSED_FACES_FOLDER']):
                return {'error': 'No processed face data available. Register students first.'}, 400
            
            # Count processed students
            student_dirs = [d for d in os.listdir(app.config['PROCESSED_FACES_FOLDER']) 
                           if os.path.isdir(os.path.join(app.config['PROCESSED_FACES_FOLDER'], d))]
            
            if len(student_dirs) < 2:
                return {
                    'error': 'Need at least 2 students with processed faces to train classifier',
                    'current_count': len(student_dirs)
                }, 400
            
            # Train classifier
            classifier_path = os.path.join(app.config['CLASSIFIERS_FOLDER'], 'classifier.pkl')
            
            logger.info("Starting classifier training...")
            result = pipeline.train_classifier_from_data(
                data_dir=app.config['PROCESSED_FACES_FOLDER'],
                classifier_output_path=classifier_path
            )
            
            # Save training metadata
            metadata = {
                'trained_at': datetime.now().isoformat(),
                'n_students': result['n_students'],
                'n_embeddings': result['n_embeddings'],
                'average_test_accuracy': result['metrics']['average_test_accuracy'],
                'average_test_f1': result['metrics']['average_test_f1'],
                'per_student_metrics': result['metrics']['per_student_metrics'],
                'classifier_path': classifier_path,
                'classifier_type': 'binary_per_student'
            }
            
            metadata_path = os.path.join(app.config['CLASSIFIERS_FOLDER'], 'classifier_metadata.json')
            with open(metadata_path, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            return {
                'message': 'Binary classifiers trained successfully (one per student)',
                'metadata': metadata
            }, 200
            
        except Exception as e:
            logger.error(f"Error training classifier: {e}")
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
            
            # Support both old single image_path and new image_paths list
            image_paths = student.get('image_paths')
            if not image_paths:
                # Fallback to old single image format
                image_path = student.get('image_path')
                if image_path:
                    image_paths = [image_path]
            
            if not image_paths:
                return {'error': 'No student images found'}, 404
            
            # Check if at least one image exists
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
                output_dir=app.config['PROCESSED_FACES_FOLDER'],
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
                
                # Trigger classifier training
                training_info = {}
                try:
                    logger.info("Starting classifier training...")
                    classifier_path = os.path.join(app.config['CLASSIFIERS_FOLDER'], 'classifier.pkl')
                    train_result = pipeline.train_classifier_from_data(
                        data_dir=app.config['PROCESSED_FACES_FOLDER'],
                        classifier_output_path=classifier_path
                    )
                    logger.info(f"✓ Classifier training completed. Accuracy: {train_result['metrics'].get('average_test_accuracy', 0):.2f}")
                    training_info = {'training_status': 'success', 'accuracy': train_result['metrics'].get('average_test_accuracy', 0)}
                except ValueError as ve:
                    logger.warning(f"Skipping classifier training: {ve}")
                    training_info = {'training_status': 'skipped', 'reason': str(ve)}
                except Exception as e:
                    logger.error(f"Classifier training failed: {e}")
                    training_info = {'training_status': 'failed', 'error': str(e)}
                
                return {
                    'message': 'Face processing completed',
                    'result': result,
                    'training': training_info
                }, 200
            else:
                database[student_id]['processing_status'] = 'failed'
                database[student_id]['processing_error'] = 'No faces detected in any image'
                save_database(database)
                
                return {'error': 'No faces detected in any image'}, 400
                
        except Exception as e:
            logger.error(f"Error processing student {student_id}: {e}", exc_info=True)
            try:
                database = load_database()
                database[student_id]['processing_status'] = 'failed'
                database[student_id]['processing_error'] = str(e)
                save_database(database)
            except:
                pass
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
            classifier_path = os.path.join(app.config['CLASSIFIERS_FOLDER'], 'classifier.pkl')
            if not os.path.exists(classifier_path):
                return {
                    'error': 'Classifier not trained yet. Please train the classifier first.',
                    'hint': 'POST to /api/students/train-classifier'
                }, 404
            
            # Load classifier
            pipeline.classifier.load(classifier_path)
            
            # Get image file
            if 'image' not in request.files:
                return {'error': 'No image file provided'}, 400
            
            file = request.files['image']
            
            # Validate image
            is_valid, message = validate_image(file)
            if not is_valid:
                return {'error': message}, 400
            
            # Save temporary file
            temp_dir = os.path.join(app.config['UPLOAD_FOLDER'], 'temp')
            os.makedirs(temp_dir, exist_ok=True)
            
            temp_filename = f"temp_{datetime.now().strftime('%Y%m%d_%H%M%S_%f')}.jpg"
            temp_path = os.path.join(temp_dir, temp_filename)
            file.save(temp_path)
            
            # Recognize face
            # Lower threshold to 0.35 to improve recall for webcams
            result = pipeline.recognize_face(temp_path, threshold=0.35)
            
            # Clean up temp file
            try:
                os.remove(temp_path)
            except:
                pass
            
            # Check for errors
            if 'error' in result:
                return result, 404
            
            # Get student info if recognized
            student_info = None
            if result['prediction']['label'] != 'Unknown':
                database = load_database()
                student_id = result['prediction']['label']
                if student_id in database:
                    student_info = database[student_id]
            
            return {
                'recognized': result['prediction']['label'] != 'Unknown',
                'student_id': result['prediction']['label'],
                'confidence': result['prediction']['confidence'],
                'all_predictions': result['prediction']['all_predictions'],
                'bbox': result['bbox'],
                'student_info': student_info
            }, 200
            
        except Exception as e:
            logger.error(f"Error recognizing face: {e}")
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
            # Check if student exists
            database = load_database()
            if student_id not in database:
                return {'error': 'Student not found'}, 404
            
            # Get pipeline
            pipeline = get_pipeline()
            if pipeline is None:
                return {'error': 'Face processing pipeline not available'}, 500
            
            # Check if classifier is trained
            classifier_path = os.path.join(app.config['CLASSIFIERS_FOLDER'], 'classifier.pkl')
            if not os.path.exists(classifier_path):
                return {
                    'error': 'Classifier not trained yet. Please train the classifier first.',
                    'hint': 'POST to /api/students/train-classifier'
                }, 404
            
            # Load classifier
            pipeline.classifier.load(classifier_path)
            
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
            temp_dir = os.path.join(app.config['UPLOAD_FOLDER'], 'temp')
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


@ns_classes.route('/')
class ClassList(Resource):
    """Endpoint for listing all classes and creating new classes."""
    
    @api.doc('list_classes')
    @api.response(200, 'Success')
    def get(self):
        """Get a list of all classes."""
        classes = load_classes()
        class_list = list(classes.values())
        return {
            'count': len(class_list),
            'classes': class_list
        }, 200
    
    @api.doc('create_class')
    @api.expect(class_model)
    @api.response(201, 'Class created successfully')
    @api.response(400, 'Bad request - validation error')
    @api.response(409, 'Conflict - class already exists')
    def post(self):
        """Create a new class."""
        try:
            data = request.get_json()
            
            # Validate required fields
            class_id = data.get('class_id')
            class_name = data.get('class_name')
            
            if not class_id or not class_name:
                return {'error': 'class_id and class_name are required'}, 400
            
            # Check if class already exists
            classes = load_classes()
            if class_id in classes:
                return {
                    'error': 'Class already exists',
                    'class_id': class_id
                }, 409
            
            # Create class record
            class_uuid = str(uuid.uuid4())
            class_data = {
                'uuid': class_uuid,
                'class_id': class_id,
                'class_name': class_name,
                'instructor': data.get('instructor', ''),
                'semester': data.get('semester', ''),
                'schedule': data.get('schedule', ''),
                'student_ids': [],
                'created_at': datetime.now().isoformat()
            }
            
            # Save to database
            classes[class_id] = class_data
            save_classes(classes)
            
            logger.info(f"Class created successfully: {class_id}")
            
            return {
                'message': 'Class created successfully',
                'class': class_data
            }, 201
            
        except Exception as e:
            logger.error(f"Error creating class: {e}")
            return {'error': f'Internal server error: {str(e)}'}, 500


@ns_classes.route('/<string:class_id>')
@api.doc(params={'class_id': 'The class ID'})
class Class(Resource):
    """Endpoint for individual class operations."""
    
    @api.doc('get_class')
    @api.response(200, 'Success', class_response_model)
    @api.response(404, 'Class not found')
    def get(self, class_id):
        """Get details of a specific class."""
        classes = load_classes()
        
        if class_id not in classes:
            return {'error': 'Class not found'}, 404
        
        return classes[class_id], 200
    
    @api.doc('update_class')
    @api.expect(class_model)
    @api.response(200, 'Class updated successfully')
    @api.response(404, 'Class not found')
    def put(self, class_id):
        """Update a class."""
        classes = load_classes()
        
        if class_id not in classes:
            return {'error': 'Class not found'}, 404
        
        try:
            data = request.get_json()
            class_data = classes[class_id]
            
            # Update fields
            if 'class_name' in data:
                class_data['class_name'] = data['class_name']
            if 'instructor' in data:
                class_data['instructor'] = data['instructor']
            if 'semester' in data:
                class_data['semester'] = data['semester']
            if 'schedule' in data:
                class_data['schedule'] = data['schedule']
            
            class_data['updated_at'] = datetime.now().isoformat()
            
            save_classes(classes)
            
            logger.info(f"Class updated: {class_id}")
            
            return {
                'message': 'Class updated successfully',
                'class': class_data
            }, 200
            
        except Exception as e:
            logger.error(f"Error updating class: {e}")
            return {'error': f'Internal server error: {str(e)}'}, 500
    
    @api.doc('delete_class')
    @api.response(200, 'Class deleted successfully')
    @api.response(404, 'Class not found')
    def delete(self, class_id):
        """Delete a class from the system."""
        classes = load_classes()
        
        if class_id not in classes:
            return {'error': 'Class not found'}, 404
        
        # Remove from database
        del classes[class_id]
        save_classes(classes)
        
        logger.info(f"Class deleted: {class_id}")
        
        return {
            'message': 'Class deleted successfully',
            'class_id': class_id
        }, 200


@ns_classes.route('/<string:class_id>/students')
@api.doc(params={'class_id': 'The class ID'})
class ClassStudents(Resource):
    """Endpoint for managing students in a class."""
    
    @api.doc('get_class_students')
    @api.response(200, 'Success')
    @api.response(404, 'Class not found')
    def get(self, class_id):
        """Get all students enrolled in a class."""
        classes = load_classes()
        
        if class_id not in classes:
            return {'error': 'Class not found'}, 404
        
        class_data = classes[class_id]
        student_ids = class_data.get('student_ids', [])
        
        # Get student details
        students_db = load_database()
        students = []
        for sid in student_ids:
            if sid in students_db:
                students.append(students_db[sid])
        
        return {
            'class_id': class_id,
            'class_name': class_data.get('class_name'),
            'student_count': len(students),
            'students': students
        }, 200
    
    @api.doc('add_student_to_class')
    @api.expect(api.parser().add_argument('student_id', type=str, required=True, location='json', help='Student ID to add'))
    @api.response(200, 'Student added to class successfully')
    @api.response(404, 'Class or student not found')
    @api.response(409, 'Student already enrolled in class')
    def post(self, class_id):
        """Add a student to a class."""
        classes = load_classes()
        
        if class_id not in classes:
            return {'error': 'Class not found'}, 404
        
        try:
            data = request.get_json()
            student_id = data.get('student_id')
            
            if not student_id:
                return {'error': 'student_id is required'}, 400
            
            # Check if student exists
            students_db = load_database()
            if student_id not in students_db:
                return {'error': 'Student not found'}, 404
            
            # Check if student already enrolled
            class_data = classes[class_id]
            if student_id in class_data.get('student_ids', []):
                return {
                    'error': 'Student already enrolled in this class',
                    'student_id': student_id
                }, 409
            
            # Add student to class
            if 'student_ids' not in class_data:
                class_data['student_ids'] = []
            
            class_data['student_ids'].append(student_id)
            class_data['updated_at'] = datetime.now().isoformat()
            
            save_classes(classes)
            
            logger.info(f"Student {student_id} added to class {class_id}")
            
            return {
                'message': 'Student added to class successfully',
                'class_id': class_id,
                'student_id': student_id,
                'student_name': students_db[student_id]['name']
            }, 200
            
        except Exception as e:
            logger.error(f"Error adding student to class: {e}")
            return {'error': f'Internal server error: {str(e)}'}, 500
    
    @api.doc('remove_student_from_class')
    @api.expect(api.parser().add_argument('student_id', type=str, required=True, location='json', help='Student ID to remove'))
    @api.response(200, 'Student removed from class successfully')
    @api.response(404, 'Class or student not found')
    def delete(self, class_id):
        """Remove a student from a class."""
        classes = load_classes()
        
        if class_id not in classes:
            return {'error': 'Class not found'}, 404
        
        try:
            data = request.get_json()
            student_id = data.get('student_id')
            
            if not student_id:
                return {'error': 'student_id is required'}, 400
            
            class_data = classes[class_id]
            
            if student_id not in class_data.get('student_ids', []):
                return {
                    'error': 'Student not enrolled in this class',
                    'student_id': student_id
                }, 404
            
            # Remove student from class
            class_data['student_ids'].remove(student_id)
            class_data['updated_at'] = datetime.now().isoformat()
            
            save_classes(classes)
            
            logger.info(f"Student {student_id} removed from class {class_id}")
            
            return {
                'message': 'Student removed from class successfully',
                'class_id': class_id,
                'student_id': student_id
            }, 200
            
        except Exception as e:
            logger.error(f"Error removing student from class: {e}")
            return {'error': f'Internal server error: {str(e)}'}, 500


@ns_attendance.route('/mark')
class MarkAttendance(Resource):
    """Mark attendance for a student."""
    
    @api.doc('mark_attendance')
    @api.expect(api.parser()
        .add_argument('student_id', type=str, required=True, location='form', help='Student ID')
        .add_argument('course_id', type=str, required=True, location='form', help='Course ID')
        .add_argument('image', type=FileStorage, required=True, location='files', help='Face image for verification'))
    @api.response(200, 'Attendance marked successfully')
    @api.response(404, 'Student not found')
    def post(self):
        """Mark attendance for a student (placeholder - needs face recognition integration)."""
        # This is a placeholder endpoint
        # You'll integrate face recognition here later
        
        student_id = request.form.get('student_id')
        course_id = request.form.get('course_id')
        
        if not student_id or not course_id:
            return {'error': 'student_id and course_id are required'}, 400
        
        database = load_database()
        
        if student_id not in database:
            return {'error': 'Student not found'}, 404
        
        # TODO: Add face recognition verification here
        
        return {
            'message': 'Attendance marked successfully',
            'student_id': student_id,
            'course_id': course_id,
            'timestamp': datetime.now().isoformat(),
            'note': 'Face recognition verification pending implementation'
        }, 200


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
        """Recognize a face and return which student in the given class it matches (if any)."""
        # Parse inputs
        class_id = request.form.get('class_id')
        threshold = request.form.get('threshold', type=float)
        if threshold is None:
            threshold = 0.5

        if not class_id:
            return {'error': 'class_id is required'}, 400

        classes = load_classes()
        if class_id not in classes:
            return {'error': 'Class not found'}, 404

        class_data = classes[class_id]
        student_ids = class_data.get('student_ids', [])

        if len(student_ids) == 0:
            return {'error': 'No students enrolled in this class'}, 400

        # Get image file
        if 'image' not in request.files:
            return {'error': 'No image file provided'}, 400

        file = request.files['image']

        # Validate image
        is_valid, message = validate_image(file)
        if not is_valid:
            return {'error': message}, 400

        # Get pipeline
        pipeline = get_pipeline()
        if pipeline is None:
            return {'error': 'Face processing pipeline not available'}, 500

        # Check if classifier is trained
        classifier_path = os.path.join(app.config['CLASSIFIERS_FOLDER'], 'classifier.pkl')
        if not os.path.exists(classifier_path):
            return {
                'error': 'Classifier not trained yet. Please train the classifier first.',
                'hint': 'POST to /api/students/train-classifier'
            }, 404

        # Load classifier
        pipeline.classifier.load(classifier_path)

        # Filter to students that have classifiers
        available_students = [s for s in student_ids if s in pipeline.classifier.classifiers]

        if len(available_students) == 0:
            return {'error': 'None of the class students have trained classifiers'}, 404

        # Save temporary file
        temp_dir = os.path.join(app.config['UPLOAD_FOLDER'], 'temp')
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

            # Predict restricted to class students
            prediction = pipeline.classifier.predict(embedding, threshold=threshold, allowed_student_ids=available_students)

            # If recognized and student in database, include student info
            recognized = False
            student_info = None
            student_id = prediction.get('label')
            if student_id != 'Unknown':
                database = load_database()
                if student_id in database:
                    student_info = database[student_id]
                    recognized = True

            return {
                'class_id': class_id,
                'recognized': recognized,
                'student_id': student_id,
                'confidence': prediction.get('confidence'),
                'all_predictions': prediction.get('all_predictions'),
                'bbox': [x1, y1, x2, y2],
                'student_info': student_info
            }, 200

        finally:
            try:
                os.remove(temp_path)
            except:
                pass


# ==================== Static Files ====================

@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    """Serve uploaded files."""
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)


# ==================== Error Handlers ====================

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({'error': 'Not found'}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal server error: {error}")
    return jsonify({'error': 'Internal server error'}), 500


# ==================== Root Routes for Easy Verification ====================

@app.route('/')
def index():
    """Root endpoint to verify server is running."""
    return {
        'message': 'Vision-Based Attendance Backend is Running!',
        'docs_url': '/api/docs',
        'health_url': '/api/health/status'
    }, 200

@app.route('/api')
def api_root():
    """Redirect /api to Swagger UI."""
    return redirect('/api/docs')


# ==================== Main ====================

if __name__ == '__main__':
    logger.info("Starting Vision-Based Attendance API...")
    logger.info(f"Upload folder: {UPLOAD_FOLDER}")
    logger.info(f"Database file: {DATABASE_FILE}")
    logger.info("Swagger UI available at: http://localhost:5000/api/docs")
    
    app.run(debug=False, host='0.0.0.0', port=5000)
