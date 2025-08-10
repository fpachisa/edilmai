import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config.dart';
import 'firebase_options.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> init() async {
    if (!kUseFirebaseAuth) return;
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  static Future<String?> getIdToken() async {
    if (!kUseFirebaseAuth) return null;
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }
}

