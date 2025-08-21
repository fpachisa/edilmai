#!/usr/bin/env python3
"""
FastAPI Router Import Debugger

This script systematically tests each router import and mounting to identify
which one is causing the /v1/* routes to fail.

Usage:
    python debug_routers.py

This will:
1. Test each router import individually
2. Test mounting each router to a test FastAPI app
3. Identify specific import failures
4. Suggest fixes for common issues
"""

import sys
import traceback
from pathlib import Path
from fastapi import FastAPI
from typing import Dict, List, Tuple, Any
import importlib.util

# Add the current directory to Python path for imports
sys.path.insert(0, str(Path(__file__).parent))

# List of routers to test (matches main.py)
ROUTERS_TO_TEST = [
    ("items", "routers.v1.items"),
    ("session", "routers.v1.session"), 
    ("leaderboards", "routers.v1.leaderboards"),
    ("profiles", "routers.v1.profiles"),
    ("home", "routers.v1.home"),
    ("parents", "routers.v1.parents"),
    ("admin", "routers.v1.admin"),
]

def test_router_import(name: str, module_path: str) -> Tuple[bool, str, Any]:
    """
    Test importing a single router module.
    
    Returns:
        (success: bool, error_message: str, router_object: Any)
    """
    try:
        print(f"🔍 Testing import: {module_path}")
        
        # Try to import the module
        module = importlib.import_module(module_path)
        
        # Check if the module has a 'router' attribute
        if not hasattr(module, 'router'):
            return False, f"Module {module_path} has no 'router' attribute", None
            
        router = getattr(module, 'router')
        
        # Basic validation of router object
        if not hasattr(router, 'routes'):
            return False, f"Router in {module_path} has no 'routes' attribute", None
            
        route_count = len(getattr(router, 'routes', []))
        print(f"  ✅ Import successful - Found {route_count} routes")
        return True, f"Success - {route_count} routes found", router
        
    except ImportError as e:
        error_msg = f"ImportError: {str(e)}"
        print(f"  ❌ Import failed: {error_msg}")
        return False, error_msg, None
        
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        print(f"  ❌ Unexpected error: {error_msg}")
        return False, error_msg, None

def test_router_mounting(name: str, router_object: Any) -> Tuple[bool, str]:
    """
    Test mounting a router to a test FastAPI app.
    
    Returns:
        (success: bool, error_message: str)
    """
    try:
        print(f"🔧 Testing mount: {name}")
        
        # Create a test FastAPI app
        test_app = FastAPI()
        
        # Try to mount the router
        test_app.include_router(router_object, prefix="/v1", tags=[name])
        
        # Check if routes were actually added
        v1_routes = [route for route in test_app.routes if getattr(route, 'path', '').startswith('/v1')]
        
        print(f"  ✅ Mount successful - {len(v1_routes)} /v1 routes added")
        return True, f"Success - {len(v1_routes)} /v1 routes mounted"
        
    except Exception as e:
        error_msg = f"Mount error: {str(e)}"
        print(f"  ❌ Mount failed: {error_msg}")
        return False, error_msg

def analyze_import_dependencies(module_path: str) -> List[str]:
    """
    Analyze what modules a router is trying to import.
    
    Returns:
        List of problematic imports
    """
    try:
        # Try to find the actual file
        parts = module_path.split('.')
        file_path = Path(__file__).parent / '/'.join(parts[1:]) + '.py'
        
        if not file_path.exists():
            return [f"File not found: {file_path}"]
            
        # Read the file and look for imports
        content = file_path.read_text()
        
        problematic_imports = []
        for line_num, line in enumerate(content.split('\n'), 1):
            line = line.strip()
            if line.startswith(('import ', 'from ')) and not line.startswith('#'):
                # Try to test this import
                try:
                    exec(line)
                except Exception as e:
                    problematic_imports.append(f"Line {line_num}: {line} -> {str(e)}")
                    
        return problematic_imports
        
    except Exception as e:
        return [f"Analysis failed: {str(e)}"]

