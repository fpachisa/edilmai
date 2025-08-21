import 'package:firebase_core/firebase_core.dart';

  class DefaultFirebaseOptions {
    static FirebaseOptions get currentPlatform => web;

    static const FirebaseOptions web = FirebaseOptions(
      apiKey: 'AIzaSyAu3RkvFhwd7uorpxh52vST_TIAH6Y3Dus',
      appId: '1:693849775003:web:3f02ef25dfecf494ac1f3e',
      messagingSenderId: '693849775003',
      projectId: 'edilmai',
      authDomain: 'edilmai.firebaseapp.com',
      storageBucket: 'edilmai.appspot.com',
      measurementId: 'G-ZYCSPYZ5B3',
    );
  }
