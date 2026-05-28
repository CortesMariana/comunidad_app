import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
            'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCAlccYVOzDCpSdaV2pHplNKmDfOiJ02EE',
    appId: '1:1017950554459:android:fe057a255311b2bae2f27e',
    messagingSenderId: '1017950554459',
    projectId: 'comunidad-one',
    storageBucket: 'comunidad-one.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCVCe15ADLttBTJxTlpKsW7os0Z1XjvX5o',
    appId: '1:1017950554459:ios:ee7f7590585bab9ae2f27e',
    messagingSenderId: '1017950554459',
    projectId: 'comunidad-one',
    storageBucket: 'comunidad-one.firebasestorage.app',
    iosBundleId: 'com.comunidad.comunidadApp',
  );
}