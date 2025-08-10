# EDIL AI Tutor Client (Flutter)

This is the Flutter client for iOS/Android/Web. This scaffold talks to the local API and supports ingest → start session → submit answer.

## Quick start

1) If not already created, generate platform scaffolds in this `client/` directory:

```bash
cd client
flutter create .
```

2) Get dependencies and run (web):

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000
```

3) Or run on iOS/Android:

```bash
flutter run --dart-define=API_BASE=http://<YOUR_MACHINE_IP>:8000
```

Note: For iOS/Android dev with http URLs, enable local network access / cleartext traffic in the platform configs.

## Enable Firebase Auth (optional, recommended)

This lets the client obtain a Firebase ID token and send it as `Authorization: Bearer <token>` to the API.

1) Install FlutterFire CLI and configure the project:

```bash
dart pub global activate flutterfire_cli
cd client
flutterfire configure -p edilmai
```

This generates `lib/firebase_options.dart` with your project’s config.

2) Run the API with auth required (new terminal):

```bash
cd api
export AUTH_STUB=false
export FIREBASE_PROJECT_ID=edilmai
export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json
uvicorn main:app --reload --port 8000
```

3) Run the Flutter client with Firebase auth enabled:

```bash
cd client
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000 --dart-define=USE_FIREBASE_AUTH=true
```

The app signs in anonymously and attaches the ID token to API requests.

This scaffold uses `--dart-define=API_BASE=...` to set the backend base URL. Default is `http://localhost:8000`.
