import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/monetization/presentation/profile_boost_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _BoostRemote implements MonetizationRemoteDataSource {
  int stateCalls = 0;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (path == '/api/boosts/products') {
      return {
        'success': true,
        'data': {
          'products': [
            {
              'id': 'boost_starter_30',
              'name': 'Starter Boost',
              'quantity': 1,
              'durationMinutes': 30,
              'priceMinor': 29900,
              'walletCost': 299,
              'currency': 'INR',
            },
          ],
        },
      };
    }
    if (path == '/api/boosts/me') {
      stateCalls++;
      return {
        'success': true,
        'data': {
          'boost': {
            'available': stateCalls == 1 ? 1 : 0,
            'active': stateCalls == 1
                ? null
                : {
                    'startedAt': DateTime.now().toUtc().toIso8601String(),
                    'expiresAt': DateTime.now()
                        .add(const Duration(minutes: 30))
                        .toUtc()
                        .toIso8601String(),
                    'remainingSeconds': 1800,
                  },
          },
        },
      };
    }
    throw StateError('Unexpected request: $method $path');
  }
}

class _BoostApi extends DiscoverApiService {
  bool failNext = false;
  final keys = <String>[];

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> boost(String key) async {
    keys.add(key);
    if (failNext) {
      failNext = false;
      return const DiscoverApiResult.failure(
        'Unable to reach Discover right now.',
        statusCode: 0,
      );
    }
    return DiscoverApiResult.success({
      'active': true,
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 30))
          .toUtc()
          .toIso8601String(),
      'remainingSeconds': 1800,
    }, statusCode: 200);
  }
}

void main() {
  late _BoostRemote remote;
  late _BoostApi api;

  setUp(() {
    remote = _BoostRemote();
    api = _BoostApi();
    MonetizationRepository.debugOverride = MonetizationRepository(
      remote: remote,
    );
  });

  tearDown(() {
    MonetizationRepository.debugOverride?.dispose();
    MonetizationRepository.debugOverride = null;
  });

  testWidgets('backend-confirmed Boost response updates the visible state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ProfileBoostScreen(discoverApiService: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Activate Boost'), findsOneWidget);
    await tester.tap(find.text('Activate Boost'));
    await tester.pumpAndSettle();

    expect(api.keys, hasLength(1));
    expect(remote.stateCalls, 2);
    expect(find.text('Boost is live in nearby discovery.'), findsOneWidget);
    expect(find.text('Boost Active'), findsOneWidget);
  });

  testWidgets('network retry reuses its key and never shows fake success', (
    tester,
  ) async {
    api.failNext = true;
    await tester.pumpWidget(
      MaterialApp(home: ProfileBoostScreen(discoverApiService: api)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Activate Boost'));
    await tester.pumpAndSettle();
    expect(find.text('Boost is live in nearby discovery.'), findsNothing);
    expect(remote.stateCalls, 1);

    await tester.tap(find.text('Activate Boost'));
    await tester.pumpAndSettle();

    expect(api.keys, hasLength(2));
    expect(api.keys[1], api.keys[0]);
    expect(find.text('Boost is live in nearby discovery.'), findsOneWidget);
  });
}
