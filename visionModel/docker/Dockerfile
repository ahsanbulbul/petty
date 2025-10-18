FROM python:3.10-slim

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    MODELS_CACHE=/app/models_cache

# Install system dependencies for OpenCV and PyTorch
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and install Python dependencies
COPY api/requirements.txt .

# Install dependencies with longer timeout and CPU-only PyTorch (much smaller/faster)
RUN pip install --no-cache-dir --default-timeout=1000 \
    torch torchvision --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir --default-timeout=1000 -r requirements.txt

# Copy models FIRST (before Python code)
COPY models_cache/ /app/models_cache/

# Copy ALL necessary Python files to app root (so imports work)
COPY pet_matching_engine.py .
COPY api/vision_processor.py .
COPY api/database.py .
COPY api/api.py .

# Create data directory
RUN mkdir -p /app/data

# Expose port
EXPOSE 19911

# Run the API
CMD ["python", "-m", "uvicorn", "api:app", "--host", "0.0.0.0", "--port", "19911"]
