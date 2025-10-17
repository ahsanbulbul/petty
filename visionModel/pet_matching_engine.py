"""
Pet Re-Identification Matching System (Database-Optimized)
Efficient matching with precomputed embeddings and exponential decay scoring

Design Principles:
1. Embeddings are precomputed and stored in database
2. Distance scoring uses exponential decay (closer = exponentially better)
3. Time scoring uses exponential decay (recent = exponentially better)
4. Clean data model with only essential matching fields
5. Efficient batch matching for real-time queries
"""

import numpy as np
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
import math


@dataclass
class PetPost:
    """
    Minimal data structure for a pet post (only matching essentials)
    
    Note: Contact info, image URLs, etc. are stored in main database
    but not needed for matching computation
    """
    id: str
    pet_type: str  # 'cat' or 'dog'
    description: Optional[str]  # Special markings, patterns, etc.
    latitude: float
    longitude: float
    timestamp: datetime
    neutered: Optional[bool]
    gender: Optional[str]  # 'male', 'female', or None
    
    # Precomputed embeddings (loaded from database)
    embeddings: List[np.ndarray]  # DINOv2 embeddings (already computed)


@dataclass
class MatchResult:
    """
    Result of matching operation
    """
    query_id: str
    matched_id: str
    confidence: float  # 0-100
    match_score: float  # Raw score before normalization
    
    # Breakdown of score components
    visual_similarity: float
    location_score: float
    time_score: float
    metadata_score: float
    
    # Match decision
    is_match: bool
    match_category: str  # 'high', 'medium', 'low', 'no_match'
    
    # Additional info
    distance_km: float
    time_diff_hours: float
    pet_type: str


class PetMatchingConfig:
    """
    Configuration for matching algorithm with exponential decay
    
    Weighting system:
    - Visual (image match): 50%
    - Time: 20%
    - Location: 20%
    - Gender: 10%
    - Final score multiplied by pet_type match (1.0 if match, 0.0 if mismatch)
    """
    # Component weights (must sum to 1.0)
    WEIGHT_VISUAL = 0.50        # Image matching
    WEIGHT_TIME = 0.20          # Time proximity
    WEIGHT_LOCATION = 0.20      # Location proximity
    WEIGHT_GENDER = 0.10        # Gender matching
    
    # Visual similarity thresholds (DINOv2)
    VISUAL_THRESHOLD_HIGH = 0.75   # Very confident match
    VISUAL_THRESHOLD_MEDIUM = 0.65  # Probable match
    VISUAL_THRESHOLD_LOW = 0.55     # Possible match
    
    # Distance exponential decay parameters
    DISTANCE_PERFECT_MATCH_KM = 10.0  # Within 10km = 100% match (no decay)
    DISTANCE_HALF_LIFE_KM = 15.0    # After perfect zone, distance where score drops to 50%
    # Score formula: 
    # - If distance <= 10km: 100 (perfect match)
    # - If distance > 10km: 100 * exp(-ln(2) * (distance - 10) / half_life)
    # Examples: 0-10km=100, 15km=84.1, 25km=50, 40km=17.8, 55km=6.3, 100km=0.4
    
    # Time exponential decay parameters  
    TIME_MAX_DAYS = 90              # Hard cutoff - don't match >3 months old
    TIME_PERFECT_MATCH_DAYS = 3.0   # Within 3 days = 100% match (no decay)
    TIME_HALF_LIFE_DAYS = 14.0      # After perfect zone, time where score drops to 50%
    # Score formula:
    # - If time_diff <= 3 days: 100 (perfect match)
    # - If time_diff > 3 days: 100 * exp(-ln(2) * (days - 3) / half_life)
    # Examples: 0-3d=100, 10d=72.5, 17d=50, 31d=17.8, 45d=6.3, 90d=0
    
    # Final confidence thresholds
    CONFIDENCE_HIGH = 75.0          # High confidence match
    CONFIDENCE_MEDIUM = 60.0        # Medium confidence match
    CONFIDENCE_LOW = 45.0           # Low confidence match


