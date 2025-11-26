from flask_restx import Api

api = Api(
    version='1.0',
    title='Vision-Based Attendance API',
    description='API for managing students and face recognition-based attendance system',
    doc='/api/docs',
    prefix='/api'
)

