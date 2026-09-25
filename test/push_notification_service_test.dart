import 'dart:async';

import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/notifications/data/notification_deep_link.dart';
import 'package:amora_ai/features/notifications/data/push_notification_service.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

class _Gateway implements PushMessagingGateway {
  PushAuthorizationState authorization = PushAuthorizationState.granted;
  String? currentToken = 'device-token-12345678901234567890';
  int permissionRequests = 0;
  final refreshes = StreamController<String>.broadcast();
  final foreground = StreamController<PushEnvelope>.broadcast();
  final opened = StreamController<PushEnvelope>.broadcast();

  @override
  Future<PushAuthorizationState> authorizationState() async => authorization;
  @override
  Future<PushAuthorizationState> requestPermission() async {
    permissionRequests++;
    return authorization = PushAuthorizationState.granted;
  }

  @override
  Future<String?> token() async => currentToken;
  @override
  Stream<String> get tokenRefreshes => refreshes.stream;
  @override
  Stream<PushEnvelope> get foregroundMessages => foreground.stream;
  @override
  Stream<PushEnvelope> get openedMessages => opened.stream;
  @override
  Future<PushEnvelope?> initialMessage() async => null;
}

class _Registrar implements PushTokenRegistrar {
  _Registrar(this.userId);
  final String? Function() userId;
  final List<String> registrations = [];
  final List<String> removals = [];

  @override
  Future<bool> registerPushToken(
    String token, {
    String? platform,
    String? installationId,
  }) async {
    registrations.add('${userId()}:$token:$platform:$installationId');
    return true;
  }

  @override
  Future<bool> unregisterPushToken(String token) async {
    removals.add('${userId()}:$token');
    return true;
  }
}

void main() {
  test('registers only authenticated users and is idempotent', () async {
    String? userId;
    final gateway = _Gateway();
    final registrar = _Registrar(() => userId);
    final coordinator = PushTokenCoordinator(
      gateway: gateway,
      registrar: registrar,
      authenticatedUserId: () => userId,
      platform: 'android',
      installationId: () async => 'installation-1',
    );
    addTearDown(coordinator.dispose);

    expect(await coordinator.sync(), isFalse);
    expect(registrar.registrations, isEmpty);
    userId = '1';
    expect(await coordinator.sync(), isTrue);
    expect(await coordinator.sync(), isTrue);
    expect(registrar.registrations, hasLength(1));
  });

  test(
    'token refresh registers the replacement and removes the stale token',
    () async {
      String? userId = '1';
      final gateway = _Gateway();
      final registrar = _Registrar(() => userId);
      final coordinator = PushTokenCoordinator(
        gateway: gateway,
        registrar: registrar,
        authenticatedUserId: () => userId,
        platform: 'ios',
        installationId: () async => 'installation-1',
      );
      addTearDown(coordinator.dispose);
      await coordinator.sync();

      gateway.refreshes.add('replacement-token-12345678901234567890');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(registrar.registrations, hasLength(2));
      expect(
        registrar.removals,
        contains('1:device-token-12345678901234567890'),
      );
    },
  );

  test(
    'logout unregisters and a subsequent user owns the current token',
    () async {
      String? userId = '1';
      final gateway = _Gateway();
      final registrar = _Registrar(() => userId);
      final coordinator = PushTokenCoordinator(
        gateway: gateway,
        registrar: registrar,
        authenticatedUserId: () => userId,
        platform: 'android',
        installationId: () async => 'installation-1',
      );
      addTearDown(coordinator.dispose);
      await coordinator.sync();
      await coordinator.unregister();
      userId = '2';
      await coordinator.sync();

      expect(registrar.removals.single, contains('1:'));
      expect(registrar.registrations.last, startsWith('2:'));
    },
  );

  test('a denied permission is not requested repeatedly', () async {
    final gateway = _Gateway()..authorization = PushAuthorizationState.denied;
    final registrar = _Registrar(() => '1');
    final coordinator = PushTokenCoordinator(
      gateway: gateway,
      registrar: registrar,
      authenticatedUserId: () => '1',
      platform: 'android',
      installationId: () async => 'installation-1',
    );
    addTearDown(coordinator.dispose);

    expect(await coordinator.sync(), isFalse);
    expect(await coordinator.sync(), isFalse);
    expect(gateway.permissionRequests, 0);
  });

  test(
    'notification destinations are allowlisted and validate identifiers',
    () {
      final chat = NotificationDeepLink.resolve({
        'type': 'new_message',
        'conversationId': '42',
        'targetUserId': '9',
      });
      expect(chat.route, ChatDetailScreen.routeName);
      expect((chat.arguments! as ChatDetailArgs).conversationId, '42');

      expect(
        NotificationDeepLink.resolve({'type': 'new_match'}).route,
        MatchesScreen.routeName,
      );
      expect(
        NotificationDeepLink.resolve({
          'type': 'new_like',
          'targetUserId': '7',
        }).route,
        ProfileDetailScreen.routeName,
      );
      expect(
        NotificationDeepLink.resolve({
          'route': '/admin',
          'type': 'new_message',
          'conversationId': '../42',
        }).route,
        NotificationsHubScreen.routeName,
      );
    },
  );
}
