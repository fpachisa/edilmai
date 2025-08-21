#!/usr/bin/env python3
"""
Debug script to inspect Firestore database structure
Find out what collections exist and how questions are actually stored
"""

import os
import sys
from google.cloud import firestore

# Set up environment
os.environ['ENV'] = 'production'

def inspect_firestore():
    """Inspect Firestore database structure"""
    try:
        # Connect to production database
        db = firestore.Client(project='edilmai', database='production')
        print(f"🔗 Connected to Firestore production database")
        
        # List all collections at root level
        print(f"\n📁 ROOT COLLECTIONS:")
        collections = db.collections()
        collection_names = []
        for collection in collections:
            collection_names.append(collection.id)
            print(f"  - {collection.id}")
        
        # Check if curriculum_questions collection exists and inspect its structure
        if 'curriculum_questions' in collection_names:
            print(f"\n🔍 INSPECTING 'curriculum_questions' COLLECTION:")
            
            # Get first 5 documents to see structure
            docs = db.collection('curriculum_questions').limit(5).get()
            print(f"  Found {len(docs)} documents (showing first 5)")
            
            for i, doc in enumerate(docs):
                print(f"\n  📄 Document {i+1}: {doc.id}")
                data = doc.to_dict()
                
                # Show key structure
                if data:
                    print(f"    Keys: {list(data.keys())}")
                    
                    # Show important fields
                    topic_field = data.get('topic', 'NOT FOUND')
                    title_field = data.get('title', 'NOT FOUND')
                    problem_text = data.get('problem_text', 'NOT FOUND')
                    
                    print(f"    topic: '{topic_field}'")
                    print(f"    title: '{title_field}'")
                    print(f"    problem_text: {problem_text[:50]}..." if isinstance(problem_text, str) else f"    problem_text: {problem_text}")
                else:
                    print(f"    EMPTY DOCUMENT")
                    
        else:
            print(f"\n❌ 'curriculum_questions' collection NOT FOUND")
            
        # Check for other curriculum-related collections
        curriculum_collections = [name for name in collection_names if 'curriculum' in name.lower()]
        if curriculum_collections:
            print(f"\n📚 CURRICULUM-RELATED COLLECTIONS:")
            for coll_name in curriculum_collections:
                docs = db.collection(coll_name).limit(2).get()
                print(f"  - {coll_name}: {len(docs)} documents")
                
        # Check for any collections that might contain questions
        question_collections = [name for name in collection_names if any(keyword in name.lower() for keyword in ['question', 'problem', 'item', 'content'])]
        if question_collections:
            print(f"\n❓ QUESTION-RELATED COLLECTIONS:")
            for coll_name in question_collections:
                docs = db.collection(coll_name).limit(2).get()
                print(f"  - {coll_name}: {len(docs)} documents")
                
        # Try to find fractions data specifically
        print(f"\n🔍 SEARCHING FOR 'fractions' DATA:")
        for coll_name in collection_names:
            try:
                # Try to query for fractions in different fields
                fractions_docs = db.collection(coll_name).where('topic', '==', 'fractions').limit(1).get()
                if fractions_docs:
                    print(f"  ✅ Found 'fractions' in {coll_name} collection (topic field)")
                    
                fractions_docs = db.collection(coll_name).where('topic', '==', 'Fractions').limit(1).get()
                if fractions_docs:
                    print(f"  ✅ Found 'Fractions' in {coll_name} collection (topic field)")
                    
            except Exception as e:
                # Collection might not have topic field, skip
                pass
                
        print(f"\n✅ Database inspection complete")
        
    except Exception as e:
        print(f"❌ Error inspecting Firestore: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    inspect_firestore()