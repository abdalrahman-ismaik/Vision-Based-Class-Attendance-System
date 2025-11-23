"""
API Routes and Endpoints
This package contains all Flask API route definitions and resource handlers.
"""

from flask_restx import Api

def init_api(app):
    """Initialize Flask-RESTX API with the Flask app"""
    api = Api(
        app,
        version='1.0',
        title='Vision-Based Attendance System API',
        description='REST API for face recognition-based attendance tracking',
        doc='/api/docs'
    )
    return api
