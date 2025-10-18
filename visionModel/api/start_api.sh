#!/bin/bash

# Pet Matching API - Startup Script
# This script installs dependencies and starts the API server

echo "========================================"
echo "  Pet Matching API - Startup Script"
echo "========================================"
echo ""

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "Working directory: $SCRIPT_DIR"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo "✓ Python found: $(python3 --version)"
echo ""

# Check if parent venv exists (preferred)
if [ -d "../.venv" ]; then
    echo "✓ Using parent virtual environment: ../.venv"
    source ../.venv/bin/activate
elif [ -d "venv" ]; then
    echo "✓ Using local virtual environment: venv"
    source venv/bin/activate
else
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    echo "✓ Virtual environment created"
fi

echo ""

# Check if dependencies are installed
echo "Checking dependencies..."
python3 -c "import fastapi, uvicorn" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Installing dependencies..."
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
    echo "✓ Dependencies installed"
else
    echo "✓ Dependencies already installed"
fi
echo ""

# Check if database exists
if [ ! -f "pet_matching.db" ]; then
    echo "ℹ Database will be created on first run"
else
    echo "✓ Database exists"
fi

echo ""

# Check if models cache exists in parent directory
if [ ! -d "../models_cache" ]; then
    echo "ℹ Models will be downloaded on first run (~1.5 GB)"
    echo "  This may take a few minutes..."
else
    echo "✓ Model cache exists"
fi

echo ""
echo "========================================"
echo "  Starting API Server"
echo "========================================"
echo ""
echo "API will be available at:"
echo "  - http://localhost:8000"
echo "  - API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
python api.py
