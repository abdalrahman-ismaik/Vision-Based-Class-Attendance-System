from flask_restx import Resource
from backend.api import api
from backend.services.manager import get_pipeline

ns_health = api.namespace('health', description='Health check operations')

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
            'pipeline_status': pipeline_status
        }, 200
