import 'dart:async';
import 'dart:math';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/widgets/amora_top_notification.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/notifications/data/notification_deep_link.dart';
import 'package:amora_ai/features/notifications/data/notification_inbox_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

enum PushAuthorizationState { notDetermined, granted, denied }

class PushEnvelope {
  const PushEnvelope({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
  });

  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
}

abstract interface class PushMessagingGateway {
  Future<PushAuthorizationState> authorizationState();
  Future<PushAuthorizationState> requestPermission();
  Future<String?> token();
  Stream<String> get tokenRefreshes;
  Stream<PushEnvelope> get foregroundMessages;
  Stream<PushEnvelope> get openedMessages;
  Future<PushEnvelope?> initialMessage();
}

abstract interface class PushTokenRegistrar {
  Future<bool> registerPushToken(
    String token, {
    String? platform,
    String? installationId,
  });
  Future<bool> unregisterPushToken(String token);
}

class NotificationInboxPushTokenRegistrar implements PushTokenRegistrar {
  const NotificationInboxPushTokenRegistrar(this.repository);

  final NotificationInboxRepository repository;

  @override
  Future<bool> registerPushToken(
    String token, {
    String? platform,
    String? installationId,
  }) => repository.registerPushToken(
    token,
    platform: platform,
    installationId: installationId,
  );

  @override
  Future<bool> unregisterPushToken(String token) =>
      repository.unregisterPushToken(token);
}

class PushTokenCoordinator {
  PushTokenCoordinator({
    required this.gateway,
    required this.registrar,
    required this.authenticatedUserId,
    required this.platform,
    required this.installationId,
  });

  final PushMessagingGateway gateway;
  final PushTokenRegistrar registrar;
  final String? Function() authenticatedUserId;
  final String platform;
  final Future<String> Function() installationId;
  StreamSubscription<String>? _refreshSubscription;
  String? _registeredToken;
  String? _registeredUserId;

  void listenForRefreshes() {
    _refreshSubscription ??= gateway.tokenRefreshes.listen(
      (token) => unawaited(_register(token)),
    );
  }

  Future<bool> sync({bool requestPermission = true}) async {
    if (authenticatedUserId() == null) return false;
    var authorization = await gateway.authorizationState();
    if (authorization == PushAuthorizationState.notDetermined &&
        requestPermission) {
      authorization = await gateway.requestPermission();
    }
    if (authorization != PushAuthorizationState.granted) return false;
    final token = (await gateway.token())?.trim() ?? '';
    if (token.isEmpty) return false;
    listenForRefreshes();
    return _register(token);
  }

  Future<bool> _register(String token) async {
    final userId = authenticatedUserId();
    final cleanToken = token.trim();
    if (userId == null || cleanToken.isEmpty) return false;
    if (_registeredToken == cleanToken && _registeredUserId == userId) {
      return true;
    }
    final registered = await registrar.registerPushToken(
      cleanToken,
      platform: platform,
      installationId: await installationId(),
    );
    if (!registered) return false;
    final previousToken = _registeredToken;
    _registeredToken = cleanToken;
    _registeredUserId = userId;
    if (previousToken != null && previousToken != cleanToken) {
      await registrar.unregisterPushToken(previousToken);
    }
    return true;
  }

  Future<void> unregister() async {
    final token = _registeredToken ?? (await gateway.token())?.trim();
    if (token != null && token.isNotEmpty && authenticatedUserId() != null) {
      await registrar.unregisterPushToken(token);
    }
    _registeredToken = null;
    _registeredUserId = null;
  }

