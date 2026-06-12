// File generated from Firebase project hospynav-b6fae.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCvt3MVgES4M8GRXsVZHSckNBYHVp2wLN4',
    appId: '1:462932257595:web:6d6153921cafd6f4afe51e',
    messagingSenderId: '462932257595',
    projectId: 'hospynav-b6fae',
    authDomain: 'hospynav-b6fae.firebaseapp.com',
    storageBucket: 'hospynav-b6fae.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvt3MVgES4M8GRXsVZHSckNBYHVp2wLN4',
    appId: '1:462932257595:android:7ac9b05e513817ebafe51e',
    messagingSenderId: '462932257595',
    projectId: 'hospynav-b6fae',
    storageBucket: 'hospynav-b6fae.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCvt3MVgES4M8GRXsVZHSckNBYHVp2wLN4',
    appId: '1:462932257595:ios:21cab9768d5aa734afe51e',
    messagingSenderId: '462932257595',
    projectId: 'hospynav-b6fae',
    storageBucket: 'hospynav-b6fae.firebasestorage.app',
    iosBundleId: 'com.example.hospyNav',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCvt3MVgES4M8GRXsVZHSckNBYHVp2wLN4',
    appId: '1:462932257595:ios:21cab9768d5aa734afe51e',
    messagingSenderId: '462932257595',
    projectId: 'hospynav-b6fae',
    storageBucket: 'hospynav-b6fae.firebasestorage.app',
    iosBundleId: 'com.example.hospyNav',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCvt3MVgES4M8GRXsVZHSckNBYHVp2wLN4',
    appId: '1:462932257595:web:f9accddff7439ae7afe51e',
    messagingSenderId: '462932257595',
    projectId: 'hospynav-b6fae',
    authDomain: 'hospynav-b6fae.firebaseapp.com',
    storageBucket: 'hospynav-b6fae.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCvt3MVgES4M8GRXsVZHSckNBYHVp2wLN4',
    appId: '1:462932257595:web:6d6153921cafd6f4afe51e',
    messagingSenderId: '462932257595',
    projectId: 'hospynav-b6fae',
    authDomain: 'hospynav-b6fae.firebaseapp.com',
    storageBucket: 'hospynav-b6fae.firebasestorage.app',
  );
}
