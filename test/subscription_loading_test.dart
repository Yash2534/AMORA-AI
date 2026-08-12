import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SubscriptionRemote implements MonetizationRemoteDataSource {
  _SubscriptionRemote(this.handler);

  final Future<Map<String, dynamic>> Function(String path) handler;
  final calls = <String>[];

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    calls.add('$method $path');
    return handler(path);
  }
}

Map<String, dynamic> _ok(Map<String, dynamic> data) => {
  'success': true,
  'data': data,
};

final _plan = <String, dynamic>{
  'id': 'amoraa_gold_monthly',
  'name': 'AMORAA Gold',
  'displayName': 'AMORAA Gold Monthly',
  'description': 'Premium visibility for intentional conversations.',
  'priceMinor': 199900,
  'currency': 'INR',
  'billingPeriod': 'month',
  'billingInterval': 1,
  'features': ['Priority profiles', 'Read receipts'],
  'entitlements': {'premium': true},
  'active': true,
  'sortOrder': 20,
};

Map<String, dynamic> _none() => {
  'status': 'none',
  'premium': false,
  'plan': null,
  'autoRenew': false,
  'cancelAtPeriodEnd': false,
  'entitlements': <String, dynamic>{},
};

void main() {
  tearDown(() {
    MonetizationRepository.debugOverride?.dispose();
    MonetizationRepository.debugOverride = null;
  });

  Future<_SubscriptionRemote> pump(
    WidgetTester tester,
    Future<Map<String, dynamic>> Function(String path) handler,
  ) async {
    final remote = _SubscriptionRemote(handler);
    MonetizationRepository.debugOverride = MonetizationRepository(
      remote: remote,
    );
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const SubscriptionScreen()),
    );
    await tester.pumpAndSettle();
    return remote;
  }

  testWidgets('plans and no-membership state render from API data', (
    tester,
  ) async {
    final remote = await pump(tester, (path) async {
      if (path.endsWith('/plans')) {
        return _ok({
          'plans': [_plan],
        });
      }
      return _ok({'membership': _none()});
    });

    expect(find.text('AMORAA Gold'), findsWidgets);
    expect(find.text('Priority profiles'), findsOneWidget);
    expect(find.textContaining('1,999'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(remote.calls, [
      'GET /api/subscriptions/plans',
      'GET /api/subscriptions/me',
    ]);
  });

  testWidgets('zero active plans reaches a truthful empty state', (
    tester,
  ) async {
    await pump(tester, (path) async {
      if (path.endsWith('/plans')) return _ok({'plans': []});
      return _ok({'membership': _none()});
    });

    expect(
      find.text('No membership plans are currently available.'),
      findsOneWidget,
    );
    expect(find.text('No plans available'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('membership authentication error is safe and retryable', (
    tester,
  ) async {
    await pump(tester, (path) async {
      if (path.endsWith('/plans')) {
        return _ok({
          'plans': [_plan],
        });
      }
      throw const AuthException(
        'Invalid access token.',
        code: 'TOKEN_INVALID',
        statusCode: 401,
      );
    });

    expect(find.text('Membership could not be loaded.'), findsOneWidget);
    expect(
      find.text('Your session has expired. Please log in again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining("Instance of 'AuthException'"), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('active membership uses its associated persisted plan', (
    tester,
  ) async {
    await pump(tester, (path) async {
      if (path.endsWith('/plans')) {
        return _ok({
          'plans': [_plan],
        });
      }
      return _ok({
        'membership': {
          'id': '14',
          'planId': 'amoraa_gold_monthly',
          'status': 'active',
          'premium': true,
          'plan': _plan,
          'startedAt': '2026-08-01T00:00:00.000Z',
          'currentPeriodEnd': '2026-09-01T00:00:00.000Z',
          'autoRenew': true,
          'cancelAtPeriodEnd': false,
          'entitlements': {'premium': true},
        },
      });
    });

    expect(find.text('Membership active'), findsOneWidget);
    expect(find.text('AMORAA Gold'), findsWidgets);
    expect(find.text('Choose your membership'), findsNothing);
  });
}
