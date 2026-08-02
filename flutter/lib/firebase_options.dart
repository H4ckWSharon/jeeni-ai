import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return android; // fallback
      default:
        return android; // fallback
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBQ0m4O7cORtjlTrRkEyM59sIcvve9-13A',
    appId: '1:1059673395517:web:eb770bd673c649d1603554',
    messagingSenderId: '1059673395517',
    projectId: 'jeeni-ai',
    authDomain: 'jeeni-ai.firebaseapp.com',
    storageBucket: 'jeeni-ai.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQ0m4O7cORtjlTrRkEyM59sIcvve9-13A',
    appId: '1:1059673395517:android:eb770bd673c649d1603554',
    messagingSenderId: '1059673395517',
    projectId: 'jeeni-ai',
    authDomain: 'jeeni-ai.firebaseapp.com',
    storageBucket: 'jeeni-ai.firebasestorage.app',
  );
}
