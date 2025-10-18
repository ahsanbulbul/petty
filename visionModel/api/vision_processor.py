"""
Vision Processing Module
Handles YOLOv8 detection + DINOv2 embedding extraction

This module wraps the vision processing pipeline from the notebook
into a clean API for the REST server.
"""

import torch
import cv2
import numpy as np
from PIL import Image
from pathlib import Path
from typing import List, Optional, Union
import logging
import base64
import io
import os

from ultralytics import YOLO
from transformers import AutoImageProcessor, AutoModel

logger = logging.getLogger(__name__)


class VisionProcessor:
    """Vision processing pipeline for pet re-identification"""
    
    def __init__(self, cache_dir: str = None):
        """
        Initialize vision processor
        
        Args:
            cache_dir: Directory to cache model files (defaults to env MODELS_CACHE or /app/models_cache)
        """
        if cache_dir is None:
            # Check environment variable first, then default
            cache_dir = os.environ.get('MODELS_CACHE', '/app/models_cache')
        
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True, parents=True)
        
        # Force transformers to use our cache directory ONLY
        os.environ['TRANSFORMERS_CACHE'] = str(self.cache_dir)
        os.environ['HF_HOME'] = str(self.cache_dir)
        os.environ['HF_DATASETS_CACHE'] = str(self.cache_dir)
        
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
        # Models (loaded on startup)
        self.detector = None
        self.reid_model = None
        self.processor = None
        
        logger.info(f"VisionProcessor initialized on device: {self.device}")
        logger.info(f"Model cache directory: {self.cache_dir}")
        logger.info(f"Transformers cache forced to: {os.environ['TRANSFORMERS_CACHE']}")
    
    def load_models(self):
        """Load YOLOv8 and DINOv2 models"""
        try:
            # Load YOLOv8 Segmentation
            logger.info("Loading YOLOv8-Seg...")
            yolo_path = self.cache_dir / 'yolov8x-seg.pt'
            
            if yolo_path.exists():
                logger.info(f"Loading YOLOv8-Seg from cache: {yolo_path}")
                self.detector = YOLO(str(yolo_path))
            else:
                logger.warning(f"YOLOv8 model not found at {yolo_path}, downloading...")
                self.detector = YOLO('yolov8x-seg.pt')
                # Save to cache directory for next time
                if self.detector.ckpt_path:
                    import shutil
                    shutil.copy(self.detector.ckpt_path, yolo_path)
                    logger.info(f"Saved YOLOv8 model to {yolo_path}")
            
            self.detector.model.to(self.device)
            logger.info("✓ YOLOv8-Seg loaded")
            
            # Load DINOv2
            logger.info("Loading DINOv2-Large...")
            model_name = 'facebook/dinov2-large'
            
            # Explicitly set cache directory for transformers
            # This ensures models are stored ONLY in our models_cache
            self.processor = AutoImageProcessor.from_pretrained(
                model_name, 
                cache_dir=str(self.cache_dir),
                local_files_only=False,  # Allow download if not cached
                use_fast=True
            )
            self.reid_model = AutoModel.from_pretrained(
                model_name,
                cache_dir=str(self.cache_dir),
                local_files_only=False  # Allow download if not cached
            )
            self.reid_model = self.reid_model.to(self.device)
            self.reid_model.eval()
            
            logger.info("✓ DINOv2-Large loaded")
            logger.info(f"✓ Models cached in: {self.cache_dir}")
            logger.info("✓ All models loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load models: {e}", exc_info=True)
            raise
    
    def detect_pets(self, image_path: str, conf_threshold: float = 0.3) -> List[dict]:
        """
        Detect pets using YOLOv8 segmentation
        
        Args:
            image_path: Path to image file
            conf_threshold: Confidence threshold for detection
            
        Returns:
            List of detections with bounding boxes and masks
        """
        results = self.detector(image_path, conf=conf_threshold, verbose=False)
        detections = []
        
        for result in results:
            if result.masks is None:
                continue
            
            boxes = result.boxes
            masks = result.masks.data.cpu().numpy()
            
            for idx, (box, mask) in enumerate(zip(boxes, masks)):
                class_id = int(box.cls[0])
                class_name = result.names[class_id]
                
                # Filter for cats (15) and dogs (16)
                if class_id not in [15, 16]:
                    continue
                
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                confidence = float(box.conf[0])
                
                detections.append({
                    'bbox': (x1, y1, x2, y2),
                    'class': class_name,
                    'confidence': confidence,
                    'mask': mask
                })
        
        return detections
    
    def preprocess_crop(self, image: np.ndarray, detection: dict, 
                       padding_percent: float = 0.15) -> np.ndarray:
        """
        Advanced preprocessing with background removal and enhancement
        
        Args:
            image: Input image (BGR)
            detection: Detection dictionary with bbox and mask
            padding_percent: Padding around bounding box
            
        Returns:
            Preprocessed cropped image
        """
        x1, y1, x2, y2 = detection['bbox']
        mask = detection['mask']
        
        # Resize mask to image dimensions
        h, w = image.shape[:2]
        mask_resized = cv2.resize(mask, (w, h), interpolation=cv2.INTER_LINEAR)
        mask_binary = (mask_resized > 0.5).astype(np.uint8) * 255
        
        # Create masked image (remove background)
        masked_image = cv2.bitwise_and(image, image, mask=mask_binary)
        
        # Add padding to bounding box
        pad_w = int((x2 - x1) * padding_percent)
        pad_h = int((y2 - y1) * padding_percent)
        
        x1_pad = max(0, x1 - pad_w)
        y1_pad = max(0, y1 - pad_h)
        x2_pad = min(w, x2 + pad_w)
        y2_pad = min(h, y2 + pad_h)
        
        # Crop with padding
        cropped = masked_image[y1_pad:y2_pad, x1_pad:x2_pad]
        
        # CLAHE enhancement on LAB color space
        lab = cv2.cvtColor(cropped, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l_clahe = clahe.apply(l)
        enhanced = cv2.merge([l_clahe, a, b])
        enhanced = cv2.cvtColor(enhanced, cv2.COLOR_LAB2BGR)
        
        return enhanced
    
    def extract_embedding(self, image_bgr: np.ndarray) -> np.ndarray:
        """
        Extract DINOv2 embedding with test-time augmentation
        
        Args:
            image_bgr: Preprocessed image (BGR format)
            
        Returns:
            Normalized embedding vector
        """
        self.reid_model.eval()
        embeddings = []
        
        # Convert BGR to RGB
        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
        pil_image = Image.fromarray(image_rgb)
        
        # Original image
        inputs = self.processor(images=pil_image, return_tensors="pt")
        inputs = {k: v.to(self.device) for k, v in inputs.items()}
        
        with torch.no_grad():
            outputs = self.reid_model(**inputs)
            embedding = outputs.last_hidden_state[:, 0, :].cpu().numpy()[0]
            embeddings.append(embedding)
        
        # Horizontally flipped image (test-time augmentation)
        pil_image_flip = pil_image.transpose(Image.FLIP_LEFT_RIGHT)
        inputs_flip = self.processor(images=pil_image_flip, return_tensors="pt")
        inputs_flip = {k: v.to(self.device) for k, v in inputs_flip.items()}
        
        with torch.no_grad():
            outputs_flip = self.reid_model(**inputs_flip)
            embedding_flip = outputs_flip.last_hidden_state[:, 0, :].cpu().numpy()[0]
            embeddings.append(embedding_flip)
        
        # Average embeddings
        final_embedding = np.mean(embeddings, axis=0)
        
        # Normalize
        final_embedding = final_embedding / np.linalg.norm(final_embedding)
        
        return final_embedding
    
    def base64_to_image(self, base64_string: str) -> np.ndarray:
        """
        Convert base64 encoded image to numpy array (BGR format for OpenCV)
        
        Args:
            base64_string: Base64 encoded image string
            
        Returns:
            Image as numpy array in BGR format
        """
        # Decode base64 to bytes
        img_data = base64.b64decode(base64_string)
        
        # Convert bytes to PIL Image
        pil_image = Image.open(io.BytesIO(img_data))
        
        # Convert to RGB if needed
        if pil_image.mode != 'RGB':
            pil_image = pil_image.convert('RGB')
        
        # Convert to numpy array
        img_array = np.array(pil_image)
        
        # Convert RGB to BGR for OpenCV
        img_bgr = cv2.cvtColor(img_array, cv2.COLOR_RGB2BGR)
        
        return img_bgr
    
    def detect_pets_from_array(self, image: np.ndarray, conf_threshold: float = 0.3) -> List[dict]:
        """
        Detect pets using YOLOv8 segmentation from numpy array
        
        Args:
            image: Image as numpy array (BGR format)
            conf_threshold: Confidence threshold for detection
            
        Returns:
            List of detections with bounding boxes and masks
        """
        results = self.detector(image, conf=conf_threshold, verbose=False)
        detections = []
        
        for result in results:
            if result.masks is None:
                continue
            
            boxes = result.boxes
            masks = result.masks.data.cpu().numpy()
            
            for idx, (box, mask) in enumerate(zip(boxes, masks)):
                class_id = int(box.cls[0])
                class_name = result.names[class_id]
                
                # Filter for cats (15) and dogs (16)
                if class_id not in [15, 16]:
                    continue
                
                x1, y1, x2, y2 = map(int, box.xyxy[0])
                confidence = float(box.conf[0])
                
                detections.append({
                    'bbox': (x1, y1, x2, y2),
                    'class': class_name,
                    'confidence': confidence,
                    'mask': mask
                })
        
        return detections
    
    def process_images(self, image_inputs: List[Union[str, np.ndarray]]) -> List[np.ndarray]:
        """
        Complete processing pipeline for multiple images
        
        Args:
            image_inputs: List of image file paths OR numpy arrays (BGR format)
            
        Returns:
            List of embedding vectors
        """
        all_embeddings = []
        
        for idx, img_input in enumerate(image_inputs):
            try:
                # Handle both file paths and numpy arrays
                if isinstance(img_input, str):
                    logger.info(f"Processing image {idx+1}: file path")
                    # Load image from path
                    image = cv2.imread(str(img_input))
                    if image is None:
                        logger.warning(f"Could not load image: {img_input}")
                        continue
                    # Detect pets
                    detections = self.detect_pets(str(img_input))
                elif isinstance(img_input, np.ndarray):
                    logger.info(f"Processing image {idx+1}: numpy array")
                    image = img_input
                    # Detect pets from array
                    detections = self.detect_pets_from_array(image)
                else:
                    logger.warning(f"Unsupported image input type: {type(img_input)}")
                    continue
                
                if not detections:
                    logger.warning(f"No pets detected in image {idx+1}")
                    continue
                
                logger.info(f"Found {len(detections)} pet(s)")
                
                # Process each detection
                for idx, det in enumerate(detections):
                    # Preprocess
                    processed = self.preprocess_crop(image, det)
                    
                    # Extract embedding
                    embedding = self.extract_embedding(processed)
                    all_embeddings.append(embedding)
                    
                    logger.info(f"Extracted embedding (detection {idx+1})")
                    
            except Exception as e:
                logger.error(f"Error processing image {idx+1}: {e}", exc_info=True)
                continue
        
        return all_embeddings
    
    def models_loaded(self) -> bool:
        """Check if models are loaded"""
        return (self.detector is not None and 
                self.reid_model is not None and 
                self.processor is not None)
    
    def gpu_available(self) -> bool:
        """Check if GPU is available"""
        return torch.cuda.is_available()


# Example usage
if __name__ == "__main__":
    processor = VisionProcessor()
    processor.load_models()
    
    print(f"Models loaded: {processor.models_loaded()}")
    print(f"GPU available: {processor.gpu_available()}")
