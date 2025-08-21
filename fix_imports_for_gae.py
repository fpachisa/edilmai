#!/usr/bin/env python3
"""
Quick script to fix imports for GAE deployment
Converts 'from api.' imports to relative imports when running from api directory
"""

import os
import re
from pathlib import Path

def fix_imports_in_file(file_path):
    """Fix imports in a single file"""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Replace 'from api.' with relative imports
    # Pattern: from api.module import something
    content = re.sub(r'from api\.', 'from ', content)
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"Fixed imports in: {file_path}")

def main():
    """Fix all Python files in the api directory"""
    api_dir = Path('/Users/farhat/Documents/AI Systems/AITutor/edilmai/edilmai/api')
    
    # Find all Python files
    python_files = list(api_dir.rglob('*.py'))
    
    for py_file in python_files:
        if py_file.name == '__pycache__':
            continue
        
        try:
            fix_imports_in_file(py_file)
        except Exception as e:
            print(f"Error fixing {py_file}: {e}")
    
    print(f"Import fixing complete! Processed {len(python_files)} files")

if __name__ == "__main__":
    main()