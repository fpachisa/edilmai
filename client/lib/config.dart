// API base URL can be overridden at build time with:
// flutter run -d chrome --dart-define=API_BASE=http://localhost:8000
const String kDefaultApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://edilmai.as.r.appspot.com',
);

const bool kUseFirebaseAuth = bool.fromEnvironment(
  'USE_FIREBASE_AUTH',
  defaultValue: true,
);

// Gate Firestore writes from the web client in production.
// Backend API should own writes to protected collections (sessions/learners).
// Enable in dev with: --dart-define=ALLOW_CLIENT_FIRESTORE_WRITES=true
const bool kAllowClientFirestoreWrites = bool.fromEnvironment(
  'ALLOW_CLIENT_FIRESTORE_WRITES',
  defaultValue: false,
);

// Feature flag: enable the new sample-based theme
// flutter run --dart-define=UI_NEW_THEME=true
const bool kNewThemeEnabled = bool.fromEnvironment(
  'UI_NEW_THEME',
  defaultValue: false,
);
