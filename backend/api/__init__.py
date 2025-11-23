"""
API Routes and Endpoints
This package contains all Flask API route definitions and resource handlers.

Modules:
- health: Health check and status endpoints
- students: Student management endpoints (TODO)
- classes: Class management endpoints (TODO)
- attendance: Attendance tracking endpoints (TODO)
"""
from .health import health_ns

__all__ = ['health_ns']

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
