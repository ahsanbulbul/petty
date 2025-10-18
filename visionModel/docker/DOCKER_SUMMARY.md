# Pet Matching API - Docker Setup Summary

## ✅ What's Completed

### 1. **Docker Configuration**
- ✅ Minimal, production-ready Dockerfile
- ✅ Docker Compose configuration (uses pre-built image)
- ✅ CPU-only PyTorch for faster builds & smaller images
- ✅ Compatible with both Docker & Podman
- ✅ Port 19911 configured

### 2. **Shell Scripts**
- ✅ `build.sh` - Build the Docker image
- ✅ `run.sh` - Run the container
- ✅ `stop.sh` - Stop the container
- ✅ Auto-detects Docker or Podman

### 3. **Documentation**
- ✅ README.md - Docker setup instructions
- ✅ Clean, minimal configuration

---

## 🚀 Quick Start

```bash
cd /distros/droidev/Projects/petty/visionModel/docker

# 1. Build
./build.sh

# 2. Run
podman-compose up -d
# Or: docker-compose up -d

# 3. Test
curl http://localhost:19911/api/v1/health

# 4. Stop
podman-compose down
# Or: docker-compose down
```

---

## 📋 Files Structure

```
visionModel/
├── docker/
│   ├── Dockerfile              # Container definition
│   ├── compose.yaml            # Compose config (uses image)
│   ├── build.sh                # Build script
│   ├── run.sh                  # Run script
│   ├── stop.sh                 # Stop script
│   ├── README.md               # Docker documentation
│   └── .dockerignore           # Build exclusions
├── api/
│   ├── api.py                  # Main API
│   ├── vision_processor.py     # Vision processing (fixed model loading)
│   ├── database.py
│   └── requirements.txt
└── pet_matching_engine.py
```

---

## 🐳 Docker vs Podman Compatibility

### ✅ Fully Compatible!

Both use the same:
- OCI standard containers
- Dockerfile syntax
- Image format
- Network configuration

### Only Difference:
- **Docker**: Runs as root daemon
- **Podman**: Runs rootless (more secure)

### Commands Work on Both:
```bash
docker build -t pet-api .    → podman build -t pet-api .
docker run pet-api           → podman run pet-api
docker ps                    → podman ps
docker logs pet-api          → podman logs pet-api
```

---

## 📡 API Endpoints (Port 19911)

- `GET /api/v1/health` - Health check (no auth)
- `POST /api/v1/lost` - Submit lost pet (requires X-API-Key)
- `POST /api/v1/found` - Submit found pet (requires X-API-Key)
- `DELETE /api/v1/solvedlost/{id}` - Delete lost post (requires X-API-Key)
- `DELETE /api/v1/solvedfound/{id}` - Delete found post (requires X-API-Key)

### Authentication:
```bash
X-API-Key: RXN0ZXIgRWdn
```

---

## 🔍 Testing the API

```bash
# Health check
curl http://localhost:19911/api/v1/health

# Submit lost pet
curl -X POST http://localhost:19911/api/v1/lost \
  -H "Content-Type: application/json" \
  -H "X-API-Key: RXN0ZXIgRWdn" \
  -d '{
    "id": "TEST_001",
    "pet_type": "cat",
    "latitude": 23.8103,
    "longitude": 90.4125,
    "timestamp": "2025-10-18T10:00:00Z",
    "images": ["<base64_image_data>"],
    "gender": "male",
    "description": "Orange tabby"
  }'

# Check container logs
podman logs -f pet-api
```

---

## 🛠️ Troubleshooting

### Build fails on package timeout:
- Already fixed with `--default-timeout=1000`
- Using CPU-only PyTorch (much smaller)

### Container crashes on startup:
```bash
# Check logs
podman logs pet-api

# Common issue: Missing files
# Solution: Rebuild image
./build.sh
```

### Port already in use:
```bash
# Check what's using port 19911
sudo lsof -i :19911

# Kill it
sudo kill -9 <PID>
```

### Import errors in container:
- Check that all files are copied in Dockerfile
- Verify Dockerfile copies: vision_processor.py, database.py, pet_matching_engine.py

---

## 📦 What's Included in Image

- ✅ Python 3.10
- ✅ All required packages (CPU-optimized)
- ✅ API code (api.py, vision_processor.py, database.py)
- ✅ Matching engine (pet_matching_engine.py)
- ✅ Pre-trained models (YOLOv8, DINOv2)
- ✅ System dependencies (libgl1, libglib2.0-0, libgomp1)

### Image Size: ~3-4 GB
- Python base: ~150 MB
- PyTorch CPU: ~200 MB
- Transformers + models: ~2.5 GB
- Other packages: ~500 MB

---

## 🚢 Deployment to Server

### Option 1: Transfer Image
```bash
# Save image
podman save pet-api:latest | gzip > pet-api.tar.gz

# Transfer to server
scp pet-api.tar.gz user@server:/tmp/

# On server
docker load < pet-api.tar.gz
docker-compose up -d
```

### Option 2: Rebuild on Server
```bash
# Copy files
scp -r visionModel/ user@server:/opt/pet-api/

# On server
cd /opt/pet-api/visionModel/docker
./build.sh
docker-compose up -d
```

---

## 🔐 Security Notes

1. **API Key**: Change in production
2. **Firewall**: Open port 19911
   ```bash
   sudo ufw allow 19911/tcp
   ```
3. **HTTPS**: Use reverse proxy (nginx/caddy)
4. **Volumes**: Data persists in `pet-data` volume

---

## ✨ Summary

**Status**: ✅ Complete & Ready for Deployment

**Key Features**:
- ✅ Minimal Docker setup (6 files)
- ✅ Uses cached models (no downloading on startup)
- ✅ Docker/Podman compatible
- ✅ Port 19911 configured
- ✅ Production-ready

**To Deploy**:
1. Build: `./build.sh`
2. Run: `podman-compose up -d`
3. Test: `curl http://localhost:19911/api/v1/health`

**Documentation**: Clean, focused on Docker deployment

---

**Last Updated**: October 18, 2025
