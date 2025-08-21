from services.repositories import InMemorySessionsRepo, InMemoryProfilesRepo, InMemoryParentsRepo
from services.firestore_repository import get_firestore_repository
from services.progression import ProgressionService
from models.curriculum_models import COLLECTIONS
from core.config import settings
import os
import logging
import asyncio

logger = logging.getLogger(__name__)

# Initialize Firestore for production, fallback to in-memory for development
def init_repositories():
    """Initialize data repositories based on environment"""
    use_firestore = not settings.auth_stub and (
        os.getenv('FIRESTORE_PROJECT_ID') or 
        os.getenv('GOOGLE_CLOUD_PROJECT') or
        os.getenv('FIREBASE_PROJECT_ID')
    )
    
    if use_firestore:
        try:
            project_id = (os.getenv('FIRESTORE_PROJECT_ID') or 
                         os.getenv('GOOGLE_CLOUD_PROJECT') or 
                         os.getenv('FIREBASE_PROJECT_ID'))
            
            firestore_repo = get_firestore_repository(project_id)
            
            print(f"✅ Firestore initialized for project: {project_id}")
            
            return {
                'items': HybridItemsRepo(firestore_repo),
                'sessions': FirestoreSessionsRepo(firestore_repo), 
                'profiles': FirestoreProfilesRepo(firestore_repo),
                'parents': FirestoreParentsRepo(firestore_repo)
            }
            
        except Exception as e:
            print(f"⚠️ Firestore initialization failed: {e}")
            print("💾 Falling back to in-memory repositories")
            
    # Default to hybrid with local Firestore emulator or production
    print("💾 Using hybrid repositories (development mode)")
    try:
        # Try to connect to Firestore even in dev mode
        firestore_repo = get_firestore_repository()
        return {
            'items': HybridItemsRepo(firestore_repo),
            'sessions': InMemorySessionsRepo(),
            'profiles': InMemoryProfilesRepo(), 
            'parents': InMemoryParentsRepo()
        }
    except Exception as e:
        print(f"⚠️ Cannot connect to Firestore in dev mode: {e}")
        # Create a minimal fallback that loads nothing
        class EmptyItemsRepo:
            def __init__(self):
                self._cache = {}
            def get_item(self, item_id): return None
            def get_all_items(self): return {}
            def put_item(self, item): pass
        
        return {
            'items': EmptyItemsRepo(),
            'sessions': InMemorySessionsRepo(),
            'profiles': InMemoryProfilesRepo(), 
            'parents': InMemoryParentsRepo()
        }

# Hybrid Items Repository - Firestore golden copy, in-memory cache
class HybridItemsRepo:
    def __init__(self, firestore_repo):
        self.firestore = firestore_repo
        self._cache = {}
        self._load_from_firestore()
        
    def _load_from_firestore(self):
        """Load all items from Firestore into memory cache at startup"""
        try:
            print("🔄 Loading curriculum from Firestore into memory cache...")
            # Load from the canonical curriculum_questions collection
            collection_ref = self.firestore.db.collection(COLLECTIONS['curriculum_questions'])
            docs = collection_ref.get()
            
            loaded_count = 0
            for doc in docs:
                if doc.exists:
                    item_data = doc.to_dict()
                    item_id = doc.id
                    self._cache[item_id] = item_data
                    loaded_count += 1
                    
            print(f"✅ Loaded {loaded_count} items from Firestore into memory cache")
            
        except Exception as e:
            print(f"❌ ERROR loading from Firestore: {e}")
            print("💾 Falling back to empty cache")
            self._cache = {}
    
    def get_item(self, item_id: str) -> dict:
        """Get item from memory cache (fast)"""
        return self._cache.get(item_id)
    
    def get_all_items(self) -> dict:
        """Get all items from memory cache (fast)"""
        return self._cache.copy()
    
    def put_item(self, item: dict):
        """Store item to both Firestore and memory cache"""
        item_id = item.get('id')
        if not item_id:
            raise ValueError("Item must have an 'id' field")
            
        # Store to Firestore
        try:
            doc_ref = self.firestore.db.collection(COLLECTIONS['curriculum_questions']).document(item_id)
            doc_ref.set(item)
        except Exception as e:
            print(f"❌ ERROR storing to Firestore: {e}")
            raise
            
        # Update memory cache
        self._cache[item_id] = item
        print(f"✅ Stored {item_id} to both Firestore and cache")
        
    def refresh_cache(self):
        """Reload cache from Firestore"""
        print("🔄 Refreshing cache from Firestore...")
        self._load_from_firestore()
        
    def _sync_call(self, coro):
        """Temporary sync wrapper - will be replaced with proper async"""
        import asyncio
        try:
            loop = asyncio.get_event_loop()
            return loop.run_until_complete(coro)
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            return loop.run_until_complete(coro)

