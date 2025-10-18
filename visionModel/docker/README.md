# Pet Matching API - Docker Setup

Simple Docker/Podman setup for the Pet Matching API running on port **19911**.

## 🐳 Compatibility

Works with both **Docker** and **Podman** - scripts auto-detect which one you have.

## � Quick Start

```bash
cd docker

# 1. Build
./build.sh

# 2. Run
./run.sh

# 3. Stop
./stop.sh
```

Or use docker-compose:

```bash
docker-compose up -d    # Start
docker-compose down     # Stop
```

## 📡 Access

- **API:** http://localhost:19911
- **Docs:** http://localhost:19911/docs
- **Health:** http://localhost:19911/api/v1/health

## 📊 Useful Commands

```bash
# View logs
docker logs -f pet-api

# Check status
docker ps | grep pet-api

# Restart
docker restart pet-api

# Test health
curl http://localhost:19911/api/v1/health
```

## � What's Included

- `Dockerfile` - Container definition
- `docker-compose.yml` - Easy orchestration
- `build.sh` - Build script
- `run.sh` - Run script
- `stop.sh` - Stop script

## 🗄️ Data Persistence

Database is stored in Docker volume `pet-data` and persists between restarts.

## 🚢 Deploy to Server

```bash
# 1. Copy files to server
tar -czf pet-api.tar.gz docker/ api/ models_cache/ pet_matching_engine.py
scp pet-api.tar.gz user@server:/opt/pet-api/

# 2. On server
cd /opt/pet-api
tar -xzf pet-api.tar.gz
cd docker
./build.sh
./run.sh
```

## 🐛 Troubleshooting

**Port already in use:**
```bash
sudo lsof -i :19911
```

**Check logs:**
```bash
docker logs pet-api
```

**Rebuild from scratch:**
```bash
docker stop pet-api
docker rm pet-api
docker rmi pet-api:latest
./build.sh
./run.sh
```
