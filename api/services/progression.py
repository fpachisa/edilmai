from __future__ import annotations
from typing import List, Dict, Optional, Any


class ProgressionService:
    """Manages multi-item learning progression through any math topics (auto-discovering)."""
    
    def __init__(self):
        pass
    
    def get_topic_progression(self, topic_name: str, subtopic_filter: str = None) -> List[str]:
        """Get ordered list of item IDs for any topic progression, optionally filtered by subtopic."""
        # Import here to avoid circular dependency
        from services.container import ITEMS_REPO
        
        print(f"🔍 DEBUG: get_topic_progression called with topic='{topic_name}', subtopic_filter='{subtopic_filter}'")
        
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
                
                # Apply subtopic filter if specified
                if subtopic_filter:
                    # Check if this item matches the subtopic filter
                    if not self._matches_subtopic(item_id, sub_topic, subtopic_filter):
                        print(f"🔍 DEBUG: Skipping {item_id} - doesn't match subtopic filter '{subtopic_filter}' (item sub_topic: '{sub_topic}')")
                        continue
                    print(f"🔍 DEBUG: Including {item_id} - matches subtopic filter '{subtopic_filter}' (item sub_topic: '{sub_topic}')")
                
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
        
        result_ids = [item["id"] for item in available_items]
        print(f"🔍 DEBUG: get_topic_progression returning {len(result_ids)} items: {result_ids[:3]}..." if result_ids else "🔍 DEBUG: get_topic_progression returning 0 items")
        return result_ids
    
    
    def _discover_topic_items(self, topic_name: str) -> List[str]:
        """Auto-discover all items for a given topic in the repository."""
        # Import here to avoid circular dependency
        from services.container import ITEMS_REPO
        
        # Get all items from repository and find ones matching this topic
        all_items = ITEMS_REPO.get_all_items()
        topic_items = []
        
        # Convert topic name to uppercase for matching (e.g., "fractions" -> "FRACTIONS")
        topic_upper = topic_name.upper()
        print(f"🔍 DEBUG: Looking for items STARTING WITH '{topic_upper}-' in {len(all_items)} total items")
        
        for item_id, item_data in all_items.items():
            # Check if item ID STARTS WITH the topic name followed by a hyphen
            # This prevents "FRACTIONS" from matching "RATIO-RATIOS-AND-FRACTIONS-Q9"
            item_id_upper = item_id.upper()
            if item_id_upper.startswith(f"{topic_upper}-"):
                topic_items.append(item_id)
                print(f"🔍 DEBUG: Found {topic_name} item: {item_id}")
            else:
                # Also check the actual topic field in the item data for more precision
                item_topic = item_data.get('topic', '').lower() if item_data else ''
                if item_topic == topic_name.lower():
                    topic_items.append(item_id)
                    print(f"🔍 DEBUG: Found {topic_name} item by topic field: {item_id}")
        
        print(f"🔍 DEBUG: Found {len(topic_items)} items for topic '{topic_name}': {topic_items[:10]}...")
        return topic_items
        
    def _matches_subtopic(self, item_id: str, item_sub_topic: str, subtopic_filter: str) -> bool:
        """Check if an item matches the subtopic filter using subtopic IDs."""
        print(f"🔍 DEBUG: _matches_subtopic checking '{item_id}' against filter '{subtopic_filter}'")
        print(f"🔍 DEBUG: _matches_subtopic item_sub_topic: '{item_sub_topic}'")
        
        # PRIMARY: Check exact match with sub_topic field (subtopic ID)
        if item_sub_topic and item_sub_topic.lower() == subtopic_filter.lower():
            print(f"🔍 DEBUG: _matches_subtopic EXACT MATCH by sub_topic: '{item_sub_topic}' == '{subtopic_filter}'")
            return True
            
        # FALLBACK: Check if item ID contains the subtopic pattern (for legacy data)
        filter_upper = subtopic_filter.upper()
        item_id_upper = item_id.upper()
        if filter_upper in item_id_upper:
            print(f"🔍 DEBUG: _matches_subtopic FALLBACK MATCH by ID: '{filter_upper}' in '{item_id_upper}'")
            return True
        
        print(f"🔍 DEBUG: _matches_subtopic NO MATCH")    
        return False
    
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
        from services.container import ITEMS_REPO
        
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
    
    def get_next_item_id(self, current_item_id: str, completed_items: List[str], topic_name: str, subtopic_filter: str = None) -> Optional[str]:
        """Get the next item ID in the progression for any topic."""
        progression = self.get_topic_progression(topic_name, subtopic_filter)
        print(f"🔍 DEBUG: get_next_item_id called with current='{current_item_id}', topic='{topic_name}', subtopic='{subtopic_filter}'")
        print(f"🔍 DEBUG: get_next_item_id progression has {len(progression)} items: {progression[:3]}...")
        print(f"🔍 DEBUG: get_next_item_id completed_items: {completed_items}")
        
        try:
            current_index = progression.index(current_item_id)
            print(f"🔍 DEBUG: get_next_item_id found current item at index {current_index}")
            # Get next item that hasn't been completed
            for i in range(current_index + 1, len(progression)):
                next_item_id = progression[i]
                if next_item_id not in completed_items:
                    print(f"🔍 DEBUG: get_next_item_id returning next item: {next_item_id}")
                    return next_item_id
                else:
                    print(f"🔍 DEBUG: get_next_item_id skipping completed item: {next_item_id}")
            print(f"🔍 DEBUG: get_next_item_id no more items after current")
            return None  # No more items
        except ValueError:
            print(f"🔍 DEBUG: get_next_item_id current item not in progression, returning first available")
            # Current item not in progression, return first available
            for item_id in progression:
                if item_id not in completed_items:
                    print(f"🔍 DEBUG: get_next_item_id returning first available: {item_id}")
                    return item_id
                else:
                    print(f"🔍 DEBUG: get_next_item_id skipping completed item: {item_id}")
            print(f"🔍 DEBUG: get_next_item_id no available items")
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
    
    def recommend_next_session(self, learner_profile: Dict[str, Any], topic_name: str, subtopic_filter: str = None) -> Optional[str]:
        """Recommend next item based on learner's progress and performance for any topic, optionally filtered by subtopic."""
        completed_items = learner_profile.get("completed_items", [])
        progression = self.get_topic_progression(topic_name, subtopic_filter)
        print(f"🔍 DEBUG: recommend_next_session for '{topic_name}' (subtopic: '{subtopic_filter}') - progression has {len(progression)} items")
        print(f"🔍 DEBUG: First 5 progression items: {progression[:5] if progression else 'NONE'}")
        
        # NO FALLBACKS - If no progression found, fail clearly
        if not progression:
            print(f"🔍 DEBUG: No progression found for topic '{topic_name}'")
            return None
        
        # Filter completed items to only include items from this topic
        topic_completed = [item_id for item_id in completed_items if item_id in progression]
        
        # If no completed items in this topic, start with first item in progression
        if not topic_completed:
            recommended = progression[0]
            print(f"🔍 DEBUG: No completed items in topic, recommending first: {recommended}")
            return recommended
        
        # For now, simple sequential progression
        # TODO: Add adaptive logic based on performance, misconceptions, etc.
        # Use the last completed item FROM THIS TOPIC, not globally
        last_completed_in_topic = topic_completed[-1]
        recommended = self.get_next_item_id(last_completed_in_topic, completed_items, topic_name, subtopic_filter)
        print(f"🔍 DEBUG: Recommending next after {last_completed_in_topic}: {recommended}")
        return recommended


# Global progression service instance
PROGRESSION_SERVICE = ProgressionService()