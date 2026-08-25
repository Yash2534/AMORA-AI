import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

typedef DeviceTokenRegistrar =
    Future<void> Function(String token, String platform);
typedef NotificationOpenHandler = void Function(RemoteMessage message);

@pragma('vm:entry-point')
Future<void> amoraFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.log(
      'Received a background push message.',
    );
  }
}

/// One place for non-sensitive Firebase lifecycle work. The AMORAA backend JWT
/// remains the authorization credential for API calls; Firebase is not used to
/// grant backend access without server-side token verification.
class FirebaseService {
  FirebaseService._();

  static final instance = FirebaseService._();
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();
  DeviceTokenRegistrar? _deviceTokenRegistrar;
  NotificationOpenHandler? _notificationOpenHandler;
  RemoteMessage? _pendingOpen;
  String? _lastDeviceToken;
  bool _initialized = false;

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    FirebaseMessaging.onBackgroundMessage(
      amoraFirebaseMessagingBackgroundHandler,
    );

    await _activateAppCheck();
    await _configureCrashReporting();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(
        _logAnalytics('firebase_auth_state_changed', <String, Object>{
          'signed_in': user == null ? 0 : 1,
        }),
      );
    });
    FirebaseMessaging.onMessage.listen((message) {
      _foregroundMessages.add(message);
      unawaited(
        _logAnalytics('push_received_foreground', <String, Object>{
          'has_data': message.data.isEmpty ? 0 : 1,
        }),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_deliverOpenedMessage);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _pendingOpen = initial;
  }

  Future<void> _activateAppCheck() async {
    if (kIsWeb) return;
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AmoraFirebaseEnvironment.isDevelopment
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  }

  Future<void> _configureCrashReporting() async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode || const bool.fromEnvironment('AMORA_CRASHLYTICS_DEBUG'),
    );
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> signInWithGoogleCredential({
    required String idToken,
    required String? accessToken,
  }) async {
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void bindAuthenticatedDevice(DeviceTokenRegistrar registrar) {
    _deviceTokenRegistrar = registrar;
    unawaited(_registerCurrentToken());
  }

  Future<String?> currentToken() async => _lastDeviceToken;

  void clearAuthenticatedDevice() => _deviceTokenRegistrar = null;

  void setNotificationOpenHandler(NotificationOpenHandler handler) {
    _notificationOpenHandler = handler;
    final pending = _pendingOpen;
    if (pending != null) {
      _pendingOpen = null;
      handler(pending);
    }
  }

  void _deliverOpenedMessage(RemoteMessage message) {
    final handler = _notificationOpenHandler;
    if (handler == null) {
      _pendingOpen = message;
    } else {
      handler(message);
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _tokenForCurrentPermission();
      final registrar = _deviceTokenRegistrar;
      if (token != null && registrar != null) await registrar(token, _platform);
    } catch (error, stack) {
      await recordNonFatal(error, stack, reason: 'device_token_registration');
    }
  }

  Future<String?> _tokenForCurrentPermission() async {
    if (kIsWeb && DefaultFirebaseOptions.webPushVapidKey.isEmpty) {
      return null;
    }
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      return null;
    }
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb ? DefaultFirebaseOptions.webPushVapidKey : null,
      serviceWorkerScriptPath: kIsWeb ? '/firebase-messaging-sw.js' : null,
    );
    _lastDeviceToken = token;
    return token;
  }

  void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _lastDeviceToken = token;
      final registrar = _deviceTokenRegistrar;
      if (registrar == null) return;
      try {
        await registrar(token, _platform);
      } catch (error, stack) {
        await recordNonFatal(error, stack, reason: 'device_token_refresh');
      }
    });
  }

  Future<void> logAuthEvent(String name, {String? method}) => _logAnalytics(
    name,
    method == null ? null : <String, Object>{'method': method},
  );

  Future<void> logOnboardingStep(String step) => _logAnalytics(
    'onboarding_step_completed',
    <String, Object>{'step': step},
  );

  Future<void> _logAnalytics(
    String name,
    Map<String, Object>? parameters,
  ) async {
    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } catch (error, stack) {
      await recordNonFatal(error, stack, reason: 'analytics_$name');
    }
  }

  Future<void> recordNonFatal(
    Object error,
    StackTrace stack, {
    required String reason,
  }) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (_) {
      // Reporting must never interrupt the user flow.
    }
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'web',
    };
  }
}
