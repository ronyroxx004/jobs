// File generated for jobs Firebase project.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7KI9loWQJw4k-HIJZLhpkW9_LJzsX43o',
    appId: '1:661848855589:android:701265b3e45099ba419bcc',
    messagingSenderId: '661848855589',
    projectId: 'jobs-37214',
    databaseURL: 'https://jobs-37214-default-rtdb.firebaseio.com',
    storageBucket: 'jobs-37214.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3aZcfD4lKC0797YJLHrLaZCIpZxUEudo',
    appId: '1:661848855589:ios:749e4bd283782b5b419bcc',
    messagingSenderId: '661848855589',
    projectId: 'jobs-37214',
    databaseURL: 'https://jobs-37214-default-rtdb.firebaseio.com',
    storageBucket: 'jobs-37214.firebasestorage.app',
    iosBundleId: 'com.portal.jobs',
  );
}
