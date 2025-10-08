"""
HADIR Frame Selection Microservice
FastAPI service for optimal frame selection with diversity scoring, quality assessment, and pose coverage.
Implements modular computer vision pipeline using OpenCV, scikit-learn, and MediaPipe.
"""

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import logging
from datetime import datetime
import asyncio
import base64

# Import our modular services
from services.frame_extractor import FrameExtractor
from services.quality_assessor import QualityAssessor
from services.pose_analyzer import PoseAnalyzer
from services.diversity_scorer import DiversityScorer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="HADIR Frame Selection Service",
    description="AI-powered frame selection for student registration videos using modular ML pipeline",
    version="2.0.0"
)

# CORS middleware for Flutter app communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify Flutter app origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
frame_extractor = FrameExtractor(max_frames=300)
quality_assessor = QualityAssessor()
pose_analyzer = PoseAnalyzer()
diversity_scorer = DiversityScorer(clustering_method='kmeans')

# Pydantic models for API requests/responses
class FrameAnalysis(BaseModel):
    timestamp: float
    quality_score: float
    pose_angles: Dict[str, float]  # yaw, pitch, roll
    face_confidence: float
    sharpness_score: float
    lighting_score: float
    diversity_score: float
    cluster_id: int

class FrameSelectionRequest(BaseModel):
    quality_threshold: float = 0.6
    pose_diversity_weight: float = 0.8
    target_frame_count: int = 10
    max_processing_time: int = 60  # seconds
    pose_requirements: Optional[Dict[str, int]] = {
        "frontal": 4,
        "left_profile": 3,
        "right_profile": 3
    }

class FrameSelectionResponse(BaseModel):
    success: bool
    message: str
    selected_frames: List[Dict[str, Any]]
    processing_stats: Dict[str, Any]
    total_frames_analyzed: int
    frames_passed_quality: int
    processing_time_seconds: float

class HealthResponse(BaseModel):
    status: str
    version: str
    services: Dict[str, str]
    timestamp: str

# Main frame selection pipeline
class FrameSelectionPipeline:
    """Complete frame selection pipeline using modular services"""
    
    def __init__(self):
        self.extractor = frame_extractor
        self.quality_assessor = quality_assessor
        self.pose_analyzer = pose_analyzer
        self.diversity_scorer = diversity_scorer
    
    async def process_video(self, video_data: bytes, 
                          selection_params: FrameSelectionRequest) -> FrameSelectionResponse:
        """
        Process video through complete pipeline
        
        Args:
            video_data: Raw video bytes
            selection_params: Parameters for frame selection
            
        Returns:
            FrameSelectionResponse with selected frames and stats
        """
        start_time = datetime.now()
        
        try:
            logger.info("Starting frame selection pipeline")
            
            # Step 1: Extract frames from video
            temp_video_path = self.extractor.save_temp_video(video_data)
            frames_with_timestamps = self.extractor.extract_frames(temp_video_path)
            
            logger.info(f"Extracted {len(frames_with_timestamps)} frames")
            
            # Step 2: Assess quality for all frames
            frames_with_quality = []
            for frame, timestamp in frames_with_timestamps:
                quality_data = self.quality_assessor.assess_quality(frame)
                frames_with_quality.append((frame, timestamp, quality_data))
            
            # Step 3: Filter frames by quality threshold
            filtered_frames = self.quality_assessor.filter_quality_frames(
                frames_with_quality, selection_params.quality_threshold
            )
            
            if len(filtered_frames) == 0:
                raise HTTPException(
                    status_code=400,
                    detail="No frames passed quality threshold. Consider lowering quality_threshold."
                )
            
            # Step 4: Analyze poses for filtered frames
            frames_with_poses = []
            for frame, timestamp, quality in filtered_frames:
                pose_data = self.pose_analyzer.analyze_pose(frame)
                frames_with_poses.append((frame, timestamp, quality, pose_data))
            
            # Step 5: Calculate diversity scores
            frames_with_diversity = self.diversity_scorer.calculate_diversity_scores(
                frames_with_poses, n_clusters=min(8, len(frames_with_poses))
            )
            
            # Step 6: Select representative frames
            selected_frames = self.diversity_scorer.select_representative_frames(
                frames_with_diversity,
                target_count=selection_params.target_frame_count,
                pose_requirements=selection_params.pose_requirements
            )
            
            # Step 7: Convert selected frames to response format
            response_frames = []
            for frame, timestamp, quality, pose, diversity in selected_frames:
                # Convert frame to base64 for JSON response
                import cv2
                _, buffer = cv2.imencode('.jpg', frame)
                frame_base64 = base64.b64encode(buffer).decode('utf-8')
                
                frame_data = {
                    "timestamp": timestamp,
                    "quality_metrics": quality,
                    "pose_analysis": pose,
                    "diversity_data": diversity,
                    "frame_data": frame_base64
                }
                response_frames.append(frame_data)
            
            # Clean up temporary file
            self.extractor.cleanup_temp_file(temp_video_path)
            
            # Calculate processing stats
            processing_time = (datetime.now() - start_time).total_seconds()
            
            return FrameSelectionResponse(
                success=True,
                message=f"Successfully selected {len(selected_frames)} frames",
                selected_frames=response_frames,
                processing_stats={
                    "total_extracted": len(frames_with_timestamps),
                    "passed_quality": len(filtered_frames),
                    "clusters_created": len(set(d[4]['cluster'] for d in frames_with_diversity)),
                    "final_selected": len(selected_frames)
                },
                total_frames_analyzed=len(frames_with_timestamps),
                frames_passed_quality=len(filtered_frames),
                processing_time_seconds=processing_time
            )
            
        except Exception as e:
            logger.error(f"Error in frame selection pipeline: {str(e)}")
            # Clean up in case of error
            try:
                self.extractor.cleanup_temp_file(temp_video_path)
            except:
                pass
            
            raise HTTPException(status_code=500, detail=f"Processing error: {str(e)}")

