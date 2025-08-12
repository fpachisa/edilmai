import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'config.dart';
import 'firebase_options.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }
  
  static Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      // Return a stream with null user if Firebase isn't initialized
      return Stream.value(null);
    }
  }

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      // Don't auto sign-in anonymously - let users choose their auth method
    } catch (e) {
      // Firebase initialization failed
      print('Firebase initialization error: $e');
    }
  }

  static Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('AuthService: Starting Google Sign-in process');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('AuthService: GoogleSignInAccount result: ${googleUser?.email ?? 'null'}');
      print('AuthService: User display name: ${googleUser?.displayName ?? 'null'}');
      
      if (googleUser == null) {
        print('AuthService: User cancelled Google Sign-in');
        return null;
      }

      print('AuthService: Getting authentication tokens');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('AuthService: Got tokens - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('AuthService: Created Firebase credential');

      print('AuthService: Signing in with Firebase credential');
      final result = await _auth.signInWithCredential(credential);
      print('AuthService: Firebase sign-in successful: ${result.user?.uid ?? 'null'}');
      print('AuthService: Firebase auth currentUser: ${_auth.currentUser?.uid ?? 'null'}');
      
      return result;
    } catch (e) {
      print('AuthService: Exception during Google Sign-in: $e');
      if (e.toString().contains('ClientId') || e.toString().contains('CLIENT_ID')) {
        throw AuthException('Google sign-in configuration error. Please contact support.');
      }
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  static Future<UserCredential?> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      return await _auth.signInWithProvider(appleProvider);
    } catch (e) {
      throw AuthException('Apple sign-in is not available. Please use email or Google authentication.');
    }
  }

  static Future<UserCredential> createAccountWithEmail(
    String email, 
    String password, 
    {String? displayName}
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  static Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  static String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in instead.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

