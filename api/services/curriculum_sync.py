"""
Curriculum Sync Service: JSON Files → Firestore
Maintains JSON files as source of truth for curriculum authoring,
syncs to Firestore for production runtime performance.
"""

import json
import os
import logging
from typing import Dict, List, Optional, Any
from pathlib import Path
from datetime import datetime, timezone

from services.firestore_repository import get_firestore_repository
from models.curriculum_models import CurriculumQuestion, TopicProgression, COLLECTIONS

logger = logging.getLogger(__name__)


class CurriculumSyncService:
    """
    Handles syncing curriculum from JSON files to Firestore
    """
    
    def __init__(self, assets_path: Optional[str] = None):
        self.firestore_repo = get_firestore_repository()
        
        # Find assets directory - try multiple paths for flexibility
        if assets_path:
            self.assets_path = Path(assets_path)
        else:
            self.assets_path = self._find_assets_directory()
            
        if not self.assets_path or not self.assets_path.exists():
            raise FileNotFoundError(f"Assets directory not found. Tried: {self.assets_path}")
            
        logger.info(f"CurriculumSyncService initialized with assets path: {self.assets_path}")

    def _find_assets_directory(self) -> Optional[Path]:
        """Find the assets directory from various possible locations"""
        current_dir = Path(__file__).parent
        
        # Try multiple paths relative to this file
        possible_paths = [
            # First try the assets directory we copied to the API root
            current_dir / ".." / "assets",                         # From api/services/ → api/assets/
            current_dir.parent / "assets",                         # From api/services/ → api/assets/
            Path.cwd() / "assets",                                 # From api root → assets/
            
            # Fallback to client/assets paths
            current_dir / ".." / ".." / ".." / "client" / "assets",  # From api/services/
            current_dir / ".." / ".." / "client" / "assets",        # From api/services/ (different structure)
            current_dir.parent.parent / "client" / "assets",       # From api/services/
            Path.cwd() / "client" / "assets",                      # From project root
            Path.cwd() / ".." / "client" / "assets"                # From api directory
        ]
        
        for path in possible_paths:
            resolved_path = path.resolve()
            logger.info(f"Trying assets path: {resolved_path}")
            if resolved_path.exists() and resolved_path.is_dir():
                logger.info(f"Found assets directory: {resolved_path}")
                return resolved_path
                
        logger.warning("Assets directory not found in any expected location")
        return None

    def get_curriculum_files(self) -> List[Path]:
        """Get all JSON curriculum files from assets directory"""
        if not self.assets_path.exists():
            return []
            
        # Look for curriculum JSON files (exclude topics mapping file)
        curriculum_files = []
        for json_file in self.assets_path.glob("*.json"):
            if json_file.name != "p6_maths_topics.json":  # Skip topics mapping
                curriculum_files.append(json_file)
                
        logger.info(f"Found {len(curriculum_files)} curriculum files: {[f.name for f in curriculum_files]}")
        return curriculum_files

    def load_topics_mapping(self) -> Dict[str, Any]:
        """Load the p6_maths_topics.json file for topic structure"""
        topics_file = self.assets_path / "p6_maths_topics.json"
        if not topics_file.exists():
            logger.warning("p6_maths_topics.json not found")
            return {}
            
        try:
            with open(topics_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Error loading topics mapping: {e}")
            return {}

    def determine_subtopic_from_filename(self, filename: str, topics_mapping: Dict[str, Any]) -> tuple[str, str]:
        """
        Determine topic and subtopic from filename using topics mapping
        Returns: (topic, subtopic)
        """
        base_name = filename.replace('.json', '').lower()
        
        # Direct mapping for known files
        file_to_topic = {
            'algebra': 'algebra',
            'fractions': 'fractions', 
            'percentage': 'percentage',
            'ratio': 'ratio',
            'speed': 'speed',
            'geometry': 'geometry',
            'data-analysis': 'data-analysis',
            'measurement': 'geometry'  # measurement goes under geometry
        }
        
        topic = file_to_topic.get(base_name)
        if not topic:
            # Fallback to inferring from filename
            for known_topic in file_to_topic.values():
                if known_topic in base_name:
                    topic = known_topic
                    break
                    
        if not topic:
            logger.warning(f"Could not determine topic for file: {filename}")
            topic = base_name
            
        # For now, use filename as subtopic - can be enhanced later with topics mapping
        subtopic = base_name
        
        return topic, subtopic

    def map_display_name_to_subtopic_id(self, display_name: str, topic: str, topics_mapping: Dict[str, Any]) -> str:
        """
        Map subtopic display name to subtopic ID using p6_maths_topics.json
        e.g., "2.1 Dividing Whole Number By Proper Fractions" -> "dividing-whole-by-proper-fractions"
        """
        if not topics_mapping or 'subjects' not in topics_mapping:
            # Fallback to display name if mapping not available
            return display_name
            
        # Find the subject in topics mapping
        for subject in topics_mapping['subjects']:
            if subject.get('id') == topic:
                # Find matching subtopic by display name
                for subtopic in subject.get('subtopics', []):
                    if subtopic.get('display_name') == display_name:
                        return subtopic.get('id', display_name)
                break
        
        # If no mapping found, return display name as fallback
        logger.debug(f"No subtopic ID mapping found for display_name '{display_name}' in topic '{topic}'")
        return display_name

    def parse_curriculum_file(self, file_path: Path, topics_mapping: Dict[str, Any]) -> List[CurriculumQuestion]:
        """Parse a single curriculum JSON file into CurriculumQuestion objects"""
        try:
            with open(file_path, 'r') as f:
                data = json.load(f)
        except Exception as e:
            logger.error(f"Error reading {file_path}: {e}")
            return []

        # Determine topic and subtopic from filename
        topic, subtopic = self.determine_subtopic_from_filename(file_path.name, topics_mapping)
        
        # Extract questions from JSON structure
        questions = []
        items = data.get("questions") or data.get("items") or []
        
        if not isinstance(items, list):
            logger.warning(f"No questions list found in {file_path.name}")
            return []
            
        for item in items:
            if not isinstance(item, dict) or not item.get("id"):
                continue
                
            try:
                # SYSTEMATIC FIX: Map display name to subtopic ID using p6_maths_topics.json
                display_subtopic = item.get("sub_topic", subtopic)  # Get from JSON or fallback to filename
                subtopic_id = self.map_display_name_to_subtopic_id(display_subtopic, topic, topics_mapping)
                
                question = CurriculumQuestion.from_json_item(item, topic, subtopic_id)
                questions.append(question)
                logger.debug(f"Parsed question: {question.question_id} - display: '{display_subtopic}' -> id: '{subtopic_id}'")
            except Exception as e:
                logger.error(f"Error parsing question {item.get('id', 'unknown')} from {file_path.name}: {e}")
                continue
                
        logger.info(f"Parsed {len(questions)} questions from {file_path.name}")
        return questions

    def build_topic_progressions(self, questions: List[CurriculumQuestion]) -> List[TopicProgression]:
        """Build ordered progressions for each topic/subtopic combination"""
        progressions = {}
        
        # Group questions by topic/subtopic
        for question in questions:
            key = f"{question.topic}:{question.subtopic}"
            if key not in progressions:
                progressions[key] = []
            progressions[key].append(question)
            
        # Create TopicProgression objects
        progression_objects = []
        for key, topic_questions in progressions.items():
            topic, subtopic = key.split(":", 1)
            
            # Sort by learn_step for proper progression order
            sorted_questions = sorted(topic_questions, key=lambda q: q.learn_step)
            
            progression = TopicProgression(
                topic=topic,
                subtopic=subtopic,
                question_sequence=[q.question_id for q in sorted_questions],
                total_questions=len(sorted_questions),
                estimated_duration_minutes=sum(q.estimated_time_seconds for q in sorted_questions) // 60
            )
            
            progression_objects.append(progression)
            logger.info(f"Built progression for {topic}/{subtopic}: {len(sorted_questions)} questions")
            
        return progression_objects

    def sync_to_firestore(self, questions: List[CurriculumQuestion], progressions: List[TopicProgression]) -> Dict[str, int]:
        """Sync curriculum data to Firestore collections"""
        stats = {"questions_synced": 0, "progressions_synced": 0, "errors": 0}
        
        # Sync questions
        questions_collection = self.firestore_repo.db.collection(COLLECTIONS["curriculum_questions"])
        
        for question in questions:
            try:
                doc_ref = questions_collection.document(question.question_id)
                doc_ref.set(question.to_firestore_dict())
                stats["questions_synced"] += 1
                logger.debug(f"Synced question: {question.question_id}")
            except Exception as e:
                logger.error(f"Error syncing question {question.question_id}: {e}")
                stats["errors"] += 1
                
        # Sync topic progressions
        progressions_collection = self.firestore_repo.db.collection(COLLECTIONS["topic_progressions"])
        
        for progression in progressions:
            try:
                doc_id = f"{progression.topic}:{progression.subtopic}"
                doc_ref = progressions_collection.document(doc_id)
                doc_ref.set(progression.to_firestore_dict())
                stats["progressions_synced"] += 1
                logger.debug(f"Synced progression: {doc_id}")
            except Exception as e:
                logger.error(f"Error syncing progression {progression.topic}/{progression.subtopic}: {e}")
                stats["errors"] += 1
        
        # Update sync metadata
        self._update_sync_metadata(stats)
        
        return stats

    def _update_sync_metadata(self, stats: Dict[str, int]):
        """Update sync metadata in Firestore"""
        try:
            metadata_collection = self.firestore_repo.db.collection(COLLECTIONS["curriculum_metadata"])
            metadata_doc = metadata_collection.document("sync_history")
            
            sync_record = {
                "last_sync": datetime.now(timezone.utc).isoformat(),
                "questions_synced": stats["questions_synced"],
                "progressions_synced": stats["progressions_synced"],
                "errors": stats["errors"],
                "status": "success" if stats["errors"] == 0 else "partial_success"
            }
            
            metadata_doc.set(sync_record)
            logger.info("Updated sync metadata")
        except Exception as e:
            logger.error(f"Error updating sync metadata: {e}")

    def full_sync(self) -> Dict[str, int]:
        """Perform complete curriculum sync from JSON files to Firestore"""
        logger.info("Starting full curriculum sync...")
        
        # Load topics mapping
        topics_mapping = self.load_topics_mapping()
        
        # Get all curriculum files
        curriculum_files = self.get_curriculum_files()
        if not curriculum_files:
            logger.warning("No curriculum files found to sync")
            return {"questions_synced": 0, "progressions_synced": 0, "errors": 1}
        
        # Parse all questions from all files
        all_questions = []
        for file_path in curriculum_files:
            questions = self.parse_curriculum_file(file_path, topics_mapping)
            all_questions.extend(questions)
            
        if not all_questions:
            logger.warning("No questions parsed from curriculum files")
            return {"questions_synced": 0, "progressions_synced": 0, "errors": 1}
            
        # Build topic progressions
        progressions = self.build_topic_progressions(all_questions)
        
        # Sync to Firestore
        stats = self.sync_to_firestore(all_questions, progressions)
        
        logger.info(f"Curriculum sync completed: {stats}")
        return stats


# Convenience function for external use
def sync_curriculum_to_firestore(assets_path: Optional[str] = None) -> Dict[str, int]:
    """
    Main entry point for curriculum sync
    Returns sync statistics
    """
    try:
        sync_service = CurriculumSyncService(assets_path)
        return sync_service.full_sync()
    except Exception as e:
        logger.error(f"Curriculum sync failed: {e}")
        return {"questions_synced": 0, "progressions_synced": 0, "errors": 1}