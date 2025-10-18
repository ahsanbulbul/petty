#!/usr/bin/env python3
"""
Simple runner for the API that properly sets up the path
"""
import sys
from pathlib import Path

# Add parent directory to path for pet_matching_engine import
sys.path.insert(0, str(Path(__file__).parent.parent))

# Now run the API
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=False, log_level="info")