class PetMatcher:
    """
    Main matching engine that combines visual similarity with metadata
    """
    
    def __init__(self, config: Optional[PetMatchingConfig] = None):
        """
        Initialize matcher with optional custom configuration
        
        Args:
            config: Custom configuration, uses defaults if None
        """
        self.config = config or PetMatchingConfig()
        
    def calculate_distance_km(self, lat1: float, lon1: float, 
                             lat2: float, lon2: float) -> float:
        """
        Calculate distance between two coordinates using Haversine formula
        
        Args:
            lat1, lon1: First coordinate
            lat2, lon2: Second coordinate
            
        Returns:
            Distance in kilometers
        """
        R = 6371  # Earth's radius in kilometers
        
        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)
        
        a = (math.sin(delta_lat / 2) ** 2 + 
             math.cos(lat1_rad) * math.cos(lat2_rad) * 
             math.sin(delta_lon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        
        return R * c
    
    def compute_visual_similarity(self, embeddings1: List[np.ndarray], 
                                 embeddings2: List[np.ndarray],
                                 aggregation: str = 'max') -> float:
        """
        Compute visual similarity between two sets of embeddings
        Uses multi-image approach for robustness
        
        Args:
            embeddings1: List of embeddings from first pet
            embeddings2: List of embeddings from second pet
            aggregation: How to combine multiple comparisons ('max', 'mean', 'top2_mean')
            
        Returns:
            Similarity score (0-1)
        """
        similarities = []
        
        for emb1 in embeddings1:
            for emb2 in embeddings2:
                # Cosine similarity
                sim = np.dot(emb1, emb2) / (np.linalg.norm(emb1) * np.linalg.norm(emb2))
                similarities.append(float(sim))
        
        if not similarities:
            return 0.0
        
        # Aggregate multiple similarities
        if aggregation == 'max':
            return max(similarities)
        elif aggregation == 'mean':
            return np.mean(similarities)
        elif aggregation == 'top2_mean':
            top_scores = sorted(similarities, reverse=True)[:2]
            return np.mean(top_scores)
        else:
            return max(similarities)
    
    def score_visual_component(self, visual_sim: float) -> float:
        """
        Convert raw visual similarity to normalized score (0-100)
        
        Args:
            visual_sim: Raw similarity from DINOv2 (0-1)
            
        Returns:
            Normalized score (0-100)
        """
        # DINOv2 typically gives 0.65-0.85 for matches
        # Map this range to higher scores
        
        if visual_sim >= self.config.VISUAL_THRESHOLD_HIGH:
            # Very strong match: map 0.75-1.0 to 85-100
            return 85 + (visual_sim - 0.75) * 60
        elif visual_sim >= self.config.VISUAL_THRESHOLD_MEDIUM:
            # Good match: map 0.65-0.75 to 70-85
            return 70 + (visual_sim - 0.65) * 150
        elif visual_sim >= self.config.VISUAL_THRESHOLD_LOW:
            # Possible match: map 0.55-0.65 to 50-70
            return 50 + (visual_sim - 0.55) * 200
        else:
            # Weak match: map 0-0.55 to 0-50
            return visual_sim * 90.9
    
    def score_location_component(self, distance_km: float) -> float:
        """
        Score based on geographic proximity using EXPONENTIAL DECAY
        
        Key insight: Pets typically stay VERY close. Within 10km radius is 
        considered perfect match (100%), then exponential decay applies.
        No hard cutoff - exponential decay naturally handles extreme distances.
        
        Formula:
        - If distance <= 10km: 100 (perfect match zone)
        - If distance > 10km: 100 * exp(-ln(2) * (distance - 10) / half_life)
        
        Examples (perfect_zone=10km, half_life=15km):
        - 0-10 km:  100.0 points (perfect match zone)
        - 15 km:     84.1 points (just outside perfect zone)
        - 25 km:     50.0 points (half score)
        - 40 km:     17.8 points (very unlikely)
        - 55 km:      6.3 points (extremely unlikely)
        - 100 km:     0.4 points (practically zero)
        
        Args:
            distance_km: Distance between posts in kilometers
            
        Returns:
            Location score (0-100)
        """
        # Perfect match zone: within 10km
        if distance_km <= self.config.DISTANCE_PERFECT_MATCH_KM:
            return 100.0
        
        # Exponential decay beyond perfect zone (no hard cutoff)
        excess_distance = distance_km - self.config.DISTANCE_PERFECT_MATCH_KM
        decay_factor = -math.log(2) * excess_distance / self.config.DISTANCE_HALF_LIFE_KM
        score = 100.0 * math.exp(decay_factor)
        
        # Still clamp to ensure valid range
        return max(0.0, min(100.0, score))
    
    def score_time_component(self, time_diff_hours: float) -> float:
        """
        Score based on time window using EXPONENTIAL DECAY
        
        Key insight: Recent posts are MUCH more relevant. Within 3 days is 
        considered perfect match (100%), then exponential decay applies.
        
        Formula:
        - If time_diff <= 3 days: 100 (perfect match zone)
        - If time_diff > 3 days: 100 * exp(-ln(2) * (days - 3) / half_life)
        
        Examples (perfect_zone=3 days, half_life=14 days):
        - 0-3 days:  100.0 points (perfect match zone)
        - 10 days:    72.5 points (recent)
        - 17 days:    50.0 points (half score)
        - 31 days:    17.8 points (getting old)
        - 45 days:     6.3 points (quite old)
        - 90 days:     0.0 points (hard cutoff)
        
        Args:
            time_diff_hours: Time difference in hours
            
        Returns:
            Time score (0-100)
        """
        time_diff_days = time_diff_hours / 24.0
        
        if time_diff_days > self.config.TIME_MAX_DAYS:
            return 0.0
        
        # Perfect match zone: within 3 days
        if time_diff_days <= self.config.TIME_PERFECT_MATCH_DAYS:
            return 100.0
        
        # Exponential decay beyond perfect zone
        excess_days = time_diff_days - self.config.TIME_PERFECT_MATCH_DAYS
        decay_factor = -math.log(2) * excess_days / self.config.TIME_HALF_LIFE_DAYS
        score = 100.0 * math.exp(decay_factor)
        
        return max(0.0, min(100.0, score))
    
    def score_metadata_component(self, post1: PetPost, post2: PetPost) -> float:
        """
        Gender scoring (10% weight)
        
        Args:
            post1, post2: Pet posts to compare
            
        Returns:
            Gender score (0-100)
        """
        # If both have gender info and they match = 100
        # If both have gender info and mismatch = 0
        # If either missing gender info = 50 (neutral)
        
        if post1.gender and post2.gender:
            if post1.gender.lower() == post2.gender.lower():
                return 100.0  # Perfect match
            else:
                return 0.0    # Mismatch
        else:
            return 50.0  # Neutral when info missing
    
    def match(self, query_post: PetPost, candidate_post: PetPost,
              aggregation: str = 'max') -> MatchResult:
        """
        Main matching function - combines all components
        
        Scoring logic:
        1. Compute weighted score: 50% visual + 20% time + 20% location + 10% gender
        2. Multiply by pet_type match (1.0 if same type, 0.0 if different)
        
        Args:
            query_post: Query pet (lost or found)
            candidate_post: Candidate pet (opposite type)
            aggregation: How to combine multi-image similarities
            
        Returns:
            MatchResult with detailed scoring breakdown
        """
        # Pet type multiplier: 1.0 if match, 0.0 if mismatch
        pet_type_multiplier = 1.0 if query_post.pet_type.lower() == candidate_post.pet_type.lower() else 0.0
        
        if pet_type_multiplier == 0.0:
            return self._create_no_match_result(query_post, candidate_post, 
                                               reason="Pet type mismatch")
        
        # Check embeddings exist
        if not query_post.embeddings or not candidate_post.embeddings:
            return self._create_no_match_result(query_post, candidate_post,
                                               reason="Missing embeddings")
        
        # 1. Visual Similarity (50% weight)
        visual_sim = self.compute_visual_similarity(
            query_post.embeddings,
            candidate_post.embeddings,
            aggregation
        )
        visual_score = self.score_visual_component(visual_sim)
        
        # 2. Time Score (20% weight)
        time_diff = abs((query_post.timestamp - candidate_post.timestamp).total_seconds() / 3600)
        time_score = self.score_time_component(time_diff)
        
        # 3. Location Score (20% weight)
        distance_km = self.calculate_distance_km(
            query_post.latitude, query_post.longitude,
            candidate_post.latitude, candidate_post.longitude
        )
        location_score = self.score_location_component(distance_km)
        
        # 4. Gender Score (10% weight)
        gender_score = self.score_metadata_component(query_post, candidate_post)
        
        # Weighted combination (50% + 20% + 20% + 10% = 100%)
        weighted_score = (
            self.config.WEIGHT_VISUAL * visual_score +
            self.config.WEIGHT_TIME * time_score +
            self.config.WEIGHT_LOCATION * location_score +
            self.config.WEIGHT_GENDER * gender_score
        )
        
        # Apply pet_type multiplier (0.0 or 1.0)
        final_score = weighted_score * pet_type_multiplier
        final_score = max(0.0, min(100.0, final_score))  # Clamp to 0-100
        
        # Determine match category
        if final_score >= self.config.CONFIDENCE_HIGH:
            is_match = True
            category = 'high'
        elif final_score >= self.config.CONFIDENCE_MEDIUM:
            is_match = True
            category = 'medium'
        elif final_score >= self.config.CONFIDENCE_LOW:
            is_match = False  # Too uncertain
            category = 'low'
        else:
            is_match = False
            category = 'no_match'
        
        return MatchResult(
            query_id=query_post.id,
            matched_id=candidate_post.id,
            confidence=final_score,
            match_score=weighted_score,
            visual_similarity=visual_sim,
            location_score=location_score,
            time_score=time_score,
            metadata_score=gender_score,
            is_match=is_match,
            match_category=category,
            distance_km=distance_km,
            time_diff_hours=time_diff,
            pet_type=query_post.pet_type
        )
    
    def _create_no_match_result(self, query_post: PetPost, 
                               candidate_post: PetPost,
                               reason: str = "") -> MatchResult:
        """Helper to create a no-match result"""
        return MatchResult(
            query_id=query_post.id,
            matched_id=candidate_post.id,
            confidence=0.0,
            match_score=0.0,
            visual_similarity=0.0,
            location_score=0.0,
            time_score=0.0,
            metadata_score=0.0,
            is_match=False,
            match_category='no_match',
            distance_km=0.0,
            time_diff_hours=0.0,
            pet_type=query_post.pet_type
        )
    
    def find_best_matches(self, query_post: PetPost, 
                         candidate_posts: List[PetPost],
                         top_k: int = 10,
                         min_confidence: float = 45.0) -> List[MatchResult]:
        """
        Find best matches from a list of candidates
        
        Args:
            query_post: Query pet post
            candidate_posts: List of candidate posts to match against
            top_k: Number of top matches to return
            min_confidence: Minimum confidence threshold
            
        Returns:
            List of MatchResults sorted by confidence (highest first)
        """
        results = []
        
        for candidate in candidate_posts:
            result = self.match(query_post, candidate)
            
            # Filter by minimum confidence
            if result.confidence >= min_confidence:
                results.append(result)
        
        # Sort by confidence descending
        results.sort(key=lambda x: x.confidence, reverse=True)
        
        return results[:top_k]


def format_match_result(result: MatchResult, detailed: bool = False) -> Dict:
    """
    Format match result as dictionary (ready for JSON API response)
    
    Args:
        result: MatchResult object
        detailed: Include detailed breakdown
        
    Returns:
        Dictionary with match information
    """
    output = {
        'query_id': result.query_id,
        'matched_id': result.matched_id,
        'confidence': round(result.confidence, 2),
        'is_match': result.is_match,
        'match_category': result.match_category,
        'pet_type': result.pet_type
    }
    
    if detailed:
        output['details'] = {
            'visual_similarity': round(result.visual_similarity, 4),
            'location_score': round(result.location_score, 2),
            'time_score': round(result.time_score, 2),
            'metadata_score': round(result.metadata_score, 2),
            'distance_km': round(result.distance_km, 2),
            'time_diff_hours': round(result.time_diff_hours, 2)
        }
    
    return output


# Example usage and testing
if __name__ == "__main__":
    print("Pet Matching System - Module loaded successfully")
    print("=" * 80)
    print("\nConfiguration:")
    config = PetMatchingConfig()
    print(f"  Visual weight: {config.WEIGHT_VISUAL * 100:.1f}%")
    print(f"  Location weight: {config.WEIGHT_LOCATION * 100:.1f}%")
    print(f"  Time weight: {config.WEIGHT_TIME * 100:.1f}%")
    print(f"  Metadata weight: {config.WEIGHT_METADATA * 100:.1f}%")
    print(f"\n  High confidence threshold: {config.CONFIDENCE_HIGH:.1f}%")
    print(f"  Medium confidence threshold: {config.CONFIDENCE_MEDIUM:.1f}%")
    print(f"  Low confidence threshold: {config.CONFIDENCE_LOW:.1f}%")
    print("\n" + "=" * 80)
