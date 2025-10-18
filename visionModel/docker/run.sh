#!/bin/bash
# Run the API container

set -e

# Detect Docker or Podman
if command -v docker &> /dev/null; then
    CMD="docker"
elif command -v podman &> /dev/null; then
    CMD="podman"
else
    echo "Error: Neither Docker nor Podman found"
    exit 1
fi

# Stop existing container if running
$CMD stop pet-api 2>/dev/null || true
$CMD rm pet-api 2>/dev/null || true

echo "Starting Pet API..."
$CMD run -d \
    --name pet-api \
    -p 19911:19911 \
    -v pet-data:/app/data \
    --restart unless-stopped \
    pet-api:latest

echo "✓ API running on http://localhost:19911"
echo "✓ Docs at http://localhost:19911/docs"
echo ""
echo "View logs: $CMD logs -f pet-api"
echo "Stop: $CMD stop pet-api"
