"""
Curriculum Service for Production Runtime
Provides efficient querying of curriculum data from Firestore
Supports adaptive learning patterns and student progress tracking
"""

import logging
from typing import Dict, List, Optional, Any
from datetime import datetime, timezone

from services.firestore_repository import get_firestore_repository
from models.curriculum_models import CurriculumQuestion, TopicProgression, COLLECTIONS

logger = logging.getLogger(__name__)


class CurriculumService:
    """
    Production service for querying curriculum from Firestore
    Optimized for adaptive learning and student progress tracking
    """
    
    def __init__(self):
        self.firestore_repo = get_firestore_repository()
        self._question_cache = {}  # Simple in-memory cache for frequently accessed questions
        self._progression_cache = {}  # Cache for topic progressions

    def get_question(self, question_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a specific question by ID
        Uses caching for performance
        """
        print(f"🔍 DEBUG: CurriculumService.get_question called with ID: {question_id}")
        
        # Check cache first
        if question_id in self._question_cache:
            cached_question = self._question_cache[question_id]
            print(f"🔍 DEBUG: Found in cache - topic: {cached_question.get('topic', 'NO_TOPIC')}, title: {cached_question.get('title', 'NO_TITLE')}")
            return cached_question
            
        try:
            doc_ref = self.firestore_repo.db.collection(COLLECTIONS["curriculum_questions"]).document(question_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                print(f"🔍 DEBUG: Question document does not exist: {question_id}")
                logger.warning(f"Question not found: {question_id}")
                return None
                
            question_data = doc.to_dict()
            print(f"🔍 DEBUG: Retrieved from Firestore - topic: {question_data.get('topic', 'NO_TOPIC')}, title: {question_data.get('title', 'NO_TITLE')}")
            print(f"🔍 DEBUG: Problem text preview: {question_data.get('problem_text', 'NO_PROBLEM_TEXT')[:100]}...")
            
            # Cache for future requests
            self._question_cache[question_id] = question_data
            
            logger.debug(f"Retrieved question: {question_id}")
            return question_data
            
        except Exception as e:
            print(f"🔍 DEBUG: Error retrieving question {question_id}: {e}")
            logger.error(f"Error retrieving question {question_id}: {e}")
            return None

    def get_topic_progression(self, topic: str, subtopic: Optional[str] = None) -> List[str]:
        """
        Get ordered list of question IDs for a topic/subtopic progression
        Returns empty list if not found
        """
        cache_key = f"{topic}:{subtopic or 'all'}"
        
        # Check cache first
        if cache_key in self._progression_cache:
            return self._progression_cache[cache_key]
            
        try:
            progressions_collection = self.firestore_repo.db.collection(COLLECTIONS["topic_progressions"])
            
            if subtopic:
                # Get specific subtopic progression
                doc_id = f"{topic}:{subtopic}"
                doc_ref = progressions_collection.document(doc_id)
                doc = doc_ref.get()
                
                if doc.exists:
                    progression_data = doc.to_dict()
                    question_sequence = progression_data.get("question_sequence", [])
                    self._progression_cache[cache_key] = question_sequence
                    return question_sequence
            else:
                # Get all progressions for topic
                query = progressions_collection.where("topic", "==", topic)
                docs = query.get()
                
                all_questions = []
                for doc in docs:
                    progression_data = doc.to_dict()
                    questions = progression_data.get("question_sequence", [])
                    all_questions.extend(questions)
                
                self._progression_cache[cache_key] = all_questions
                return all_questions
                
            logger.warning(f"No progression found for {topic}/{subtopic}")
            return []
            
        except Exception as e:
            logger.error(f"Error retrieving progression for {topic}/{subtopic}: {e}")
            return []

    def get_next_question_in_progression(self, topic: str, completed_questions: List[str], 
                                       subtopic: Optional[str] = None) -> Optional[str]:
        """
        Get the next question ID in a topic progression that hasn't been completed
        Supports adaptive learning by finding appropriate next challenge
        """
        progression = self.get_topic_progression(topic, subtopic)
        
        if not progression:
            return None
            
        # Find first question not in completed list
        for question_id in progression:
            if question_id not in completed_questions:
                logger.debug(f"Next question for {topic}: {question_id}")
                return question_id
                
        logger.info(f"All questions completed for {topic}/{subtopic}")
        return None

    def get_questions_by_difficulty(self, topic: str, difficulty_range: tuple[float, float], 
                                  limit: int = 10) -> List[Dict[str, Any]]:
        """
        Get questions within a specific difficulty range for adaptive learning
        difficulty_range: (min_difficulty, max_difficulty) both 0.0-1.0
        """
        try:
            questions_collection = self.firestore_repo.db.collection(COLLECTIONS["curriculum_questions"])
            
            # Query by topic and difficulty range
            query = (questions_collection
                    .where("topic", "==", topic)
                    .where("difficulty", ">=", difficulty_range[0])
                    .where("difficulty", "<=", difficulty_range[1])
                    .limit(limit))
            
            docs = query.get()
            questions = [doc.to_dict() for doc in docs]
            
            logger.debug(f"Found {len(questions)} questions for {topic} with difficulty {difficulty_range}")
            return questions
            
        except Exception as e:
            logger.error(f"Error querying questions by difficulty: {e}")
            return []

    def get_questions_by_skills(self, skills: List[str], limit: int = 10) -> List[Dict[str, Any]]:
        """
        Get questions that teach specific skills
        Useful for targeted remediation or skill building
        """
        try:
            questions_collection = self.firestore_repo.db.collection(COLLECTIONS["curriculum_questions"])
            
            # Query for questions that contain any of the specified skills
            query = (questions_collection
                    .where("subskills", "array_contains_any", skills)
                    .limit(limit))
            
            docs = query.get()
            questions = [doc.to_dict() for doc in docs]
            
            logger.debug(f"Found {len(questions)} questions for skills: {skills}")
            return questions
            
        except Exception as e:
            logger.error(f"Error querying questions by skills: {e}")
            return []

    def update_question_usage_stats(self, question_id: str, completion_time: int, 
                                  success: bool, misconceptions: List[str] = None):
        """
        Update question usage statistics for analytics and adaptive learning
        This helps improve question difficulty ratings and identify problematic questions
        """
        try:
            doc_ref = self.firestore_repo.db.collection(COLLECTIONS["curriculum_questions"]).document(question_id)
            
            # Use Firestore transaction for atomic updates
            @self.firestore_repo.db.transaction
            def update_stats(transaction):
                doc = transaction.get(doc_ref)
                if not doc.exists:
                    return
                    
                current_stats = doc.to_dict().get("usage_stats", {
                    "times_used": 0,
                    "success_rate": 0.0,
                    "average_completion_time": 0,
                    "common_misconceptions": []
                })
                
                # Update statistics
                times_used = current_stats.get("times_used", 0) + 1
                old_success_rate = current_stats.get("success_rate", 0.0)
                old_avg_time = current_stats.get("average_completion_time", 0)
                
                # Calculate new success rate
                new_success_rate = ((old_success_rate * (times_used - 1)) + (1.0 if success else 0.0)) / times_used
                
                # Calculate new average completion time
                new_avg_time = ((old_avg_time * (times_used - 1)) + completion_time) / times_used
                
                # Update misconceptions
                common_misconceptions = current_stats.get("common_misconceptions", [])
                if misconceptions:
                    common_misconceptions.extend(misconceptions)
                    # Keep only unique misconceptions (simple approach)
                    common_misconceptions = list(set(common_misconceptions))
                
                updated_stats = {
                    "times_used": times_used,
                    "success_rate": new_success_rate,
                    "average_completion_time": int(new_avg_time),
                    "common_misconceptions": common_misconceptions
                }
                
                transaction.update(doc_ref, {"usage_stats": updated_stats, "updated_at": datetime.now(timezone.utc).isoformat()})
                
            update_stats()
            logger.debug(f"Updated usage stats for question: {question_id}")
            
        except Exception as e:
            logger.error(f"Error updating question usage stats: {e}")

    def get_available_topics(self) -> List[Dict[str, Any]]:
        """
        Get list of all available topics with metadata
        Useful for navigation and topic selection
        """
        try:
            progressions_collection = self.firestore_repo.db.collection(COLLECTIONS["topic_progressions"])
            docs = progressions_collection.get()
            
            topics_info = {}
            
            for doc in docs:
                data = doc.to_dict()
                topic = data.get("topic")
                subtopic = data.get("subtopic")
                
                if topic not in topics_info:
                    topics_info[topic] = {
                        "topic": topic,
                        "subtopics": [],
                        "total_questions": 0,
                        "estimated_duration_minutes": 0
                    }
                
                topics_info[topic]["subtopics"].append({
                    "subtopic": subtopic,
                    "question_count": data.get("total_questions", 0),
                    "duration_minutes": data.get("estimated_duration_minutes", 0)
                })
                
                topics_info[topic]["total_questions"] += data.get("total_questions", 0)
                topics_info[topic]["estimated_duration_minutes"] += data.get("estimated_duration_minutes", 0)
            
            return list(topics_info.values())
            
        except Exception as e:
            logger.error(f"Error getting available topics: {e}")
            return []

    def search_questions(self, query: str, topic: Optional[str] = None, limit: int = 10) -> List[Dict[str, Any]]:
        """
        Search questions by text content
        Note: Firestore doesn't support full-text search, so this is a basic implementation
        For production, consider using Algolia or Elasticsearch for better search
        """
        try:
            questions_collection = self.firestore_repo.db.collection(COLLECTIONS["curriculum_questions"])
            
            # Basic query - can be enhanced with external search service
            base_query = questions_collection
            
            if topic:
                base_query = base_query.where("topic", "==", topic)
                
            docs = base_query.limit(limit * 3).get()  # Get more docs to filter locally
            
            # Simple text matching (case-insensitive)
            query_lower = query.lower()
            matching_questions = []
            
            for doc in docs:
                question_data = doc.to_dict()
                title = question_data.get("title", "").lower()
                problem_text = question_data.get("problem_text", "").lower()
                
                if query_lower in title or query_lower in problem_text:
                    matching_questions.append(question_data)
                    
                if len(matching_questions) >= limit:
                    break
            
            logger.debug(f"Found {len(matching_questions)} questions matching '{query}'")
            return matching_questions
            
        except Exception as e:
            logger.error(f"Error searching questions: {e}")
            return []

    def clear_cache(self):
        """Clear internal caches - useful for testing or after curriculum updates"""
        self._question_cache.clear()
        self._progression_cache.clear()
        logger.info("Cleared curriculum service caches")


# Global singleton instance
_curriculum_service = None

def get_curriculum_service() -> CurriculumService:
    """Get singleton instance of CurriculumService"""
    global _curriculum_service
    if _curriculum_service is None:
        _curriculum_service = CurriculumService()
    return _curriculum_service