  void forgetRegistration() {
    _registeredToken = null;
    _registeredUserId = null;
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();
  static const _installationKey = 'amora_push_installation_id';
  static const _storage = FlutterSecureStorage();

  PushTokenCoordinator? _coordinator;
  final Set<String> _handledMessageIds = <String>{};
  PushEnvelope? _pendingNavigation;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !_supportsPush) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      final gateway = _FirebasePushMessagingGateway();
      _coordinator = PushTokenCoordinator(
        gateway: gateway,
        registrar: NotificationInboxPushTokenRegistrar(
          NotificationInboxRepository.instance,
        ),
        authenticatedUserId: () =>
            AuthService.instance.currentUser?.id.toString(),
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        installationId: _loadInstallationId,
      );
      gateway.foregroundMessages.listen(_handleForeground);
      gateway.openedMessages.listen(_handleOpened);
      _pendingNavigation = await gateway.initialMessage();
      _initialized = true;
    } catch (_) {
      // Missing native Firebase configuration must not prevent app startup.
    }
  }

  Future<bool> syncForAuthenticatedUser({bool requestPermission = true}) async {
    if (!_initialized) await initialize();
    final result = await _coordinator?.sync(
      requestPermission: requestPermission,
    );
    return result ?? false;
  }

  Future<void> unregisterCurrentDevice() async {
    try {
      await _coordinator?.unregister();
    } catch (_) {
      // Logout continues even when the device is temporarily offline.
    }
  }

  void forgetCurrentDeviceRegistration() {
    _coordinator?.forgetRegistration();
  }

  void flushPendingNavigation() {
    final pending = _pendingNavigation;
    if (pending == null || AuthService.instance.currentUser == null) return;
    _pendingNavigation = null;
    _navigate(pending);
  }

  void _handleForeground(PushEnvelope message) {
    if (!_claim(message)) return;
    if (message.data['type'] == 'new_message' &&
        ChatRepository.instance.realtimeConnected) {
      return;
    }
    final destination = NotificationDeepLink.resolve(message.data);
    AmoraTopNotificationManager.showGlobal(
      title: message.title,
      message: message.body,
      type: _presentationType(message.data),
      onTap: () => _navigateTo(destination),
    );
  }

  void _handleOpened(PushEnvelope message) {
    if (!_claim(message)) return;
    if (AuthService.instance.currentUser == null) {
      _pendingNavigation = message;
      return;
    }
    _navigate(message);
  }

  bool _claim(PushEnvelope message) {
    final id = message.id.trim().isNotEmpty
        ? message.id.trim()
        : message.data['notificationId']?.toString().trim() ?? '';
    if (id.isEmpty) return true;
    if (!_handledMessageIds.add(id)) return false;
    if (_handledMessageIds.length > 100) {
      _handledMessageIds.remove(_handledMessageIds.first);
    }
    return true;
  }

  void _navigate(PushEnvelope message) =>
      _navigateTo(NotificationDeepLink.resolve(message.data));

  void _navigateTo(NotificationDestination destination) {
    if (AuthService.instance.currentUser == null) return;
    AmoraTopNotificationManager.navigatorKey.currentState?.pushNamed(
      destination.route,
      arguments: destination.arguments,
    );
  }

  Future<String> _loadInstallationId() async {
    try {
      final current = await _storage.read(key: _installationKey);
      if (current != null && current.isNotEmpty) return current;
      final random = Random.secure();
      final value = List<int>.generate(
        24,
        (_) => random.nextInt(256),
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      await _storage.write(key: _installationKey, value: value);
      return value;
    } on MissingPluginException {
      return 'amora-${DateTime.now().microsecondsSinceEpoch}';
    } on PlatformException {
      return 'amora-${DateTime.now().microsecondsSinceEpoch}';
    }
  }

  bool get _supportsPush =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
}

class _FirebasePushMessagingGateway implements PushMessagingGateway {
  _FirebasePushMessagingGateway() : _messaging = FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<PushAuthorizationState> authorizationState() async => _authorization(
    (await _messaging.getNotificationSettings()).authorizationStatus,
  );

  @override
  Future<PushAuthorizationState> requestPermission() async => _authorization(
    (await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    )).authorizationStatus,
  );

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<PushEnvelope> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_envelope);

  @override
  Stream<PushEnvelope> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_envelope);

  @override
  Future<PushEnvelope?> initialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _envelope(message);
  }

  static PushAuthorizationState _authorization(AuthorizationStatus status) =>
      switch (status) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushAuthorizationState.granted,
        AuthorizationStatus.notDetermined =>
          PushAuthorizationState.notDetermined,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PushAuthorizationState.denied,
      };

  static PushEnvelope _envelope(RemoteMessage message) => PushEnvelope(
    id: message.messageId ?? '',
    title: message.notification?.title ?? 'AMORAA',
    body: message.notification?.body ?? 'You have a new notification.',
    data: Map<String, dynamic>.from(message.data),
  );
}

AmoraTopNotificationType _presentationType(Map<String, dynamic> data) {
  return switch (data['type']?.toString()) {
    'new_message' => AmoraTopNotificationType.message,
    'new_match' => AmoraTopNotificationType.match,
    'new_like' => AmoraTopNotificationType.like,
    'new_super_like' => AmoraTopNotificationType.superLike,
    _ => AmoraTopNotificationType.system,
  };
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // The operating system still presents notification payloads. Application
    // startup remains safe when native Firebase configuration is unavailable.
  }
}
