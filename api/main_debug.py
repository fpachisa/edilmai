#!/usr/bin/env python3
"""Minimal main.py for debugging startup issues"""

print("🚀 Starting minimal FastAPI debug...")

try:
    from fastapi import FastAPI
    print("✅ FastAPI import OK")
    
    app = FastAPI(title="Debug API", version="0.1.0")
    print("✅ FastAPI app created")
    
    @app.get("/healthz")
    async def healthz():
        return {"status": "ok", "debug": "minimal"}
    
    print("✅ Health endpoint registered")
    
    @app.get("/")
    async def root():
        return {"service": "debug-api", "status": "running"}
    
    print("✅ Root endpoint registered")
    
    # Try Firestore import
    try:
        from services.firestore_repository import get_firestore_repository
        print("✅ Firestore repository import OK")
    except Exception as e:
        print(f"❌ Firestore error (non-fatal): {e}")
    
    print("🎯 Debug API ready!")
    
except Exception as e:
    print(f"❌ Critical startup error: {e}")
    import traceback
    traceback.print_exc()
    raise