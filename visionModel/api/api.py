"""
Pet Matching REST API
FastAPI server for lost/found pet matching using vision AI

Endpoints:
- POST /api/v1/lost - Submit a lost pet post
- POST /api/v1/found - Submit a found pet post
- DELETE /api/v1/solvedlost/{id} - Mark lost pet as solved
- DELETE /api/v1/solvedfound/{id} - Mark found pet as solved
- GET /api/v1/health - Health check
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks, UploadFile, File, Form, Header, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any
from datetime import datetime
from pathlib import Path
import sys
import uvicorn
import logging
import json
import numpy as np
import base64
import io
from PIL import Image

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

# Import vision processing and matching
from vision_processor import VisionProcessor
from pet_matching_engine import PetPost, PetMatcher, format_match_result
from database import Database

# API Key Authentication
API_KEY = "RXN0ZXIgRWdn"  # Your secret API key


def verify_api_key(x_api_key: str = Header(..., description="API Key for authentication")):
    """
    Verify API key from request header
    
    Usage: Add header to requests: X-API-Key: RXN0ZXIgRWdn
    """
    if x_api_key != API_KEY:
        logger.warning(f"Invalid API key attempt: {x_api_key[:10]}...")
        raise HTTPException(
            status_code=401,
            detail="Invalid API key. Please provide a valid X-API-Key header."
        )
    return x_api_key

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Pet Matching API",
    description="AI-powered lost & found pet matching system",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware (adjust origins for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global instances
db = Database()
vision_processor = VisionProcessor()
matcher = PetMatcher()

# Pydantic models for request/response
class PetPostRequest(BaseModel):
    """
    Request model for lost/found pet posts
    
    Gender Matching Logic:
    - If both pets have defined gender (male/female) and match: 100% score
    - If both pets have defined gender but differ: 0% score  
    - If either pet has gender='unsure' or None: 50% score (neutral, no penalty)
    """
    id: str = Field(..., description="Unique post ID")
    pet_type: str = Field(..., description="Type of pet: cat, dog, bird, rabbit")
    latitude: float = Field(..., ge=-90, le=90, description="Latitude coordinate")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude coordinate")
    timestamp: datetime = Field(..., description="When pet was lost/found (ISO format)")
    images: List[str] = Field(..., min_items=1, description="Base64 encoded images")
    gender: str = Field(..., description="Pet gender: male, female, or unsure (unsure = neutral matching)")
    description: Optional[str] = Field(None, description="Additional details about the pet")
    
    @validator('pet_type')
    def validate_pet_type(cls, v):
        allowed = ['cat', 'dog', 'bird', 'rabbit']
        if v.lower() not in allowed:
            raise ValueError(f'pet_type must be one of {allowed}')
        return v.lower()
    
    @validator('gender')
    def validate_gender(cls, v):
        allowed = ['male', 'female', 'unsure']
        if v.lower() not in allowed:
            raise ValueError(f'gender must be one of {allowed}')
        return v.lower()
    
    @validator('images')
    def validate_images(cls, v):
        if not v:
            raise ValueError('At least one image is required')
        # Validate that images are valid base64
        for idx, img_b64 in enumerate(v):
            try:
                # Try to decode base64
                img_data = base64.b64decode(img_b64)
                # Try to load as PIL Image
                Image.open(io.BytesIO(img_data))
            except Exception as e:
                raise ValueError(f'Image {idx+1} is not a valid base64 encoded image: {str(e)}')
        return v


class MatchResponse(BaseModel):
    """Response model for match results"""
    match_found: bool
    best_match: Optional[Dict[str, Any]] = None
    all_matches: List[Dict[str, Any]] = []
    post_id: str
    message: str


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    models_loaded: bool
    gpu_available: bool
    db_status: str
    timestamp: datetime


# Background task for processing embeddings
async def process_embeddings_and_match(
    post_data: Dict,
    is_lost: bool,
    db: Database,
    vision_processor: VisionProcessor,
    matcher: PetMatcher
):
    """
    Background task to:
    1. Generate embeddings from images
    2. Save to database
    3. Find matches in opposite database
    """
    try:
        post_id = post_data['id']
        logger.info(f"Processing {'lost' if is_lost else 'found'} post: {post_id}")
        
        # Generate embeddings
        embeddings = vision_processor.process_images(post_data['image_paths'])
        
        if not embeddings:
            logger.error(f"Failed to generate embeddings for {post_id}")
            return
        
        # Save to database
        post_data['embeddings'] = embeddings
        if is_lost:
            db.save_lost_post(post_data)
            logger.info(f"Saved lost post {post_id} with {len(embeddings)} embeddings")
        else:
            db.save_found_post(post_data)
            logger.info(f"Saved found post {post_id} with {len(embeddings)} embeddings")
        
        logger.info(f"Successfully processed post {post_id}")
        
    except Exception as e:
        logger.error(f"Error processing post {post_data.get('id')}: {str(e)}", exc_info=True)


# API Endpoints

@app.post("/api/v1/lost", response_model=MatchResponse)
async def submit_lost_pet(
    request: PetPostRequest,
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """
    Submit a lost pet post
    
    **Authentication Required**: X-API-Key header
    
    Process:
    1. Delete existing post with same ID (acts as update)
    2. Generate embeddings from images
    3. Save to lost_pets database
    4. Search for matches in found_pets database
    5. Return best match if found
    """
    try:
        # Delete existing entry if exists (update functionality)
        db.delete_lost_post(request.id)
        
        # Convert request to dict
        post_data = request.dict()
        
        # Convert base64 images to numpy arrays
        logger.info(f"Processing lost pet images for ID: {request.id}")
        image_arrays = []
        for idx, img_b64 in enumerate(request.images):
            try:
                img_array = vision_processor.base64_to_image(img_b64)
                image_arrays.append(img_array)
            except Exception as e:
                logger.error(f"Failed to decode image {idx+1}: {e}")
        
        if not image_arrays:
            raise HTTPException(
                status_code=400,
                detail="Failed to decode images. Please provide valid base64 encoded images."
            )
        
        # Generate embeddings
        embeddings = vision_processor.process_images(image_arrays)
        
        if not embeddings:
            raise HTTPException(
                status_code=400,
                detail="Failed to process images. No valid pet detections found."
            )
        
        # Save to database
        post_data['embeddings'] = embeddings
        db.save_lost_post(post_data)
        logger.info(f"Saved lost post {request.id} with {len(embeddings)} embeddings")
        
        # Find matches in found_pets
        found_posts = db.get_all_found_posts(pet_type=request.pet_type)
        
        if not found_posts:
            return MatchResponse(
                match_found=False,
                post_id=request.id,
                message="Lost pet posted successfully. No matches found yet."
            )
        
        # Create PetPost object for query
        query_post = PetPost(
            id=request.id,
            pet_type=request.pet_type,
            description=request.description,
            latitude=request.latitude,
            longitude=request.longitude,
            timestamp=request.timestamp,
            neutered=None,
            gender=request.gender if request.gender != 'unsure' else None,
            embeddings=embeddings
        )
        
        # Convert found posts to PetPost objects
        candidate_posts = [
            PetPost(
                id=p['id'],
                pet_type=p['pet_type'],
                description=p.get('description'),
                latitude=p['latitude'],
                longitude=p['longitude'],
                timestamp=p['timestamp'],
                neutered=None,
                gender=p.get('gender'),
                embeddings=p['embeddings']
            )
            for p in found_posts
        ]
        
        # Find matches
        matches = matcher.find_best_matches(
            query_post,
            candidate_posts,
            top_k=5,
            min_confidence=45.0
        )
        
        if not matches:
            return MatchResponse(
                match_found=False,
                post_id=request.id,
                message="Lost pet posted successfully. No matches found."
            )
        
        # Format results
        best_match = format_match_result(matches[0], detailed=True)
        all_matches = [format_match_result(m, detailed=True) for m in matches]
        
        return MatchResponse(
            match_found=True,
            best_match=best_match,
            all_matches=all_matches,
            post_id=request.id,
            message=f"Lost pet posted. Found {len(matches)} potential match(es)!"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in submit_lost_pet: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/found", response_model=MatchResponse)
async def submit_found_pet(
    request: PetPostRequest,
    background_tasks: BackgroundTasks,
    api_key: str = Depends(verify_api_key)
):
    """
    Submit a found pet post
    
    **Authentication Required**: X-API-Key header
    
    Process:
    1. Delete existing post with same ID (acts as update)
    2. Generate embeddings from images
    3. Save to found_pets database
    4. Search for matches in lost_pets database
    5. Return best match if found
    """
    try:
        # Delete existing entry if exists (update functionality)
        db.delete_found_post(request.id)
        
        # Convert request to dict
        post_data = request.dict()
        
        # Convert base64 images to numpy arrays
        logger.info(f"Processing found pet images for ID: {request.id}")
        image_arrays = []
        for idx, img_b64 in enumerate(request.images):
            try:
                img_array = vision_processor.base64_to_image(img_b64)
                image_arrays.append(img_array)
            except Exception as e:
                logger.error(f"Failed to decode image {idx+1}: {e}")
        
        if not image_arrays:
            raise HTTPException(
                status_code=400,
                detail="Failed to decode images. Please provide valid base64 encoded images."
            )
        
        # Generate embeddings
        embeddings = vision_processor.process_images(image_arrays)
        
        if not embeddings:
            raise HTTPException(
                status_code=400,
                detail="Failed to process images. No valid pet detections found."
            )
        
        # Save to database
        post_data['embeddings'] = embeddings
        db.save_found_post(post_data)
        logger.info(f"Saved found post {request.id} with {len(embeddings)} embeddings")
        
        # Find matches in lost_pets
        lost_posts = db.get_all_lost_posts(pet_type=request.pet_type)
        
        if not lost_posts:
            return MatchResponse(
                match_found=False,
                post_id=request.id,
                message="Found pet posted successfully. No matches found yet."
            )
        
        # Create PetPost object for query
        query_post = PetPost(
            id=request.id,
            pet_type=request.pet_type,
            description=request.description,
            latitude=request.latitude,
            longitude=request.longitude,
            timestamp=request.timestamp,
            neutered=None,
            gender=request.gender if request.gender != 'unsure' else None,
            embeddings=embeddings
        )
        
        # Convert lost posts to PetPost objects
        candidate_posts = [
            PetPost(
                id=p['id'],
                pet_type=p['pet_type'],
                description=p.get('description'),
                latitude=p['latitude'],
                longitude=p['longitude'],
                timestamp=p['timestamp'],
                neutered=None,
                gender=p.get('gender'),
                embeddings=p['embeddings']
            )
            for p in lost_posts
        ]
        
        # Find matches
        matches = matcher.find_best_matches(
            query_post,
            candidate_posts,
            top_k=5,
            min_confidence=45.0
        )
        
        if not matches:
            return MatchResponse(
                match_found=False,
                post_id=request.id,
                message="Found pet posted successfully. No matches found."
            )
        
        # Format results
        best_match = format_match_result(matches[0], detailed=True)
        all_matches = [format_match_result(m, detailed=True) for m in matches]
        
        return MatchResponse(
            match_found=True,
            best_match=best_match,
            all_matches=all_matches,
            post_id=request.id,
            message=f"Found pet posted. Found {len(matches)} potential match(es)!"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in submit_found_pet: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/v1/solvedlost/{post_id}")
async def delete_solved_lost(post_id: str, api_key: str = Depends(verify_api_key)):
    """
    Delete a solved lost pet post
    
    **Authentication Required**: X-API-Key header
    
    Use this when:
    - Pet has been found
    - Post is no longer active
    - Optimizes future matching by reducing search space
    """
    try:
        success = db.delete_lost_post(post_id)
        
        if not success:
            raise HTTPException(
                status_code=404,
                detail=f"Lost pet post {post_id} not found"
            )
        
        logger.info(f"Deleted lost post: {post_id}")
        return {
            "success": True,
            "message": f"Lost pet post {post_id} deleted successfully",
            "post_id": post_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting lost post {post_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/api/v1/solvedfound/{post_id}")
async def delete_solved_found(post_id: str, api_key: str = Depends(verify_api_key)):
    """
    Delete a solved found pet post
    
    **Authentication Required**: X-API-Key header
    
    Use this when:
    - Pet has been reunited with owner
    - Post is no longer active
    - Optimizes future matching by reducing search space
    """
    try:
        success = db.delete_found_post(post_id)
        
        if not success:
            raise HTTPException(
                status_code=404,
                detail=f"Found pet post {post_id} not found"
            )
        
        logger.info(f"Deleted found post: {post_id}")
        return {
            "success": True,
            "message": f"Found pet post {post_id} deleted successfully",
            "post_id": post_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting found post {post_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint
    
    Returns:
    - API status
    - Models loaded status
    - GPU availability
    - Database status
    """
    try:
        # Check database
        db_status = "healthy" if db.is_healthy() else "unhealthy"
        
        # Check models
        models_loaded = vision_processor.models_loaded()
        
        # Check GPU
        gpu_available = vision_processor.gpu_available()
        
        status = "healthy" if (db_status == "healthy" and models_loaded) else "degraded"
        
        return HealthResponse(
            status=status,
            models_loaded=models_loaded,
            gpu_available=gpu_available,
            db_status=db_status,
            timestamp=datetime.now()
        )
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}", exc_info=True)
        return HealthResponse(
            status="unhealthy",
            models_loaded=False,
            gpu_available=False,
            db_status="error",
            timestamp=datetime.now()
        )


# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize resources on startup"""
    logger.info("Starting Pet Matching API...")
    
    # Load vision models
    logger.info("Loading vision models...")
    vision_processor.load_models()
    
    # Initialize database
    logger.info("Initializing database...")
    db.initialize()
    
    logger.info("✓ API startup complete")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup resources on shutdown"""
    logger.info("Shutting down Pet Matching API...")
    db.close()
    logger.info("✓ API shutdown complete")


# Run server
if __name__ == "__main__":
    uvicorn.run(
        "api:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
