#!/usr/bin/env python3
"""
Fix Subtopic Data Script
Re-ingest curriculum data with correct sub_topic preservation
"""

import os
import sys

# Set up environment
os.environ['ENV'] = 'production'

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

def main():
    """Re-ingest curriculum data with fixed sub_topic preservation"""
    print("🔄 Starting curriculum re-ingestion with fixed sub_topic preservation...")
    
    try:
        from services.curriculum_sync import sync_curriculum_to_firestore
        
        # Run the sync with the fixed service
        stats = sync_curriculum_to_firestore()
        
        print(f"✅ Re-ingestion completed successfully!")
        print(f"📊 Statistics:")
        print(f"   - Questions synced: {stats['questions_synced']}")
        print(f"   - Progressions synced: {stats['progressions_synced']}")
        print(f"   - Errors: {stats['errors']}")
        
        if stats['errors'] > 0:
            print(f"⚠️  Some errors occurred during sync")
            return 1
        else:
            print(f"🎉 All data successfully re-ingested with correct sub_topic values!")
            return 0
            
    except Exception as e:
        print(f"❌ Re-ingestion failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())