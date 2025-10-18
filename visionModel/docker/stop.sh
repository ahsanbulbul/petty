#!/bin/bash
# Stop the API container

# Detect Docker or Podman
if command -v docker &> /dev/null; then
    CMD="docker"
elif command -v podman &> /dev/null; then
    CMD="podman"
else
    echo "Error: Neither Docker nor Podman found"
    exit 1
fi

echo "Stopping Pet API..."
$CMD stop pet-api
echo "✓ Stopped"
