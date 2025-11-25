from flask_restx import fields
from . import api

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
