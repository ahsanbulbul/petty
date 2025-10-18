# Pet Matching REST API

AI-powered REST API for matching lost and found pets using computer vision.

## � Authentication

**All POST/DELETE endpoints require API Key authentication.**

Add this header to all requests (except `/api/v1/health`):
```
X-API-Key: RXN0ZXIgRWdn
```

---

## ��� Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the Server

**Recommended:**
```bash
./start_api.sh
```

**Or manually:**
```bash
python run_api.py
```

The server will start on `http://localhost:8000`

### 3. Access API Documentation

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

---

## 📡 API Endpoints

### 1. POST `/api/v1/lost` - Submit Lost Pet

Submit a lost pet post and find matches in found pets database.

**Request Body:**
```json
{
  "id": "LOST_12345",
  "pet_type": "cat",
  "latitude": 23.8103,
  "longitude": 90.4125,
  "timestamp": "2025-10-15T14:30:00",
  "image_paths": [
    "images/lost_cat_1.jpg",
    "images/lost_cat_2.jpg"
  ],
  "gender": "male",
  "description": "Orange tabby with white paws"
}
```

**Response:**
```json
{
  "match_found": true,
  "best_match": {
    "query_id": "LOST_12345",
    "matched_id": "FOUND_67890",
    "confidence": 78.5,
    "is_match": true,
    "match_category": "high",
    "pet_type": "cat",
    "details": {
      "visual_similarity": 0.7823,
      "location_score": 95.2,
      "time_score": 88.3,
      "metadata_score": 100.0,
      "distance_km": 0.52,
      "time_diff_hours": 36.5
    }
  },
  "all_matches": [...],
  "post_id": "LOST_12345",
  "message": "Lost pet posted. Found 3 potential match(es)!"
}
```

---

### 2. POST `/api/v1/found` - Submit Found Pet

Submit a found pet post and find matches in lost pets database.

**Request Body:** (Same structure as `/lost`)
```json
{
  "id": "FOUND_67890",
  "pet_type": "dog",
  "latitude": 23.8150,
  "longitude": 90.4180,
  "timestamp": "2025-10-17T09:15:00",
  "image_paths": ["images/found_dog.jpg"],
  "gender": "female",
  "description": "Golden retriever, friendly"
}
```

---

### 3. DELETE `/api/v1/solvedlost/{id}` - Mark Lost Pet as Solved

Delete a lost pet post when found.

**Example:**
```bash
curl -X DELETE http://localhost:8000/api/v1/solvedlost/LOST_12345 \
  -H "X-API-Key: RXN0ZXIgRWdn"
```

**Response:**
```json
{
  "success": true,
  "message": "Lost pet post LOST_12345 deleted successfully",
  "post_id": "LOST_12345"
}
```

---

### 4. DELETE `/api/v1/solvedfound/{id}` - Mark Found Pet as Solved

Delete a found pet post when reunited with owner.

**Example:**
```bash
curl -X DELETE http://localhost:8000/api/v1/solvedfound/FOUND_67890 \
  -H "X-API-Key: RXN0ZXIgRWdn"
```

---

### 5. GET `/api/v1/health` - Health Check

Check API and model status. **No authentication required.**

**Response:**
```json
{
  "status": "healthy",
  "models_loaded": true,
  "gpu_available": true,
  "db_status": "healthy",
  "timestamp": "2025-10-18T10:30:00"
}
```

---

## 📊 How It Works

### 1. **Image Processing Pipeline**
- YOLOv8-Seg detects and segments pets in images
- DINOv2 extracts visual embeddings from pet regions
- Multiple images per post for robustness

### 2. **Matching Algorithm**
Weighted scoring system:
- **Visual Similarity (50%)**: Image embedding comparison
- **Location (20%)**: Distance with exponential decay
- **Time (20%)**: Temporal proximity with exponential decay
- **Gender (10%)**: Gender matching component
  - Both genders match: 100% score
  - Both genders differ: 0% score
  - Either gender is "unsure" or missing: 50% score (neutral)
- **Pet Type**: Must match (multiplier 1.0 or 0.0)

### 3. **Match Categories**
- **High (≥75%)**: Very likely the same pet
- **Medium (60-74%)**: Probable match
- **Low (45-59%)**: Possible match
- **No Match (<45%)**: Unlikely to be the same pet

---

## 🔧 Configuration

### Model Cache
Models are cached in `models_cache/` directory:
- `yolov8x-seg.pt` (~131 MB)
- DINOv2-Large from HuggingFace (~1.3 GB)

### Database
- SQLite database: `pet_matching.db`
- Tables: `lost_pets`, `found_pets`
- Embeddings stored as serialized JSON blobs

### Adjust Matching Weights
Edit `pet_matching_engine.py`:
```python
class PetMatchingConfig:
    WEIGHT_VISUAL = 0.50
    WEIGHT_TIME = 0.20
    WEIGHT_LOCATION = 0.20
    WEIGHT_GENDER = 0.10
```

---

## 🐛 Validation & Error Handling

### Request Validation
- **Pet type**: Must be `cat`, `dog`, `bird`, or `rabbit`
- **Gender**: Must be `male`, `female`, or `unsure`
  - Use `unsure` when gender is unknown - treated as neutral (50% match weight)
