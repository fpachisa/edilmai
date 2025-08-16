#!/usr/bin/env python3
"""
Simple server runner that fixes import paths
"""
import sys
import os
from pathlib import Path

# Add the parent directory to the Python path so imports work
api_dir = Path(__file__).parent
project_root = api_dir.parent
sys.path.insert(0, str(project_root))

# Now run uvicorn with the correct module path
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "api.main:app",
        host="127.0.0.1",
        port=8000,
        reload=False
    )