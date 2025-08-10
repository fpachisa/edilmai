from __future__ import annotations
from typing import List, Dict, Optional, Any
from services.container import ITEMS_REPO


class ProgressionService:
    """Manages multi-item learning progression through algebra topics."""
    
    def __init__(self):
        pass
    
    def get_algebra_progression(self) -> List[str]:
        """Get ordered list of algebra item IDs for progression."""
        # Get all algebra items and sort by difficulty/learn_step
        all_items = {}
        # Since we don't have direct access to iterate items, we'll use known IDs for now
        known_algebra_ids = [
            "ALG-S1-E1",  # Adding to an Unknown
            "ALG-S1-E2",  # Multiplying an Unknown  
            "ALG-S1-M1",  # Division as a Fraction
        ]
        
        # Filter existing items and sort by difficulty
        available_items = []
        for item_id in known_algebra_ids:
            item = ITEMS_REPO.get_item(item_id)
            if item:
                available_items.append({
                    "id": item_id,
                    "difficulty": item.get("difficulty", 0.5),
                    "learn_step": item.get("learn_step", 1),
                    "complexity": item.get("complexity", "Easy")
                })
        
        # Sort by learn_step, then difficulty
        available_items.sort(key=lambda x: (x["learn_step"], x["difficulty"]))
        return [item["id"] for item in available_items]
    
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
        
        # For now, simple sequential progression
        # TODO: Add adaptive logic based on performance, misconceptions, etc.
        last_completed = completed_items[-1] if completed_items else ""
        return self.get_next_item_id(last_completed, completed_items)


# Global progression service instance
PROGRESSION_SERVICE = ProgressionService()