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
    apiKey: 'AIzaSyC36rLfZ6RaF7ijmuKDStPF0AeQNlgCPZY',
    appId: '1:453221488701:web:11d9e28df10893263ab254',
    messagingSenderId: '453221488701',
    projectId: 'timer-537ba',
    authDomain: 'timer-537ba.firebaseapp.com',
    storageBucket: 'timer-537ba.firebasestorage.app',
    measurementId: 'G-3XX6VXKQQM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCb9Yfwq9cFF0BFFklEpHtaPMj9fvQ84yk',
    appId: '1:453221488701:android:fc369975be42b6b73ab254',
    messagingSenderId: '453221488701',
    projectId: 'timer-537ba',
    storageBucket: 'timer-537ba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAz4NBjrtEBALuAoBwMPnHQhGzVjC7_ZH0',
    appId: '1:453221488701:ios:1c232aa9aaa98c923ab254',
    messagingSenderId: '453221488701',
    projectId: 'timer-537ba',
    storageBucket: 'timer-537ba.firebasestorage.app',
    iosBundleId: 'com.example.project1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAz4NBjrtEBALuAoBwMPnHQhGzVjC7_ZH0',
    appId: '1:453221488701:ios:1c232aa9aaa98c923ab254',
    messagingSenderId: '453221488701',
    projectId: 'timer-537ba',
    storageBucket: 'timer-537ba.firebasestorage.app',
    iosBundleId: 'com.example.project1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC36rLfZ6RaF7ijmuKDStPF0AeQNlgCPZY',
    appId: '1:453221488701:web:81bfd1586b0ade4a3ab254',
    messagingSenderId: '453221488701',
    projectId: 'timer-537ba',
    authDomain: 'timer-537ba.firebaseapp.com',
    storageBucket: 'timer-537ba.firebasestorage.app',
    measurementId: 'G-BF1FR6JG12',
  );
}