// firebase_options.dart
// ⚠️ IMPORTANT: Replace this file by running:
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//
// Until then, replace the placeholder values below with your actual Firebase config
// found in Firebase Console → Project Settings → Your apps.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAozERus09C0McHWrOkRWOPcBLUC7a7WDE',
    appId: '1:754609252198:android:6d0ecd1cdbbdacd996caa7',
    messagingSenderId: '754609252198',
    projectId: 'campus-navigation-96319',
    storageBucket: 'campus-navigation-96319.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-firebase-project-id',
    storageBucket: 'your-firebase-project-id.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.uninav.campus_navigation',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'your-firebase-project-id',
    storageBucket: 'your-firebase-project-id.appspot.com',
    authDomain: 'your-firebase-project-id.firebaseapp.com',
  );
}
