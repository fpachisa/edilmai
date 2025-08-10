# Firebase Config

Artifacts for Firestore and Storage security rules, plus notes for App Check and Remote Config.

## Deploy Rules

```bash
firebase deploy --only firestore:rules,storage:rules --project <PROJECT_ID>
```

## App Check

- Enable App Check for iOS/Android/Web in Firebase Console.
- Add SDK to Flutter client and enforce checks on server for sensitive endpoints.

## Remote Config

- Store feature flags (e.g., hint ladder depth, animation intensity) and use in client.

