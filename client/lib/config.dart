// API base URL can be overridden at build time with:
// flutter run -d chrome --dart-define=API_BASE=http://localhost:8000
const String kDefaultApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://localhost:8000',
);

const bool kUseFirebaseAuth = bool.fromEnvironment(
  'USE_FIREBASE_AUTH',
  defaultValue: true,
);