def run_comprehensive_test():
    """
    Run comprehensive router testing and provide detailed report.
    """
    print("🚀 Starting FastAPI Router Debug Session")
    print("=" * 60)
    
    results = {}
    failed_imports = []
    failed_mounts = []
    
    # Test each router
    for name, module_path in ROUTERS_TO_TEST:
        print(f"\n📦 Testing router: {name}")
        print("-" * 40)
        
        # Test import
        import_success, import_msg, router_obj = test_router_import(name, module_path)
        
        if import_success:
            # Test mounting
            mount_success, mount_msg = test_router_mounting(name, router_obj)
            
            results[name] = {
                'import': {'success': True, 'message': import_msg},
                'mount': {'success': mount_success, 'message': mount_msg}
            }
            
            if not mount_success:
                failed_mounts.append((name, mount_msg))
        else:
            results[name] = {
                'import': {'success': False, 'message': import_msg},
                'mount': {'success': False, 'message': 'Skipped due to import failure'}
            }
            failed_imports.append((name, import_msg))
            
            # Analyze dependencies for failed imports
            print(f"🔍 Analyzing dependencies for {name}...")
            deps = analyze_import_dependencies(module_path)
            if deps:
                print("  Problematic imports found:")
                for dep in deps[:5]:  # Show first 5 issues
                    print(f"    - {dep}")
    
    # Generate report
    print("\n" + "=" * 60)
    print("📊 DEBUGGING REPORT")
    print("=" * 60)
    
    if failed_imports:
        print(f"\n❌ FAILED IMPORTS ({len(failed_imports)}):")
        for name, msg in failed_imports:
            print(f"  - {name}: {msg}")
    
    if failed_mounts:
        print(f"\n⚠️  FAILED MOUNTS ({len(failed_mounts)}):")
        for name, msg in failed_mounts:
            print(f"  - {name}: {msg}")
    
    successful_count = len([r for r in results.values() if r['import']['success'] and r['mount']['success']])
    print(f"\n✅ SUCCESSFUL ROUTERS: {successful_count}/{len(ROUTERS_TO_TEST)}")
    
    # Provide recommendations
    print("\n🔧 RECOMMENDATIONS:")
    
    if failed_imports:
        print("1. Fix import errors first - these prevent app startup")
        print("   - Check for missing dependencies")
        print("   - Verify import paths are correct")
        print("   - Look for circular imports")
        
    if failed_mounts:
        print("2. Fix mounting errors - these prevent route registration")
        print("   - Check router object structure")
        print("   - Verify route definitions")
        
    if not failed_imports and not failed_mounts:
        print("1. All routers import and mount successfully!")
        print("2. The issue might be:")
        print("   - Middleware interfering with /v1 routes")
        print("   - Router order conflicts") 
        print("   - GAE deployment configuration")
        
    return results

def create_safe_main_py():
    """
    Create a version of main.py with safe router importing.
    """
    safe_main_content = '''
"""
Safe version of main.py with error-resistant router importing
"""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from core.config import settings
from core.auth import init_firebase, verify_bearer_token

app = FastAPI(title="EDIL AI Tutor API", version="0.1.0")

# Health endpoints
@app.get("/healthz")
async def healthz():
    return {"status": "ok", "env": settings.env}

@app.get("/")
async def root():
    return {"service": "edil-api", "version": app.version}

@app.get("/whoami")
async def whoami(request: Request):
    return {"user": getattr(request.state, "user", None)}

# Auth middleware (simplified)
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

# Safe router importing with individual error handling
ROUTERS_TO_IMPORT = [
    ("items", "routers.v1.items"),
    ("session", "routers.v1.session"),
    ("leaderboards", "routers.v1.leaderboards"),
    ("profiles", "routers.v1.profiles"),
    ("home", "routers.v1.home"),
    ("parents", "routers.v1.parents"),
    ("admin", "routers.v1.admin"),
]

def safe_include_routers():
    """Import and include routers with individual error handling."""
    successful_routers = []
    failed_routers = []
    
    for name, module_path in ROUTERS_TO_IMPORT:
        try:
            print(f"Loading router: {name}")
            module = __import__(module_path, fromlist=[name])
            router = getattr(module, 'router')
            app.include_router(router, prefix="/v1", tags=[name])
            successful_routers.append(name)
            print(f"✅ Successfully loaded router: {name}")
        except Exception as e:
            failed_routers.append((name, str(e)))
            print(f"❌ Failed to load router {name}: {e}")
    
    print(f"Router loading complete: {len(successful_routers)} successful, {len(failed_routers)} failed")
    
    if failed_routers:
        print("Failed routers:")
        for name, error in failed_routers:
            print(f"  - {name}: {error}")
    
    return successful_routers, failed_routers

# Load routers safely
successful_routers, failed_routers = safe_include_routers()

# CORS setup
if settings.env.lower() in ("dev", "development"):
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
'''
    
    return safe_main_content

if __name__ == "__main__":
    try:
        results = run_comprehensive_test()
        
        # Offer to create safe main.py
        print(f"\n🛠️  Would you like to create a safe version of main.py?")
        print("This version will:")
        print("- Import routers individually with error handling")
        print("- Continue loading other routers if one fails")
        print("- Provide detailed logging of what succeeded/failed")
        
        response = input("\nCreate safe main.py? (y/N): ").strip().lower()
        if response in ('y', 'yes'):
            safe_content = create_safe_main_py()
            with open('main_safe.py', 'w') as f:
                f.write(safe_content)
            print("✅ Created main_safe.py - you can test with this version")
            
    except KeyboardInterrupt:
        print("\n🛑 Debug session interrupted")
    except Exception as e:
        print(f"🔥 Debug script error: {e}")
        traceback.print_exc()