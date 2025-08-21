#!/usr/bin/env python3
"""
Debug script to test progression flow for different topics
"""
import os
import sys
sys.path.append('/Users/farhat/Documents/AI Systems/AITutor/edilmai/edilmai')

# Set environment
os.environ['ENV'] = 'dev'
os.environ['PYTHONPATH'] = '/Users/farhat/Documents/AI Systems/AITutor/edilmai/edilmai'

def test_progression(topic_name):
    """Test progression for a specific topic"""
    print(f"\n{'='*60}")
    print(f"🔍 TESTING PROGRESSION FOR: {topic_name.upper()}")
    print(f"{'='*60}")
    
    try:
        # Import after setting path
        from api.services.container import PROGRESSION_SERVICE, ITEMS_REPO
        
        # Get progression for topic
        progression = PROGRESSION_SERVICE.get_topic_progression(topic_name)
        print(f"📊 Total items in {topic_name} progression: {len(progression)}")
        
        if progression:
            print(f"📝 First 5 items:")
            for i, item_id in enumerate(progression[:5]):
                print(f"  {i+1}. {item_id}")
            if len(progression) > 5:
                print(f"  ... and {len(progression) - 5} more")
                
            # Test recommendation logic
            print(f"\n🎯 TESTING RECOMMENDATION LOGIC:")
            
            # Test with no completed items
            fake_profile_empty = {'completed_items': [], 'learner_id': 'test-learner'}
            recommended = PROGRESSION_SERVICE.recommend_next_session(fake_profile_empty, topic_name)
            print(f"📋 No completed items → recommended: {recommended}")
            
            # Test after completing first item
            first_item = progression[0]
            fake_profile_one = {'completed_items': [first_item], 'learner_id': 'test-learner'}
            recommended = PROGRESSION_SERVICE.recommend_next_session(fake_profile_one, topic_name)
            print(f"📋 After completing {first_item} → recommended: {recommended}")
            
            # Test after completing first two items
            if len(progression) > 1:
                second_item = progression[1]
                fake_profile_two = {'completed_items': [first_item, second_item], 'learner_id': 'test-learner'}
                recommended = PROGRESSION_SERVICE.recommend_next_session(fake_profile_two, topic_name)
                print(f"📋 After completing {first_item}, {second_item} → recommended: {recommended}")
        else:
            print(f"❌ NO PROGRESSION FOUND for {topic_name}")
            
    except Exception as e:
        print(f"❌ ERROR testing {topic_name}: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # Test multiple topics
    topics_to_test = ['fractions', 'algebra', 'geometry', 'percentage', 'ratio', 'speed']
    
    for topic in topics_to_test:
        test_progression(topic)
    
    print(f"\n{'='*60}")
    print("🏁 PROGRESSION TESTING COMPLETE")
    print(f"{'='*60}")