// File generated by FlutterFire CLI.
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCk1Go2HvzPneHyHbyyvW7lolaWlqKoIek',
    appId: '1:157722183443:web:1b38b1af3a532d9e65fce6',
    messagingSenderId: '157722183443',
    projectId: 'shopeeapp',
    authDomain: 'shopeeapp.firebaseapp.com',
    storageBucket: 'shopeeapp.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBNe9NLai4_mGhoTqDqm98YeD4A0zLhgvw',
    appId: '1:157722183443:android:c72b1c434d3e355565fce6',
    messagingSenderId: '157722183443',
    projectId: 'shopeeapp',
    storageBucket: 'shopeeapp.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBIl5SGoh1VqfYBhbcu7kqELLkOCkJbMFo',
    appId: '1:157722183443:ios:61b3bd03328b109c65fce6',
    messagingSenderId: '157722183443',
    projectId: 'shopeeapp',
    storageBucket: 'shopeeapp.appspot.com',
    iosBundleId: 'com.example.finalYearApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBIl5SGoh1VqfYBhbcu7kqELLkOCkJbMFo',
    appId: '1:157722183443:ios:61b3bd03328b109c65fce6',
    messagingSenderId: '157722183443',
    projectId: 'shopeeapp',
    storageBucket: 'shopeeapp.appspot.com',
    iosBundleId: 'com.example.finalYearApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCk1Go2HvzPneHyHbyyvW7lolaWlqKoIek',
    appId: '1:157722183443:web:432617a00f714fef65fce6',
    messagingSenderId: '157722183443',
    projectId: 'shopeeapp',
    authDomain: 'shopeeapp.firebaseapp.com',
    storageBucket: 'shopeeapp.appspot.com',
  );

}