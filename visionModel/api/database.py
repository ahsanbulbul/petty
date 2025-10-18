"""
Database module for Pet Matching System
SQLite-based storage for lost/found pets with embeddings

Tables:
- lost_pets: Lost pet posts with embeddings
- found_pets: Found pet posts with embeddings
"""

import sqlite3
import json
import numpy as np
from typing import List, Dict, Optional
from datetime import datetime
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class Database:
    """Database handler for pet matching system"""
    
    def __init__(self, db_path: str = "pet_matching.db"):
        """
        Initialize database connection
        
        Args:
            db_path: Path to SQLite database file
        """
        self.db_path = Path(db_path)
        self.connection = None
        
    def initialize(self):
        """Create database tables if they don't exist"""
        self.connection = sqlite3.connect(self.db_path, check_same_thread=False)
        self.connection.row_factory = sqlite3.Row
        
        cursor = self.connection.cursor()
        
        # Lost pets table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS lost_pets (
                id TEXT PRIMARY KEY,
                pet_type TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                timestamp TEXT NOT NULL,
                gender TEXT,
                description TEXT,
                embeddings BLOB NOT NULL,
                created_at TEXT NOT NULL
            )
        ''')
        
        # Found pets table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS found_pets (
                id TEXT PRIMARY KEY,
                pet_type TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                timestamp TEXT NOT NULL,
                gender TEXT,
                description TEXT,
                embeddings BLOB NOT NULL,
                created_at TEXT NOT NULL
            )
        ''')
        
        # Create indices for faster queries
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_lost_pet_type 
            ON lost_pets(pet_type)
        ''')
        
        cursor.execute('''
            CREATE INDEX IF NOT EXISTS idx_found_pet_type 
            ON found_pets(pet_type)
        ''')
        
        self.connection.commit()
        logger.info(f"Database initialized at {self.db_path}")
    
    def _serialize_embeddings(self, embeddings: List[np.ndarray]) -> bytes:
        """
        Serialize list of numpy arrays to bytes for storage
        
        Args:
            embeddings: List of numpy embedding arrays
            
        Returns:
            Serialized bytes
        """
        # Convert to list of lists for JSON serialization
        embeddings_list = [emb.tolist() for emb in embeddings]
        json_str = json.dumps(embeddings_list)
        return json_str.encode('utf-8')
    
    def _deserialize_embeddings(self, data: bytes) -> List[np.ndarray]:
        """
        Deserialize bytes back to list of numpy arrays
        
        Args:
            data: Serialized embedding data
            
        Returns:
            List of numpy arrays
        """
        json_str = data.decode('utf-8')
        embeddings_list = json.loads(json_str)
        return [np.array(emb, dtype=np.float32) for emb in embeddings_list]
    
    def save_lost_post(self, post_data: Dict):
        """
        Save a lost pet post to database
        
        Args:
            post_data: Dictionary with post information and embeddings
        """
        cursor = self.connection.cursor()
        
        embeddings_blob = self._serialize_embeddings(post_data['embeddings'])
        
        cursor.execute('''
            INSERT OR REPLACE INTO lost_pets 
            (id, pet_type, latitude, longitude, timestamp, gender, description, embeddings, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            post_data['id'],
            post_data['pet_type'],
            post_data['latitude'],
            post_data['longitude'],
            post_data['timestamp'].isoformat(),
            post_data.get('gender'),
            post_data.get('description'),
            embeddings_blob,
            datetime.now().isoformat()
        ))
        
        self.connection.commit()
        logger.info(f"Saved lost pet post: {post_data['id']}")
    
    def save_found_post(self, post_data: Dict):
        """
        Save a found pet post to database
        
        Args:
            post_data: Dictionary with post information and embeddings
        """
        cursor = self.connection.cursor()
        
        embeddings_blob = self._serialize_embeddings(post_data['embeddings'])
        
        cursor.execute('''
            INSERT OR REPLACE INTO found_pets 
            (id, pet_type, latitude, longitude, timestamp, gender, description, embeddings, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            post_data['id'],
            post_data['pet_type'],
            post_data['latitude'],
            post_data['longitude'],
            post_data['timestamp'].isoformat(),
            post_data.get('gender'),
            post_data.get('description'),
            embeddings_blob,
            datetime.now().isoformat()
        ))
        
        self.connection.commit()
        logger.info(f"Saved found pet post: {post_data['id']}")
    
    def get_all_lost_posts(self, pet_type: Optional[str] = None) -> List[Dict]:
        """
        Get all lost pet posts, optionally filtered by pet type
        
        Args:
            pet_type: Filter by pet type (cat, dog, etc.)
            
        Returns:
            List of post dictionaries with embeddings
        """
        cursor = self.connection.cursor()
        
        if pet_type:
            cursor.execute(
                'SELECT * FROM lost_pets WHERE pet_type = ?',
                (pet_type,)
            )
        else:
            cursor.execute('SELECT * FROM lost_pets')
        
        posts = []
        for row in cursor.fetchall():
            post = {
                'id': row['id'],
                'pet_type': row['pet_type'],
                'latitude': row['latitude'],
                'longitude': row['longitude'],
                'timestamp': datetime.fromisoformat(row['timestamp']),
                'gender': row['gender'],
                'description': row['description'],
                'embeddings': self._deserialize_embeddings(row['embeddings'])
            }
            posts.append(post)
        
        return posts
    
    def get_all_found_posts(self, pet_type: Optional[str] = None) -> List[Dict]:
        """
        Get all found pet posts, optionally filtered by pet type
        
        Args:
            pet_type: Filter by pet type (cat, dog, etc.)
            
        Returns:
            List of post dictionaries with embeddings
        """
        cursor = self.connection.cursor()
        
        if pet_type:
            cursor.execute(
                'SELECT * FROM found_pets WHERE pet_type = ?',
                (pet_type,)
            )
        else:
            cursor.execute('SELECT * FROM found_pets')
        
        posts = []
        for row in cursor.fetchall():
            post = {
                'id': row['id'],
                'pet_type': row['pet_type'],
                'latitude': row['latitude'],
                'longitude': row['longitude'],
                'timestamp': datetime.fromisoformat(row['timestamp']),
                'gender': row['gender'],
                'description': row['description'],
                'embeddings': self._deserialize_embeddings(row['embeddings'])
            }
            posts.append(post)
        
        return posts
    
    def delete_lost_post(self, post_id: str) -> bool:
        """
        Delete a lost pet post
        
        Args:
            post_id: ID of post to delete
            
        Returns:
            True if deleted, False if not found
        """
        cursor = self.connection.cursor()
        cursor.execute('DELETE FROM lost_pets WHERE id = ?', (post_id,))
        self.connection.commit()
        
        deleted = cursor.rowcount > 0
        if deleted:
            logger.info(f"Deleted lost pet post: {post_id}")
        
        return deleted
    
    def delete_found_post(self, post_id: str) -> bool:
        """
        Delete a found pet post
        
        Args:
            post_id: ID of post to delete
            
        Returns:
            True if deleted, False if not found
        """
        cursor = self.connection.cursor()
        cursor.execute('DELETE FROM found_pets WHERE id = ?', (post_id,))
        self.connection.commit()
        
        deleted = cursor.rowcount > 0
        if deleted:
            logger.info(f"Deleted found pet post: {post_id}")
        
        return deleted
    
    def get_stats(self) -> Dict:
        """
        Get database statistics
        
        Returns:
            Dictionary with database stats
        """
        cursor = self.connection.cursor()
        
        cursor.execute('SELECT COUNT(*) as count FROM lost_pets')
        lost_count = cursor.fetchone()['count']
        
        cursor.execute('SELECT COUNT(*) as count FROM found_pets')
        found_count = cursor.fetchone()['count']
        
        return {
            'lost_pets': lost_count,
            'found_pets': found_count,
            'total_posts': lost_count + found_count
        }
    
    def is_healthy(self) -> bool:
        """
        Check if database is healthy
        
        Returns:
            True if database is accessible, False otherwise
        """
        try:
            if self.connection is None:
                return False
            
            cursor = self.connection.cursor()
            cursor.execute('SELECT 1')
            cursor.fetchone()
            return True
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            return False
    
    def close(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()
            logger.info("Database connection closed")


# Example usage
if __name__ == "__main__":
    db = Database("test_pet_matching.db")
    db.initialize()
    
    stats = db.get_stats()
    print(f"Database stats: {stats}")
    
    db.close()
