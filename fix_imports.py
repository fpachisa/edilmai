#!/usr/bin/env python3
"""
Fix relative imports in the API to use absolute imports
"""
import os
import re
from pathlib import Path

def fix_imports_in_file(file_path):
    """Fix relative imports in a single file"""
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        original_content = content
        
        # Fix relative imports to absolute imports
        patterns = [
            (r'from \.([a-zA-Z0-9_]+) import', r'from api.\1 import'),
            (r'from \.\.([a-zA-Z0-9_]+) import', r'from api.\1 import'),
            (r'from \.\.\.([a-zA-Z0-9_]+) import', r'from api.\1 import'),
            (r'from models\.', r'from api.models.'),
            (r'from services\.', r'from api.services.'),
            (r'from core\.', r'from api.core.'),
            (r'from routers\.', r'from api.routers.'),
        ]
        
        for pattern, replacement in patterns:
            content = re.sub(pattern, replacement, content)
        
        # Only write if content changed
        if content != original_content:
            with open(file_path, 'w') as f:
                f.write(content)
            print(f"Fixed imports in: {file_path}")
            return True
        return False
        
    except Exception as e:
        print(f"Error fixing {file_path}: {e}")
        return False

def main():
    """Fix all Python files in the api directory"""
    api_dir = Path(__file__).parent / 'api'
    
    if not api_dir.exists():
        print(f"API directory not found: {api_dir}")
        return
    
    python_files = list(api_dir.rglob('*.py'))
    fixed_count = 0
    
    for py_file in python_files:
        if fix_imports_in_file(py_file):
            fixed_count += 1
    
    print(f"\nFixed imports in {fixed_count} files")

if __name__ == "__main__":
    main()