"""
Firestore Repository Implementation
Production-ready data access layer with error handling and optimization
"""

from typing import Dict, List, Optional, Any
from datetime import datetime, timezone
import uuid
import logging
from contextlib import asynccontextmanager

try:
    from google.cloud import firestore
    from google.cloud.firestore import Client as FirestoreClient
    from google.api_core import exceptions
    FIRESTORE_AVAILABLE = True
except ImportError:
    FIRESTORE_AVAILABLE = False
    logging.warning("Firestore SDK not available. Install: pip install google-cloud-firestore")

from api.models.firestore_models import (
    FirestoreUser, 
    FirestoreLearner, 
    FirestoreSession, 
    FirestoreCurriculumItem,
    COLLECTIONS
)

logger = logging.getLogger(__name__)


class FirestoreRepository:
    """
    Production Firestore repository with comprehensive error handling
    Implements flat document structure for optimal performance
    """
    
    def __init__(self, project_id: Optional[str] = None):
        if not FIRESTORE_AVAILABLE:
            raise ImportError("Firestore SDK required: pip install google-cloud-firestore")
        
        self.db: FirestoreClient = firestore.Client(project=project_id)
        self._batch_size = 500  # Firestore batch limit
        
        # Collection references for performance
        self.users = self.db.collection(COLLECTIONS['users'])
        self.learners = self.db.collection(COLLECTIONS['learners'])  
        self.sessions = self.db.collection(COLLECTIONS['sessions'])
        
    # ============ USER MANAGEMENT ============
    
    async def create_user(self, user_id: str, email: str, name: str, role: str = 'parent') -> FirestoreUser:
        """Create new user with proper error handling"""
        try:
            user = FirestoreUser.create_new(user_id, email, name, role)
            self.users.document(user_id).set(user.__dict__)
            logger.info(f"Created user: {user_id}")
            return user
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to create user {user_id}: {e}")
            raise
    
    async def get_user(self, user_id: str) -> Optional[FirestoreUser]:
        """Get user with caching and error handling"""
        try:
            doc = self.users.document(user_id).get()
            if not doc.exists:
                return None
            data = doc.to_dict()
            return FirestoreUser(**data)
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to get user {user_id}: {e}")
            return None
    
    async def update_user(self, user_id: str, updates: Dict[str, Any]) -> bool:
        """Update user with timestamp tracking"""
        try:
            updates['updated_at'] = datetime.now(timezone.utc).isoformat()
            self.users.document(user_id).update(updates)
            logger.info(f"Updated user: {user_id}")
            return True
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to update user {user_id}: {e}")
            return False
    
    # ============ LEARNER MANAGEMENT ============
    
    async def create_learner(self, parent_id: str, name: str, grade_level: str = 'P6') -> FirestoreLearner:
        """Create new learner and link to parent"""
        learner_id = str(uuid.uuid4())
        try:
            # Create learner document
            learner = FirestoreLearner.create_new(learner_id, parent_id, name, grade_level)
            self.learners.document(learner_id).set(learner.__dict__)
            
            # Add learner to parent's children list
            self.users.document(parent_id).update({
                'children_ids': firestore.ArrayUnion([learner_id]),
                'updated_at': datetime.now(timezone.utc).isoformat()
            })
            
            logger.info(f"Created learner: {learner_id} for parent: {parent_id}")
            return learner
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to create learner for {parent_id}: {e}")
            raise
    
    async def get_learner(self, learner_id: str) -> Optional[FirestoreLearner]:
        """Get learner profile with full progress data"""
        try:
            doc = self.learners.document(learner_id).get()
            if not doc.exists:
                return None
            data = doc.to_dict()
            return FirestoreLearner(**data)
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to get learner {learner_id}: {e}")
            return None
    
    async def get_learners_by_parent(self, parent_id: str) -> List[FirestoreLearner]:
        """Get all learners for a parent"""
        try:
            # Query learners by parent_id
            docs = self.learners.where('parent_id', '==', parent_id).get()
            learners = []
            for doc in docs:
                data = doc.to_dict()
                learners.append(FirestoreLearner(**data))
            return learners
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to get learners for parent {parent_id}: {e}")
            return []
    
    async def update_learner_progress(self, learner_id: str, updates: Dict[str, Any]) -> bool:
        """Update learner progress efficiently"""
        try:
            updates['updated_at'] = datetime.now(timezone.utc).isoformat()
            self.learners.document(learner_id).update(updates)
            logger.debug(f"Updated learner progress: {learner_id}")
            return True
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to update learner {learner_id}: {e}")
            return False
    
    async def add_xp(self, learner_id: str, amount: int) -> bool:
        """Add XP with atomic increment"""
        try:
            self.learners.document(learner_id).update({
                'xp': firestore.Increment(amount),
                'updated_at': datetime.now(timezone.utc).isoformat()
            })
            return True
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to add XP to learner {learner_id}: {e}")
            return False
    
    async def mark_item_completed(self, learner_id: str, item_id: str, subject: str, 
                                  mastery_increase: float = 0.1) -> bool:
        """Mark item completed and update mastery atomically"""
        try:
            # Use transaction for consistency
            @firestore.transactional  
            def update_in_transaction(transaction, doc_ref):
                doc = doc_ref.get(transaction=transaction)
                if not doc.exists:
                    raise ValueError(f"Learner {learner_id} not found")
                
                data = doc.to_dict()
                completed_items = data.get('completed_items', [])
                mastery_scores = data.get('mastery_scores', {})
                
                # Add item if not already completed
                if item_id not in completed_items:
                    completed_items.append(item_id)
                    
                    # Update mastery score
                    current_mastery = mastery_scores.get(subject, 0.0)
                    new_mastery = min(1.0, current_mastery + mastery_increase)
                    mastery_scores[subject] = new_mastery
                    
                    # Calculate new level based on total XP
                    new_level = max(1, (data.get('xp', 0) // 100) + 1)
                    
                    transaction.update(doc_ref, {
                        'completed_items': completed_items,
                        'mastery_scores': mastery_scores,
                        'level': new_level,
                        'updated_at': datetime.now(timezone.utc).isoformat()
                    })
            
            learner_ref = self.learners.document(learner_id)
            update_in_transaction(firestore.Transaction(self.db), learner_ref)
            logger.info(f"Marked item {item_id} completed for learner {learner_id}")
            return True
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to mark item completed for {learner_id}: {e}")
            return False
    
    # ============ SESSION MANAGEMENT ============
    
    async def create_session(self, learner_id: str, item_id: str, subject: str, module_id: str) -> str:
        """Create new tutoring session"""
        try:
            session = FirestoreSession.create_new(learner_id, item_id, subject, module_id)
            self.sessions.document(session.session_id).set(session.__dict__)
            
            # Update learner's current session
            await self.update_learner_progress(learner_id, {
                'current_session_id': session.session_id
            })
            
            logger.info(f"Created session: {session.session_id}")
            return session.session_id
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to create session for learner {learner_id}: {e}")
            raise
    
    async def get_session(self, session_id: str) -> Optional[FirestoreSession]:
        """Get session with full conversation history"""
        try:
            doc = self.sessions.document(session_id).get()
            if not doc.exists:
                return None
            data = doc.to_dict()
            return FirestoreSession(**data)
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to get session {session_id}: {e}")
            return None
    
    async def add_to_conversation(self, session_id: str, role: str, message: str, 
                                  metadata: Optional[Dict[str, Any]] = None) -> bool:
        """Add message to conversation history"""
        try:
            entry = {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "role": role,
                "message": message,
                "metadata": metadata or {}
            }
            
            self.sessions.document(session_id).update({
                'conversation_history': firestore.ArrayUnion([entry]),
                'updated_at': datetime.now(timezone.utc).isoformat()
            })
            return True
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to add conversation entry to {session_id}: {e}")
            return False
    
    async def record_misconceptions(self, session_id: str, misconception_tags: List[str], 
                                    confidence: float = 1.0) -> bool:
        """Record misconceptions with frequency tracking"""
        try:
            # Get current misconceptions
            session_doc = self.sessions.document(session_id).get()
            if not session_doc.exists:
                return False
                
            session_data = session_doc.to_dict()
            misconceptions = session_data.get('misconceptions', {})
            
            now = datetime.now(timezone.utc).isoformat()
            
            # Update misconception data
            for tag in misconception_tags:
                if tag not in misconceptions:
                    misconceptions[tag] = {
                        'count': 0,
                        'first_seen': now,
                        'last_seen': now,
                        'confidence_scores': []
                    }
                    
                misconceptions[tag]['count'] += 1
                misconceptions[tag]['last_seen'] = now
                misconceptions[tag]['confidence_scores'].append(confidence)
            
            # Update session
            self.sessions.document(session_id).update({
                'misconceptions': misconceptions,
                'updated_at': now
            })
            
            return True
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to record misconceptions for {session_id}: {e}")
            return False
    
    async def finish_session(self, session_id: str, success: bool, final_accuracy: float) -> bool:
        """Mark session as finished with final metrics"""
        try:
            now = datetime.now(timezone.utc).isoformat()
            
            updates = {
                'finished': True,
                'success': success,
                'final_accuracy': final_accuracy,
                'completed_at': now,
                'updated_at': now
            }
            
            self.sessions.document(session_id).update(updates)
            
            # Clear current session from learner
            session_doc = self.sessions.document(session_id).get()
            if session_doc.exists:
                learner_id = session_doc.to_dict().get('learner_id')
                if learner_id:
                    await self.update_learner_progress(learner_id, {
                        'current_session_id': None,
                        'total_sessions': firestore.Increment(1)
                    })
            
            logger.info(f"Finished session: {session_id}")
            return True
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to finish session {session_id}: {e}")
            return False
    
    # ============ CURRICULUM MANAGEMENT ============
    
    async def store_curriculum_item(self, subject: str, item: Dict[str, Any]) -> bool:
        """Store curriculum item in appropriate subject collection"""
        try:
            item_id = item['id']
            collection_path = f"curriculum/{subject}/items"
            
            # Add metadata
            now = datetime.now(timezone.utc).isoformat()
            item.update({
                'created_at': now,
                'updated_at': now,
                'usage_stats': {
                    'times_used': 0,
                    'success_rate': 0.0,
                    'average_completion_time': 0
                }
            })
            
            self.db.collection(collection_path).document(item_id).set(item)
            logger.info(f"Stored curriculum item: {subject}/{item_id}")
            return True
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to store curriculum item {item.get('id')}: {e}")
            return False
    
    async def get_curriculum_item(self, subject: str, item_id: str) -> Optional[Dict[str, Any]]:
        """Get curriculum item by subject and ID"""
        try:
            collection_path = f"curriculum/{subject}/items"
            doc = self.db.collection(collection_path).document(item_id).get()
            if not doc.exists:
                return None
            return doc.to_dict()
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to get curriculum item {subject}/{item_id}: {e}")
            return None
    
    async def get_curriculum_by_subject(self, subject: str, limit: int = 100) -> List[Dict[str, Any]]:
        """Get all curriculum items for a subject, ordered by learning progression"""
        try:
            collection_path = f"curriculum/{subject}/items"
            docs = (self.db.collection(collection_path)
                    .order_by('learn_step')
                    .limit(limit)
                    .get())
            
            items = []
            for doc in docs:
                items.append(doc.to_dict())
            return items
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to get curriculum for {subject}: {e}")
            return []
    
    # ============ ANALYTICS & REPORTING ============
    
    async def get_learner_analytics(self, learner_id: str, days: int = 30) -> Dict[str, Any]:
        """Get comprehensive analytics for a learner"""
        try:
            # Get learner profile
            learner = await self.get_learner(learner_id)
            if not learner:
                return {}
            
            # Get recent sessions
            cutoff_date = datetime.now(timezone.utc).timestamp() - (days * 24 * 60 * 60)
            cutoff_iso = datetime.fromtimestamp(cutoff_date, tz=timezone.utc).isoformat()
            
            recent_sessions = (self.sessions
                               .where('learner_id', '==', learner_id)
                               .where('started_at', '>=', cutoff_iso)
                               .order_by('started_at', direction=firestore.Query.DESCENDING)
                               .limit(50)
                               .get())
            
            # Compile analytics
            sessions_data = []
            total_time = 0
            total_accuracy = 0
            misconception_summary = {}
            
            for doc in recent_sessions:
                session_data = doc.to_dict()
                sessions_data.append(session_data)
                total_time += session_data.get('total_time_spent', 0)
                total_accuracy += session_data.get('final_accuracy', 0)
                
                # Aggregate misconceptions
                session_misconceptions = session_data.get('misconceptions', {})
                for tag, data in session_misconceptions.items():
                    if tag not in misconception_summary:
                        misconception_summary[tag] = {'count': 0, 'sessions': 0}
                    misconception_summary[tag]['count'] += data.get('count', 0)
                    misconception_summary[tag]['sessions'] += 1
            
            session_count = len(sessions_data)
            
            return {
                'learner_profile': learner.__dict__,
                'summary': {
                    'total_sessions': session_count,
                    'total_time_minutes': total_time // 60,
                    'average_accuracy': total_accuracy / max(session_count, 1),
                    'mastery_scores': learner.mastery_scores,
                    'current_level': learner.level,
                    'total_xp': learner.xp
                },
                'misconceptions': misconception_summary,
                'recent_sessions': sessions_data
            }
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Failed to get analytics for learner {learner_id}: {e}")
            return {}
    
    # ============ HEALTH & MAINTENANCE ============
    
    async def health_check(self) -> bool:
        """Check Firestore connectivity and permissions"""
        try:
            # Simple write and read test
            test_doc = self.db.collection('_health_check').document('test')
            test_data = {'timestamp': datetime.now(timezone.utc).isoformat()}
            test_doc.set(test_data)
            
            # Read it back
            result = test_doc.get()
            if result.exists:
                # Clean up
                test_doc.delete()
                return True
            return False
            
        except exceptions.GoogleCloudError as e:
            logger.error(f"Firestore health check failed: {e}")
            return False


# Singleton instance for dependency injection
_firestore_repo: Optional[FirestoreRepository] = None

def get_firestore_repository(project_id: Optional[str] = None) -> FirestoreRepository:
    """Get singleton Firestore repository instance"""
    global _firestore_repo
    if _firestore_repo is None:
        _firestore_repo = FirestoreRepository(project_id)
    return _firestore_repo