class FirestoreSessionsRepo:
    def __init__(self, firestore_repo):
        self.firestore = firestore_repo
        
    def create_session(self, learner_id: str, item_id: str) -> str:
        subject = "algebra"  # Default for now
        module_id = "basic"  # Default for now
        return self._sync_call(self.firestore.create_session(learner_id, item_id, subject, module_id))
        
    def get(self, session_id: str) -> dict:
        session = self._sync_call(self.firestore.get_session(session_id))
        return session.__dict__ if session else None
        
    def append_step(self, session_id: str, step: dict):
        pass  # Will implement with proper Firestore update
        
    def inc_attempt(self, session_id: str):
        pass  # Will implement with atomic increment
        
    def advance_step(self, session_id: str):
        pass  # Will implement with proper state management
        
    def mark_finished(self, session_id: str):
        self._sync_call(self.firestore.finish_session(session_id, True, 1.0))
        
    def add_to_conversation(self, session_id: str, role: str, message: str, metadata: dict = None):
        self._sync_call(self.firestore.add_to_conversation(session_id, role, message, metadata))
        
    def add_learning_insight(self, session_id: str, insight: str, confidence: float = 1.0):
        pass  # Will implement with array union
        
    def record_misconceptions(self, session_id: str, misconception_tags: list, confidence: float = 1.0):
        self._sync_call(self.firestore.record_misconceptions(session_id, misconception_tags, confidence))
        
    def _sync_call(self, coro):
        import asyncio
        try:
            loop = asyncio.get_event_loop()
            return loop.run_until_complete(coro)
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            return loop.run_until_complete(coro)

class FirestoreProfilesRepo:
    def __init__(self, firestore_repo):
        self.firestore = firestore_repo
        
    def get_profile(self, learner_id: str) -> dict:
        learner = self._sync_call(self.firestore.get_learner(learner_id))
        if learner:
            return {
                'learner_id': learner.learner_id,
                'xp': learner.xp,
                'badges': learner.badges,
                'completed_items': learner.completed_items,
                'current_session_id': learner.current_session_id,
                'name': learner.name,
                'grade_level': learner.grade_level,
                'subjects': learner.subjects,
                'mastery_pct': learner.mastery_scores
            }
        return {
            'learner_id': learner_id,
            'xp': 0,
            'badges': [],
            'completed_items': [],
            'current_session_id': None,
            'name': 'New Learner',
            'grade_level': 'P6',
            'subjects': ['maths'],
            'mastery_pct': {}
        }
        
    def add_xp(self, learner_id: str, amount: int):
        self._sync_call(self.firestore.add_xp(learner_id, amount))
        
    def mark_item_completed(self, learner_id: str, item_id: str):
        # Extract actual subject from the question data
        subject = self._extract_subject_from_item_id(item_id)
        self._sync_call(self.firestore.mark_item_completed(learner_id, item_id, subject))
        
    def set_current_session(self, learner_id: str, session_id: str):
        self._sync_call(self.firestore.update_learner_progress(learner_id, {
            'current_session_id': session_id
        }))
        
    def clear_current_session(self, learner_id: str):
        self._sync_call(self.firestore.update_learner_progress(learner_id, {
            'current_session_id': None
        }))
        
    def create_learner(self, *, name: str, grade_level: str = "P6", subjects: list = None, learner_id: str = None) -> str:
        parent_id = "temp-parent"  # Will get from auth context
        learner = self._sync_call(self.firestore.create_learner(parent_id, name, grade_level))
        return learner.learner_id
        
    def _extract_subject_from_item_id(self, item_id: str) -> str:
        """Extract subject/topic from item ID using curriculum service - FAIL LOUDLY if not found"""
        from services.curriculum_service import get_curriculum_service
        curriculum_service = get_curriculum_service()
        
        # Get the question data to extract topic
        question = curriculum_service.get_question(item_id)
        if not question:
            raise ValueError(f"Question not found for item_id: {item_id}")
            
        # Get topic from question data
        topic = question.get("topic", "").strip()
        if not topic:
            raise ValueError(f"No topic found in question data for item_id: {item_id}")
            
        return topic.lower()
        
    def _sync_call(self, coro):
        import asyncio
        try:
            loop = asyncio.get_event_loop()
            return loop.run_until_complete(coro)
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            return loop.run_until_complete(coro)

class FirestoreParentsRepo:
    def __init__(self, firestore_repo):
        self.firestore = firestore_repo
        
    def add_child(self, parent_uid: str, learner_id: str):
        pass  # Handled automatically in create_learner
        
    def list_children(self, parent_uid: str) -> list:
        learners = self._sync_call(self.firestore.get_learners_by_parent(parent_uid))
        return [learner.learner_id for learner in learners]
        
    def _sync_call(self, coro):
        import asyncio
        try:
            loop = asyncio.get_event_loop()
            return loop.run_until_complete(coro)
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            return loop.run_until_complete(coro)

# Initialize repositories
repos = init_repositories()
ITEMS_REPO = repos['items']
SESSIONS_REPO = repos['sessions'] 
PROFILES_REPO = repos['profiles']
PARENTS_REPO = repos['parents']

# Initialize progression service
PROGRESSION_SERVICE = ProgressionService()
