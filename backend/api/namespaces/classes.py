import uuid
import logging
from datetime import datetime
from flask import request
from flask_restx import Resource

from backend.api import api
from backend.api.models import class_model, class_response_model
from backend.database.core import load_classes, save_classes, load_database

logger = logging.getLogger(__name__)

ns_classes = api.namespace('classes', description='Class management operations')

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
        
        return {'message': 'Class deleted successfully'}, 200


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
            else:
                # Student ID exists in class but not in student DB (inconsistency)
                students.append({'student_id': sid, 'name': 'Unknown (Deleted)'})
        
        return {
            'class_id': class_id,
            'count': len(students),
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
            
            # Verify student exists
            students_db = load_database()
            if student_id not in students_db:
                return {'error': 'Student not found'}, 404
            
            class_data = classes[class_id]
            
            # Initialize list if not exists
            if 'student_ids' not in class_data:
                class_data['student_ids'] = []
            
            # Check if already enrolled
            if student_id in class_data['student_ids']:
                return {'error': 'Student already enrolled in class'}, 409
            
            # Add student
            class_data['student_ids'].append(student_id)
            save_classes(classes)
            
            logger.info(f"Student {student_id} added to class {class_id}")
            
            return {
                'message': 'Student added to class successfully',
                'class_id': class_id,
                'student_id': student_id,
                'total_students': len(class_data['student_ids'])
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
            
            if 'student_ids' not in class_data or student_id not in class_data['student_ids']:
                return {'error': 'Student not enrolled in this class'}, 404
            
            # Remove student
            class_data['student_ids'].remove(student_id)
            save_classes(classes)
            
            logger.info(f"Student {student_id} removed from class {class_id}")
            
            return {
                'message': 'Student removed from class successfully',
                'class_id': class_id,
                'student_id': student_id,
                'total_students': len(class_data['student_ids'])
            }, 200
            
        except Exception as e:
            logger.error(f"Error removing student from class: {e}")
            return {'error': f'Internal server error: {str(e)}'}, 500
