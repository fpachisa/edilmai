from .repositories import InMemoryItemsRepo, InMemorySessionsRepo, InMemoryProfilesRepo


# Simple shared singletons for dev/testing. Replace with Firestore-backed repos later.
ITEMS_REPO = InMemoryItemsRepo()
SESSIONS_REPO = InMemorySessionsRepo()
PROFILES_REPO = InMemoryProfilesRepo()

