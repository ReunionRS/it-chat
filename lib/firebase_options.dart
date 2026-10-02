import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
        'Зарегистрируйте Android/iOS приложение через flutterfire configure.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: '1:959980227800:web:9afb8b99c66bbd4f76dbad',
    messagingSenderId: '959980227800',
    projectId: 'itchat-eaa60',
    authDomain: 'itchat-eaa60.firebaseapp.com',
    storageBucket: 'itchat-eaa60.firebasestorage.app',
    measurementId: 'G-83M4DV1ZLV',
  );
}
