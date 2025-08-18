from __future__ import annotations
from typing import List, Dict, Optional, Any


class ProgressionService:
    """Manages multi-item learning progression through any math topics (auto-discovering)."""
    
    def __init__(self):
        pass
    
    def get_topic_progression(self, topic_name: str) -> List[str]:
        """Get ordered list of item IDs for any topic progression."""
        # Import here to avoid circular dependency
        from api.services.container import ITEMS_REPO
        
        # Get all items for the specified topic from the repository
        available_items = []
        
        # Auto-discover items for this topic
        topic_item_ids = self._discover_topic_items(topic_name)
        
        for item_id in topic_item_ids:
            item = ITEMS_REPO.get_item(item_id)
            if item:
                # Extract complexity-based difficulty
                complexity = item.get("complexity", "Easy")
                difficulty_map = {"Easy": 0.3, "Medium": 0.6, "Hard": 0.9}
                difficulty = difficulty_map.get(complexity, 0.5)
                
                # Extract subtopic order from sub_topic field
                sub_topic = item.get("sub_topic", "")
                subtopic_order = self._extract_subtopic_order(sub_topic)
                
                # Extract question number from ID  
                question_num = self._extract_question_number(item_id)
                
                available_items.append({
                    "id": item_id,
                    "difficulty": difficulty,
                    "complexity": complexity,
                    "subtopic_order": subtopic_order,
                    "question_num": question_num,
                    "sub_topic": sub_topic
                })
        
        # Sort by subtopic order, then question number, then difficulty
        available_items.sort(key=lambda x: (x["subtopic_order"], x["question_num"], x["difficulty"]))
        return [item["id"] for item in available_items]
    
    
    def _discover_topic_items(self, topic_name: str) -> List[str]:
        """Auto-discover all items for a given topic in the repository."""
        # Import here to avoid circular dependency
        from api.services.container import ITEMS_REPO
        
        # Get all items from repository and find ones matching this topic
        all_items = ITEMS_REPO.get_all_items()
        topic_items = []
        
        # Convert topic name to uppercase for matching (e.g., "fractions" -> "FRACTIONS")
        topic_upper = topic_name.upper()
        print(f"🔍 DEBUG: Looking for items containing '{topic_upper}' in {len(all_items)} total items")
        
        for item_id, item_data in all_items.items():
            # Check if item ID contains the topic name
            if topic_upper in item_id.upper():
                topic_items.append(item_id)
                print(f"🔍 DEBUG: Found {topic_name} item: {item_id}")
        
        print(f"🔍 DEBUG: Found {len(topic_items)} items for topic '{topic_name}'")
        return topic_items
    
    def _extract_topic_from_item_id(self, item_id: str) -> str:
        """Extract topic name from item ID (e.g., 'FRACTIONS-Q1' -> 'fractions')."""
        # Common topic patterns in item IDs
        topic_patterns = ["ALGEBRA", "FRACTIONS", "GEOMETRY", "PERCENTAGE", "RATIO", "SPEED", "STATISTICS"]
        
        for pattern in topic_patterns:
            if pattern in item_id.upper():
                return pattern.lower()
        
        # NO FALLBACKS - return unknown if pattern not recognized
        return "unknown"
    
    def get_available_topics(self) -> List[str]:
        """Get list of all available topics from repository items."""
        # Import here to avoid circular dependency
        from api.services.container import ITEMS_REPO
        
        all_items = ITEMS_REPO.get_all_items()
        topics = set()
        
        for item_id in all_items.keys():
            topic = self._extract_topic_from_item_id(item_id)
            topics.add(topic)
        
        return sorted(list(topics))
    
    
    def _extract_subtopic_order(self, sub_topic: str) -> int:
        """Extract subtopic order from sub_topic string like '1.1 Introduction to Algebra'."""
        if not sub_topic:
            return 0
        try:
            # Extract the number before the first dot (e.g., "1.1" -> 1)
            parts = sub_topic.split(".")
            if len(parts) >= 2:
                return int(float(sub_topic.split()[0]) * 10)  # 1.1 -> 11, 1.2 -> 12
            return 0
        except (ValueError, IndexError):
            return 0
    
    def _extract_question_number(self, item_id: str) -> int:
        """Extract question number from item ID like 'ALGEBRA-INTRODUCTION-TO-ALGEBRA-Q5'."""
        try:
            if "-Q" in item_id:
                return int(item_id.split("-Q")[-1])
            return 0
        except (ValueError, IndexError):
            return 0
    
    def get_next_item_id(self, current_item_id: str, completed_items: List[str], topic_name: str) -> Optional[str]:
        """Get the next item ID in the progression for any topic."""
        progression = self.get_topic_progression(topic_name)
        
        try:
            current_index = progression.index(current_item_id)
            # Get next item that hasn't been completed
            for i in range(current_index + 1, len(progression)):
                next_item_id = progression[i]
                if next_item_id not in completed_items:
                    return next_item_id
            return None  # No more items
        except ValueError:
            # Current item not in progression, return first available
            for item_id in progression:
                if item_id not in completed_items:
                    return item_id
            return None
    
    def get_progression_status(self, completed_items: List[str], topic_name: str) -> Dict[str, Any]:
        """Get overall progression status for any topic."""
        progression = self.get_topic_progression(topic_name)
        total_items = len(progression)
        completed_count = len([item_id for item_id in completed_items if item_id in progression])
        
        return {
            "total_items": total_items,
            "completed_count": completed_count,
            "completion_percentage": (completed_count / total_items * 100) if total_items > 0 else 0,
            "next_item_id": self.get_next_item_id(completed_items[-1] if completed_items else "", completed_items, topic_name),
            "progression_items": progression
        }
    
    def recommend_next_session(self, learner_profile: Dict[str, Any], topic_name: str) -> Optional[str]:
        """Recommend next item based on learner's progress and performance for any topic."""
        completed_items = learner_profile.get("completed_items", [])
        progression = self.get_topic_progression(topic_name)
        
        # NO FALLBACKS - If no progression found, fail clearly
        if not progression:
            print(f"🔍 DEBUG: No progression found for topic '{topic_name}'")
            return None
        
        # Filter completed items to only include items from this topic
        topic_completed = [item_id for item_id in completed_items if item_id in progression]
        
        # If no completed items in this topic, start with first item in progression
        if not topic_completed:
            return progression[0]
        
        # For now, simple sequential progression
        # TODO: Add adaptive logic based on performance, misconceptions, etc.
        # Use the last completed item FROM THIS TOPIC, not globally
        last_completed_in_topic = topic_completed[-1]
        return self.get_next_item_id(last_completed_in_topic, completed_items, topic_name)


# Global progression service instance
PROGRESSION_SERVICE = ProgressionService()