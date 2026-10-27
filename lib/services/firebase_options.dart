import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Stillwater Sovereign Suite (stillwater-sovereign-04)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATea1-uZdqI7oniJSL9Y1w3yRTAlL45yk',
    appId: '1:21782395147:web:15420b58e727fc9503ca0e',
    messagingSenderId: '21782395147',
    projectId: 'stillwater-sovereign-04',
    authDomain: 'stillwater-sovereign-04.firebaseapp.com',
    storageBucket: 'stillwater-sovereign-04.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBamDJj1PIhbODHeXvxqt3m0pw2OMKz7V8',
    appId: '1:21782395147:android:6b0219cece7d5d6703ca0e',
    messagingSenderId: '21782395147',
    projectId: 'stillwater-sovereign-04',
    storageBucket: 'stillwater-sovereign-04.firebasestorage.app',
  );
}
