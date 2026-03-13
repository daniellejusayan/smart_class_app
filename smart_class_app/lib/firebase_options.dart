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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCoX0F2HlJY5Le1N5UPNC-VUEpNWwK-Bao',
    authDomain: 'smart-class-app-b42fd.firebaseapp.com',
    projectId: 'smart-class-app-b42fd',
    storageBucket: 'smart-class-app-b42fd.firebasestorage.app',
    messagingSenderId: '1081457713264',
    appId: '1:1081457713264:web:c2e613b24947e53decd4b5',
    measurementId: 'G-NQRS3YCGY8',
  );

  // Android config — paste your google-services.json values here
  // These values come from your google-services.json file
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoX0F2HlJY5Le1N5UPNC-VUEpNWwK-Bao',
    appId: '1:1081457713264:android:REPLACE_WITH_ANDROID_APP_ID',
    messagingSenderId: '1081457713264',
    projectId: 'smart-class-app-b42fd',
    storageBucket: 'smart-class-app-b42fd.firebasestorage.app',
  );
}
