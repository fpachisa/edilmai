from __future__ import annotations
from typing import List, Dict, Optional, Any
from api.services.container import ITEMS_REPO


class ProgressionService:
    """Manages multi-item learning progression through algebra topics."""
    
    def __init__(self):
        pass
    
    def get_algebra_progression(self) -> List[str]:
        """Get ordered list of algebra item IDs for progression."""
        # Get all algebra items from the repository
        available_items = []
        
        # Get all items that contain "ALGEBRA" in their ID (from new structure)
        algebra_item_ids = self._discover_algebra_items()
        
        for item_id in algebra_item_ids:
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
    
    def _discover_algebra_items(self) -> List[str]:
        """Discover all algebra items in the repository."""
        # For now, generate the expected algebra item IDs based on the new structure
        # This matches the IDs from the generated algebra.json
        algebra_ids = []
        
        # Introduction to Algebra (1.1) - 20 questions
        for i in range(1, 21):
            algebra_ids.append(f"ALGEBRA-INTRODUCTION-TO-ALGEBRA-Q{i}")
        
        # Simplifying Algebraic Expressions (1.2) - 20 questions  
        for i in range(1, 21):
            algebra_ids.append(f"ALGEBRA-SIMPLIFYING-ALGEBRAIC-EXPRESSIONS-Q{i}")
            
        # Evaluating Algebraic Expressions (1.3) - 20 questions
        for i in range(1, 21):
            algebra_ids.append(f"ALGEBRA-EVALUATING-ALGEBRAIC-EXPRESSIONS-Q{i}")
            
        # Algebra Word Problems (1.4) - remaining questions
        for i in range(1, 21):
            algebra_ids.append(f"ALGEBRA-ALGEBRA-WORD-PROBLEMS-Q{i}")
        
        return algebra_ids
    
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
    
    def get_next_item_id(self, current_item_id: str, completed_items: List[str]) -> Optional[str]:
        """Get the next item ID in the progression."""
        progression = self.get_algebra_progression()
        
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
    
    def get_progression_status(self, completed_items: List[str]) -> Dict[str, Any]:
        """Get overall progression status."""
        progression = self.get_algebra_progression()
        total_items = len(progression)
        completed_count = len([item_id for item_id in completed_items if item_id in progression])
        
        return {
            "total_items": total_items,
            "completed_count": completed_count,
            "completion_percentage": (completed_count / total_items * 100) if total_items > 0 else 0,
            "next_item_id": self.get_next_item_id(completed_items[-1] if completed_items else "", completed_items),
            "progression_items": progression
        }
    
    def recommend_next_session(self, learner_profile: Dict[str, Any]) -> Optional[str]:
        """Recommend next item based on learner's progress and performance."""
        completed_items = learner_profile.get("completed_items", [])
        progression = self.get_algebra_progression()
        
        # If no completed items, start with first item in progression
        if not completed_items:
            return progression[0] if progression else None
        
        # For now, simple sequential progression
        # TODO: Add adaptive logic based on performance, misconceptions, etc.
        last_completed = completed_items[-1]
        return self.get_next_item_id(last_completed, completed_items)


# Global progression service instance
PROGRESSION_SERVICE = ProgressionService()