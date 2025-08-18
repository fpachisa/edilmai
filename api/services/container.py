from api.services.repositories import InMemoryItemsRepo, InMemorySessionsRepo, InMemoryProfilesRepo, InMemoryParentsRepo
from api.services.firestore_repository import get_firestore_repository
from api.services.progression import ProgressionService
from api.core.config import settings
import os

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
                'items': FirestoreItemsRepo(firestore_repo),
                'sessions': FirestoreSessionsRepo(firestore_repo), 
                'profiles': FirestoreProfilesRepo(firestore_repo),
                'parents': FirestoreParentsRepo(firestore_repo)
            }
            
        except Exception as e:
            print(f"⚠️ Firestore initialization failed: {e}")
            print("💾 Falling back to in-memory repositories")
            
    # Default to in-memory repositories
    print("💾 Using in-memory repositories (development mode)")
    return {
        'items': InMemoryItemsRepo(),
        'sessions': InMemorySessionsRepo(),
        'profiles': InMemoryProfilesRepo(), 
        'parents': InMemoryParentsRepo()
    }

# Wrapper classes to maintain API compatibility
class FirestoreItemsRepo:
    def __init__(self, firestore_repo):
        self.firestore = firestore_repo
        
    def put_item(self, item: dict):
        """Store curriculum item"""
        subject = item.get('topic', 'unknown').lower()
        return self._sync_call(self.firestore.store_curriculum_item(subject, item))
        
    def get_item(self, item_id: str) -> dict:
        """Get curriculum item - searches across subjects"""
        subjects = ['algebra', 'fractions', 'percentage', 'ratio', 'speed', 'geometry', 'statistics']
        for subject in subjects:
            item = self._sync_call(self.firestore.get_curriculum_item(subject, item_id))
            if item:
                return item
        return None
    
    def get_all_items(self) -> dict:
        """Get all curriculum items across all subjects"""
        all_items = {}
        subjects = ['algebra', 'fractions', 'percentage', 'ratio', 'speed', 'geometry', 'statistics']
        for subject in subjects:
            try:
                items = self._sync_call(self.firestore.get_all_curriculum_items(subject))
                for item in items:
                    if item and 'id' in item:
                        all_items[item['id']] = item
            except Exception:
                # Subject might not exist yet, continue
                pass
        return all_items
        
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
        subject = "algebra"  # Will determine from item
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
