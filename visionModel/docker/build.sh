#!/bin/bash
# Build the Docker image

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

echo "Building Pet API image..."
$CMD build -t pet-api:latest -f Dockerfile ..

echo "✓ Build complete!"
echo "Run with: ./run.sh"
