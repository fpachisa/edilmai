#!/usr/bin/env python3
"""Test startup components individually"""

def test_basic_imports():
    """Test basic FastAPI imports"""
    try:
        from fastapi import FastAPI
        print("✅ FastAPI import OK")
        
        from core.config import settings
        print(f"✅ Settings OK - ENV: {settings.env}")
        
        from services.container import ITEMS_REPO
        print("✅ Items repo OK")
        
        from services.firestore_repository import get_firestore_repository
        print("✅ Firestore repository import OK")
        
        # Test Firestore initialization
        repo = get_firestore_repository()
        print("✅ Firestore repository creation OK")
        
        # Test auth imports
        from core.auth import init_firebase, verify_bearer_token
        print("✅ Auth imports OK")
        
    except Exception as e:
        print(f"❌ Import error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_basic_imports()