- **Coordinates**: Valid latitude (-90 to 90), longitude (-180 to 180)
- **Images**: At least 1 image, must be valid base64 encoded
- **Timestamp**: ISO 8601 format

### Error Responses
```json
{
  "detail": "Failed to process images. No valid pet detections found."
}
```

---

## 🚢 Deployment

### Production Deployment
```bash
# Install production server
pip install gunicorn

# Run with Gunicorn
gunicorn api:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Docker Deployment (Coming Soon)
```dockerfile
FROM python:3.10-slim
# GPU support with nvidia-docker
# See deployment docs
```

### Environment Variables
```bash
# Optional: Configure via .env file
DATABASE_PATH=pet_matching.db
MODEL_CACHE_DIR=models_cache
LOG_LEVEL=INFO
```

---

## 📝 Update Functionality

The API implements update-on-create pattern:
- When a post with existing ID is submitted, it **deletes the old entry first**
- Then creates a new entry with updated data
- This acts as an UPDATE operation without a separate endpoint

**Example:**
```python
# First submission
POST /api/v1/lost
{
  "id": "LOST_001",
  "pet_type": "cat",
  ...
}

# Update same post (automatically deletes old, creates new)
POST /api/v1/lost
{
  "id": "LOST_001",  # Same ID
  "pet_type": "cat",
  "gender": "female",  # Updated field
  ...
}
```

---

## 🧪 Testing

### Test with cURL
```bash
# Submit lost pet
curl -X POST "http://localhost:8000/api/v1/lost" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: RXN0ZXIgRWdn" \
  -d '{
    "id": "TEST_001",
    "pet_type": "cat",
    "latitude": 23.8103,
    "longitude": 90.4125,
    "timestamp": "2025-10-18T10:00:00",
    "image_paths": ["images/test_cat.jpg"],
    "gender": "male"
  }'

# Health check (no auth required)
curl http://localhost:8000/api/v1/health

# Delete post
curl -X DELETE http://localhost:8000/api/v1/solvedlost/TEST_001 \
  -H "X-API-Key: RXN0ZXIgRWdn"
```

### Test with Python
```python
import requests
from datetime import datetime

# Submit lost pet
response = requests.post(
    "http://localhost:8000/api/v1/lost",
    headers={"X-API-Key": "RXN0ZXIgRWdn"},
    json={
        "id": "TEST_002",
        "pet_type": "dog",
        "latitude": 23.8103,
        "longitude": 90.4125,
        "timestamp": datetime.now().isoformat(),
        "image_paths": ["images/dog.jpg"],
        "gender": "female"
    }
)

print(response.json())
```

---

## 📈 Performance

- **GPU Inference**: ~200ms per image (with CUDA)
- **CPU Inference**: ~2-3s per image
- **Matching**: <50ms for 100 candidates
- **Database**: SQLite handles thousands of posts efficiently

---

## 🔒 Security Considerations (Production)

1. **Authentication**: ✅ API key authentication implemented (Header: `X-API-Key: RXN0ZXIgRWdn`)
2. **Rate Limiting**: Consider implementing request throttling for production
3. **Input Validation**: ✅ Implemented with Pydantic
4. **Image Handling**: ✅ Supports base64 encoded images
5. **CORS**: Configure allowed origins properly
6. **HTTPS**: Use reverse proxy (nginx) with SSL
7. **API Key Rotation**: Store key in environment variable for production

---

## 📚 API Integration Examples

### Flutter/Dart
```dart
final response = await http.post(
  Uri.parse('http://your-api.com/api/v1/lost'),
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'RXN0ZXIgRWdn',
  },
  body: jsonEncode({
    'id': 'LOST_${uuid.v4()}',
    'pet_type': 'cat',
    'latitude': 23.8103,
    'longitude': 90.4125,
    'timestamp': DateTime.now().toIso8601String(),
    'image_paths': imagePaths,
    'gender': 'male',
  }),
);
```

### JavaScript/React
```javascript
const response = await fetch('http://your-api.com/api/v1/lost', {
  method: 'POST',
  headers: { 
    'Content-Type': 'application/json',
    'X-API-Key': 'RXN0ZXIgRWdn'
  },
  body: JSON.stringify({
    id: 'LOST_' + Date.now(),
    pet_type: 'cat',
    latitude: 23.8103,
    longitude: 90.4125,
    timestamp: new Date().toISOString(),
    image_paths: imagePaths,
    gender: 'male'
  })
});

const data = await response.json();
```

---

## 🛠️ Troubleshooting

### Models not loading
```bash
# Clear cache and re-download
rm -rf models_cache/
python -c "from vision_processor import VisionProcessor; vp = VisionProcessor(); vp.load_models()"
```

### Database locked error
```bash
# Check if database is being accessed by another process
lsof pet_matching.db
```

### Out of memory (GPU)
```bash
# Reduce batch size or use CPU
export CUDA_VISIBLE_DEVICES=""  # Force CPU mode
```

---

## 📄 License

MIT License - See LICENSE file for details

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

---

## 📞 Support

For issues and questions:
- GitHub Issues
- Email: support@petmatching.com

---

**Built with ❤️ for reuniting lost pets with their families**
