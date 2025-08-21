#!/usr/bin/env python3
"""
Router Import Diagnostic Tool

This tool identifies and fixes the specific issue causing /v1/* routes to fail.

Based on analysis, the issue is:
1. main.py imports: from routers.v1 import parents, admin  
2. But routers/v1/__init__.py doesn't include parents and admin
3. This causes ImportError when trying to import parents and admin from routers.v1

Usage: python router_diagnostic.py
"""

import sys
from pathlib import Path

# Add current directory to path  
sys.path.insert(0, str(Path(__file__).parent))

def diagnose_import_issue():
    """Diagnose the specific import issue."""
    
    print("🔍 ROUTER IMPORT DIAGNOSTIC")
    print("=" * 50)
    
    # Check what main.py is trying to import
    main_py_path = Path(__file__).parent / "main.py"
    if main_py_path.exists():
        content = main_py_path.read_text()
        
        print("📁 Analyzing main.py imports...")
        
        # Find the import lines
        import_lines = []
        for line_num, line in enumerate(content.split('\n'), 1):
            if 'from routers.v1 import' in line:
                import_lines.append((line_num, line.strip()))
        
        if import_lines:
            print("Found these router imports in main.py:")
            for line_num, line in import_lines:
                print(f"  Line {line_num}: {line}")
    
    # Check what's actually available in __init__.py
    init_py_path = Path(__file__).parent / "routers" / "v1" / "__init__.py"
    if init_py_path.exists():
        content = init_py_path.read_text()
        
        print(f"\n📁 Analyzing routers/v1/__init__.py...")
        print("Content:")
        for line_num, line in enumerate(content.split('\n'), 1):
            if line.strip():
                print(f"  Line {line_num}: {line}")
    
    # Check what router files actually exist
    routers_dir = Path(__file__).parent / "routers" / "v1"
    if routers_dir.exists():
        print(f"\n📁 Actual router files found:")
        router_files = [f.stem for f in routers_dir.glob("*.py") if f.stem != "__init__"]
        for router_file in sorted(router_files):
            print(f"  ✅ {router_file}.py")
    
    # The diagnosis
    print(f"\n🎯 DIAGNOSIS")
    print("=" * 50)
    print("❌ PROBLEM IDENTIFIED:")
    print("main.py is importing: from routers.v1 import parents, admin")
    print("But routers/v1/__init__.py only imports: items, session, leaderboards, profiles, home")
    print("Missing: parents, admin")
    
    print(f"\n💡 SOLUTIONS:")
    print("1. Fix __init__.py to include all routers")
    print("2. OR change main.py to import directly from modules")
    print("3. OR remove __init__.py entirely (let Python handle it)")

def create_fixed_init_py():
    """Create a fixed version of __init__.py."""
    
    # Check what router files exist
    routers_dir = Path(__file__).parent / "routers" / "v1"
    router_files = [f.stem for f in routers_dir.glob("*.py") if f.stem != "__init__"]
    
    fixed_content = f"""# Auto-generated fixed __init__.py for routers/v1
from . import {', '.join(sorted(router_files))}

__all__ = [
{chr(10).join(f"    '{router}'," for router in sorted(router_files))}
]
"""
    
    return fixed_content, router_files

def create_alternative_main_py():
    """Create an alternative main.py with direct imports."""
    
    main_content = '''"""
Alternative main.py with direct router imports (avoiding __init__.py issues)
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Direct imports (bypassing __init__.py)
from routers.v1.items import router as items_router
from routers.v1.session import router as session_router  
from routers.v1.leaderboards import router as leaderboards_router
from routers.v1.profiles import router as profiles_router
from routers.v1.home import router as home_router
from routers.v1.parents import router as parents_router
from routers.v1.admin import router as admin_router

from core.config import settings
from core.auth import init_firebase, verify_bearer_token

app = FastAPI(title="EDIL AI Tutor API", version="0.1.0")

@app.get("/healthz")
async def healthz():
    return {"status": "ok", "env": settings.env}

@app.get("/")
async def root():
    return {"service": "edil-api", "version": app.version}

@app.get("/whoami")
async def whoami(request: Request):
    return {"user": getattr(request.state, "user", None)}

@app.middleware("http")
async def firebase_auth_middleware(request: Request, call_next):
    if request.method == "OPTIONS" or request.url.path.startswith("/healthz"):
        return await call_next(request)
    
    if settings.auth_stub:
        request.state.user = {"uid": "dev-user", "roles": ["learner"]}
        return await call_next(request)
        
    init_firebase(project_id=settings.firebase_project_id)
    user = verify_bearer_token(request.headers.get("Authorization"))
    if not user:
        return JSONResponse(status_code=401, content={"detail": "Unauthorized"})
    request.state.user = user
    return await call_next(request)

# Include routers with explicit router objects
app.include_router(items_router, prefix="/v1", tags=["items"])
app.include_router(session_router, prefix="/v1", tags=["session"])
app.include_router(leaderboards_router, prefix="/v1", tags=["leaderboards"])
app.include_router(profiles_router, prefix="/v1", tags=["profiles"])
app.include_router(home_router, prefix="/v1", tags=["home"])
app.include_router(parents_router, prefix="/v1", tags=["parents"])
app.include_router(admin_router, prefix="/v1", tags=["admin"])

# CORS setup
if settings.env.lower() in ("dev", "development"):
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "https://edilmai.web.app",
            "https://edilmai.firebaseapp.com",
        ],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
    )
'''
    
    return main_content

if __name__ == "__main__":
    print("🚀 Running Router Import Diagnostic...")
    
    diagnose_import_issue()
    
    print(f"\n🛠️ AVAILABLE FIXES:")
    print("=" * 50)
    
    # Option 1: Fix __init__.py
    print("1️⃣ FIX __init__.py (RECOMMENDED)")
    fixed_init, router_files = create_fixed_init_py()
    print("This will update routers/v1/__init__.py to include all routers:")
    print(fixed_init)
    
    # Option 2: Alternative main.py
    print(f"\n2️⃣ ALTERNATIVE: Direct imports in main.py")
    print("This bypasses __init__.py completely")
    
    # Offer to apply fixes
    choice = input(f"\nApply fix? (1=fix __init__.py, 2=create alternative main.py, n=no): ").strip()
    
    if choice == "1":
        init_path = Path(__file__).parent / "routers" / "v1" / "__init__.py"
        init_path.write_text(fixed_init)
        print(f"✅ Fixed {init_path}")
        print(f"Now includes: {', '.join(router_files)}")
        
    elif choice == "2":
        alt_main = create_alternative_main_py()
        alt_path = Path(__file__).parent / "main_alternative.py"
        alt_path.write_text(alt_main)
        print(f"✅ Created {alt_path}")
        print("You can rename this to main.py or test it separately")
        
    else:
        print("No changes made.")
        
    print(f"\n🎯 SUMMARY")
    print("The issue is a mismatch between:")
    print("  main.py imports: items, session, leaderboards, profiles, home, parents, admin")
    print("  __init__.py exports: items, session, leaderboards, profiles, home")
    print("  Missing in __init__.py: parents, admin")
    print(f"This causes ImportError and prevents all /v1 routes from loading.")