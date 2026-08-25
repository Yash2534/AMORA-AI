// Generated-style FlutterFire configuration. Android values are derived from
// the authoritative flavor-specific google-services.json files. Do not add
// service-account credentials or private keys to this client file.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Select with `--dart-define=AMORA_FLAVOR=dev|staging|production`.
class AmoraFirebaseEnvironment {
  const AmoraFirebaseEnvironment._();

  static const name = String.fromEnvironment(
    'AMORA_FLAVOR',
    defaultValue: 'dev',
  );
  static bool get isDevelopment => name == 'dev';

  static void validate() {
    if (name != 'dev' && name != 'staging' && name != 'production') {
      throw UnsupportedError(
        'AMORA_FLAVOR must be dev, staging, or production.',
      );
    }
  }
}

class DefaultFirebaseOptions {
  /// Public VAPID key for web FCM. Supply it at build/run time instead of
  /// committing environment-specific web push configuration.
  static const webPushVapidKey = String.fromEnvironment(
    'AMORA_WEB_PUSH_VAPID_KEY',
  );

  /// Web needs an explicit OAuth client ID; Android resolves it from the
  /// matching google-services.json selected by the Gradle flavor.
  static String? get googleSignInClientId =>
      kIsWeb ? _devGoogleWebClientId : null;

  static FirebaseOptions get currentPlatform {
    AmoraFirebaseEnvironment.validate();
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (AmoraFirebaseEnvironment.name != 'dev') {
          throw UnsupportedError(
            'This repository has no ${AmoraFirebaseEnvironment.name} iOS/macOS Firebase configuration.',
          );
        }
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError('Firebase desktop support is not configured.');
      default:
        throw UnsupportedError('Firebase is not supported on this platform.');
    }
  }

  /// Chrome has an existing dev Firebase web app only. Supply FlutterFire web
  /// configuration for staging/production before running those targets.
  static FirebaseOptions get web {
    if (AmoraFirebaseEnvironment.name != 'dev') {
      throw UnsupportedError(
        'No ${AmoraFirebaseEnvironment.name} Firebase web app configuration is available.',
      );
    }
    return _devWeb;
  }

  static FirebaseOptions get android => switch (AmoraFirebaseEnvironment.name) {
    'dev' => _devAndroid,
    'staging' => _stagingAndroid,
    'production' => _productionAndroid,
    _ => throw UnsupportedError('Unsupported Firebase environment.'),
  };

  static const FirebaseOptions _devWeb = FirebaseOptions(
    apiKey: 'AIzaSyCXVooAey8oNhbKDg38qjOiJVfQBx4rmQY',
    appId: '1:480914480895:web:1ea186f293feafa66476ca',
    messagingSenderId: '480914480895',
    projectId: 'kinetictecharc-app-dev',
    authDomain: 'kinetictecharc-app-dev.firebaseapp.com',
    storageBucket: 'kinetictecharc-app-dev.firebasestorage.app',
    measurementId: 'G-MNND6LH01R',
  );

  static const String _devGoogleWebClientId =
      '480914480895-17higrdmqu9u0etogj8lbj0abnut07nc.apps.googleusercontent.com';

  static const FirebaseOptions _devAndroid = FirebaseOptions(
    apiKey: 'AIzaSyCBpgb55W-_57MpIsd4Eamv6d5L-4fS-sY',
    appId: '1:480914480895:android:789eac666c6f98596476ca',
    messagingSenderId: '480914480895',
    projectId: 'kinetictecharc-app-dev',
    storageBucket: 'kinetictecharc-app-dev.firebasestorage.app',
  );

  static const FirebaseOptions _stagingAndroid = FirebaseOptions(
    apiKey: 'AIzaSyBmPGPtkHfA8_maLNJ-M0wFMsS1TsY5PIQ',
    appId: '1:348078187236:android:2ab10b4180837287e842f1',
    messagingSenderId: '348078187236',
    projectId: 'kinetictecharc-app-staging',
    storageBucket: 'kinetictecharc-app-staging.firebasestorage.app',
  );

  static const FirebaseOptions _productionAndroid = FirebaseOptions(
    apiKey: 'AIzaSyAkZtq_EGXwxQQ3I-GxBsX_YEaF7yCSz4g',
    appId: '1:413960132847:android:74c1d3df817350899aa31a',
    messagingSenderId: '413960132847',
    projectId: 'kinetictecharc-app-prod',
    storageBucket: 'kinetictecharc-app-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD1As6RFzg-i5fPsfTtBGaN021xxpwlH-k',
    appId: '1:480914480895:ios:dd5054814986a8956476ca',
    messagingSenderId: '480914480895',
    projectId: 'kinetictecharc-app-dev',
    storageBucket: 'kinetictecharc-app-dev.firebasestorage.app',
    androidClientId:
        '480914480895-nka9p534fh5qubd1a4tjuimotvbbbiod.apps.googleusercontent.com',
    iosClientId:
        '480914480895-elfh8n0gu7952t4m2d9rks9ru3495f7a.apps.googleusercontent.com',
    iosBundleId: 'com.example.amoraAi',
  );
}
