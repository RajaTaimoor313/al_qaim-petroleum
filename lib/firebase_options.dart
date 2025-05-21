import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBRUIB6CJTZGUmcv1b_bJHhzlgAOt8cRss',
    appId: '1:123655572763:web:991c73f70c0c380bb217be',
    messagingSenderId: '123655572763',
    projectId: 'al-qaim-6c510',
    authDomain: 'al-qaim-6c510.firebaseapp.com',
    storageBucket: 'al-qaim-6c510.firebasestorage.app',
    measurementId: 'G-JQHEQ6H0WX',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCdiGqTGfYOYlHLd3ef4yf2VUInhuugsJY',
    appId: '1:123655572763:ios:9b3f233c443a7ea7b217be',
    messagingSenderId: '123655572763',
    projectId: 'al-qaim-6c510',
    storageBucket: 'al-qaim-6c510.firebasestorage.app',
    iosBundleId: 'com.example.alQaim',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCdiGqTGfYOYlHLd3ef4yf2VUInhuugsJY',
    appId: '1:123655572763:ios:9b3f233c443a7ea7b217be',
    messagingSenderId: '123655572763',
    projectId: 'al-qaim-6c510',
    storageBucket: 'al-qaim-6c510.firebasestorage.app',
    iosBundleId: 'com.example.alQaim',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCF2EEbMNp1IKfnOg0dNN02t4_Xfd8EE34',
    appId: '1:123655572763:android:b879af28c29f91cbb217be',
    messagingSenderId: '123655572763',
    projectId: 'al-qaim-6c510',
    storageBucket: 'al-qaim-6c510.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBRUIB6CJTZGUmcv1b_bJHhzlgAOt8cRss',
    appId: '1:123655572763:web:74449a8c539161fdb217be',
    messagingSenderId: '123655572763',
    projectId: 'al-qaim-6c510',
    authDomain: 'al-qaim-6c510.firebaseapp.com',
    storageBucket: 'al-qaim-6c510.firebasestorage.app',
    measurementId: 'G-QYF6WZWF2F',
  );
}