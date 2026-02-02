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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Firebase Console'dan alınan değerlerle değiştirin
  // flutterfire configure komutu ile otomatik oluşturulabilir
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCNuvzOOgu14wZtW12ZpSVrZ9_G7A9E9_g',
    appId: '1:360048908674:web:835a1b2e477aac531a979b',
    messagingSenderId: '360048908674',
    projectId: 'fiyatradar-611967',
    authDomain: 'fiyatradar-611967.firebaseapp.com',
    storageBucket: 'fiyatradar-611967.firebasestorage.app',
    measurementId: 'G-FZL57463WD',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNuvzOOgu14wZtW12ZpSVrZ9_G7A9E9_g',
    appId: '1:360048908674:android:0577b2185257df381a979b',
    messagingSenderId: '360048908674',
    projectId: 'fiyatradar-611967',
    storageBucket: 'fiyatradar-611967.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNuvzOOgu14wZtW12ZpSVrZ9_G7A9E9_g',
    appId: '1:360048908674:ios:cd3e0587747e93541a979b',
    messagingSenderId: '360048908674',
    projectId: 'fiyatradar-611967',
    storageBucket: 'fiyatradar-611967.firebasestorage.app',
    iosBundleId: 'com.fiyatradar',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCNuvzOOgu14wZtW12ZpSVrZ9_G7A9E9_g',
    appId: '1:360048908674:ios:cd3e0587747e93541a979b',
    messagingSenderId: '360048908674',
    projectId: 'fiyatradar-611967',
    storageBucket: 'fiyatradar-611967.firebasestorage.app',
    iosBundleId: 'com.fiyatradar',
  );
}
