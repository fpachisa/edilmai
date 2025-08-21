#!/usr/bin/env python3
"""
Quick Router Import Test

This script quickly identifies which router is failing to import.
Run this first to get immediate results.

Usage: python quick_router_test.py
"""

import sys
import traceback
from pathlib import Path

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

def test_individual_imports():
    """Test each router import individually."""
    routers = [
        ("items", "routers.v1.items"),
        ("session", "routers.v1.session"),
        ("leaderboards", "routers.v1.leaderboards"), 
        ("profiles", "routers.v1.profiles"),
        ("home", "routers.v1.home"),
        ("parents", "routers.v1.parents"),
        ("admin", "routers.v1.admin"),
    ]
    
    print("🔍 Testing individual router imports...\n")
    
    successful = []
    failed = []
    
    for name, module_path in routers:
        print(f"Testing {name}... ", end="")
        try:
            # Try the import
            module = __import__(module_path, fromlist=['router'])
            router = getattr(module, 'router', None)
            
            if router is None:
                print(f"❌ No 'router' attribute found")
                failed.append((name, "No 'router' attribute"))
            else:
                routes_count = len(getattr(router, 'routes', []))
                print(f"✅ OK ({routes_count} routes)")
                successful.append(name)
                
        except Exception as e:
            print(f"❌ FAILED: {str(e)}")
            failed.append((name, str(e)))
    
    print(f"\n📊 Results:")
    print(f"✅ Successful: {len(successful)} - {', '.join(successful)}")
    print(f"❌ Failed: {len(failed)}")
    
    if failed:
        print(f"\n🔍 Detailed failure analysis:")
        for name, error in failed:
            print(f"\n--- {name} ---")
            print(f"Error: {error}")
            
            # Try to get more details
            try:
                print("Attempting detailed traceback...")
                __import__(f"routers.v1.{name}", fromlist=['router'])
            except Exception as e:
                traceback.print_exc()
    
    return successful, failed

def test_bulk_import():
    """Test the bulk import that main.py does."""
    print("🔍 Testing bulk import (like main.py does)...\n")
    
    try:
        # This is exactly what main.py does on lines 8-9
        from routers.v1 import items, session, leaderboards, profiles, home
        from routers.v1 import parents, admin
        
        print("✅ Bulk import successful!")
        
        # Test router attributes
        modules = [
            ("items", items),
            ("session", session), 
            ("leaderboards", leaderboards),
            ("profiles", profiles),
            ("home", home),
            ("parents", parents),
            ("admin", admin),
        ]
        
        for name, module in modules:
            if hasattr(module, 'router'):
                routes = len(getattr(module.router, 'routes', []))
                print(f"  {name}: ✅ {routes} routes")
            else:
                print(f"  {name}: ❌ No router attribute")
                
        return True, "Success"
        
    except Exception as e:
        print(f"❌ Bulk import failed: {str(e)}")
        print("Full traceback:")
        traceback.print_exc()
        return False, str(e)

if __name__ == "__main__":
    print("🚀 Quick Router Import Test")
    print("=" * 50)
    
    # Test 1: Individual imports
    print("\n1️⃣ INDIVIDUAL IMPORT TEST")
    successful, failed = test_individual_imports()
    
    # Test 2: Bulk import (like main.py)
    print(f"\n2️⃣ BULK IMPORT TEST (main.py style)")
    bulk_success, bulk_error = test_bulk_import()
    
    # Summary
    print(f"\n" + "=" * 50)
    print("🎯 QUICK DIAGNOSIS")
    print("=" * 50)
    
    if failed:
        print(f"❌ Problem found: {len(failed)} router(s) failing to import")
        print(f"Failing routers: {[name for name, _ in failed]}")
        print(f"\n💡 Next steps:")
        print(f"1. Fix the failing router imports above")
        print(f"2. Check for missing dependencies")
        print(f"3. Look for circular import issues")
        
    elif not bulk_success:
        print(f"❌ Bulk import issue detected")
        print(f"Individual imports work but bulk import fails")
        print(f"This suggests a circular import or import order issue")
        
    else:
        print(f"✅ All routers import successfully!")
        print(f"The /v1 route issue is likely NOT an import problem")
        print(f"Check:")
        print(f"- Middleware configuration")
        print(f"- GAE routing settings") 
        print(f"- CORS configuration")
        print(f"- FastAPI app configuration")
        
    print(f"\nFor more detailed analysis, run: python debug_routers.py")