# Initialize pipeline
pipeline = FrameSelectionPipeline()

# API Endpoints
@app.get("/", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        version="2.0.0",
        services={
            "frame_extractor": "operational",
            "quality_assessor": "operational", 
            "pose_analyzer": "operational",
            "diversity_scorer": "operational"
        },
        timestamp=datetime.now().isoformat()
    )

@app.post("/select-frames", response_model=FrameSelectionResponse)
async def select_frames(
    video: UploadFile = File(..., description="Video file for frame selection"),
    quality_threshold: float = Form(0.6, description="Minimum quality threshold (0-1)"),
    target_frame_count: int = Form(10, description="Target number of frames to select"),
    pose_diversity_weight: float = Form(0.8, description="Weight for pose diversity (0-1)"),
    frontal_frames: int = Form(4, description="Required frontal pose frames"),
    left_profile_frames: int = Form(3, description="Required left profile frames"), 
    right_profile_frames: int = Form(3, description="Required right profile frames"),
    max_processing_time: int = Form(60, description="Maximum processing time in seconds")
):
    """
    Select optimal frames from uploaded video using AI-powered analysis
    
    This endpoint implements a complete computer vision pipeline:
    1. Frame extraction using OpenCV
    2. Quality assessment (sharpness, brightness, blur detection)
    3. Pose analysis using YOLOv7-Pose (with OpenCV fallback if model not available)
    4. Diversity scoring using scikit-learn clustering
    5. Representative frame selection with pose coverage requirements
    
    Note: YOLOv7-Pose model is optional. Service will use OpenCV-based pose estimation
    if the model file (yolov7-w6-pose.pt) is not found.
    """
    
    # Validate file type
    if not video.content_type.startswith('video/'):
        raise HTTPException(
            status_code=400, 
            detail="File must be a video file"
        )
    
    # Read video data
    video_data = await video.read()
    
    if len(video_data) == 0:
        raise HTTPException(
            status_code=400,
            detail="Empty video file"
        )
    
    # Create selection parameters
    selection_params = FrameSelectionRequest(
        quality_threshold=quality_threshold,
        target_frame_count=target_frame_count,
        pose_diversity_weight=pose_diversity_weight,
        max_processing_time=max_processing_time,
        pose_requirements={
            "frontal": frontal_frames,
            "left_profile": left_profile_frames,
            "right_profile": right_profile_frames
        }
    )
    
    logger.info(f"Processing video: {len(video_data)} bytes, "
                f"target frames: {target_frame_count}, "
                f"quality threshold: {quality_threshold}")
    
    # Process through pipeline
    return await pipeline.process_video(video_data, selection_params)

@app.get("/api/config")
async def get_config():
    """Get current service configuration"""
    return {
        "max_frames": frame_extractor.max_frames,
        "quality_thresholds": {
            "min_sharpness": quality_assessor.min_sharpness,
            "min_brightness": quality_assessor.min_brightness,
            "max_brightness": quality_assessor.max_brightness
        },
        "clustering_method": diversity_scorer.clustering_method,
        "default_pose_requirements": {
            "frontal": 4,
            "left_profile": 3,
            "right_profile": 3
        }
    }

@app.post("/api/test-frame-analysis")
async def test_frame_analysis(
    image: UploadFile = File(..., description="Single image for testing analysis")
):
    """Test endpoint for analyzing a single frame"""
    
    if not image.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        import cv2
        import numpy as np
        
        # Read image
        image_data = await image.read()
        nparr = np.frombuffer(image_data, np.uint8)
        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if frame is None:
            raise HTTPException(status_code=400, detail="Could not decode image")
        
        # Run analysis
        quality_data = quality_assessor.assess_quality(frame)
        pose_data = pose_analyzer.analyze_pose(frame)
        
        return {
            "quality_analysis": quality_data,
            "pose_analysis": pose_data,
            "message": "Frame analysis completed successfully"
        }
        
    except Exception as e:
        logger.error(f"Error in test frame analysis: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Analysis error: {str(e)}")

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "error": exc.detail,
            "timestamp": datetime.now().isoformat()
        }
    )

# Development server
if __name__ == "__main__":
    import uvicorn
    logger.info("Starting HADIR Frame Selection Service...")
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=8000, 
        reload=True,
        log_level="info"
    )