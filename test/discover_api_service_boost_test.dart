import 'dart:convert';

import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'boost sends bearer authentication and Idempotency-Key header',
    () async {
      late http.Request captured;
      final service = DiscoverApiService(
        accessTokenProvider: () async => 'test-access-token',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Boost activated.',
              'data': {
                'active': true,
                'startedAt': '2026-08-11T10:00:00.000Z',
                'expiresAt': '2026-08-11T10:30:00.000Z',
                'remainingSeconds': 1800,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final result = await service.boost('flutter:boost:test-key-0001');

      expect(result.success, isTrue);
      expect(result.data?['active'], isTrue);
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/discover/boost');
      expect(captured.headers['authorization'], 'Bearer test-access-token');
      expect(
        captured.headers['idempotency-key'],
        'flutter:boost:test-key-0001',
      );
      expect(captured.body, isEmpty);
    },
  );

  test('boost exposes backend validation and entitlement failures', () async {
    var response = http.Response(
      jsonEncode({
        'success': false,
        'message': 'A valid Idempotency-Key is required.',
        'code': 'IDEMPOTENCY_KEY_REQUIRED',
        'errors': <dynamic>[],
      }),
      400,
    );
    final service = DiscoverApiService(
      accessTokenProvider: () async => 'test-access-token',
      client: MockClient((_) async => response),
    );

    final invalid = await service.boost('short');
    expect(invalid.success, isFalse);
    expect(invalid.statusCode, 400);
    expect(invalid.message, contains('Idempotency-Key'));

    response = http.Response(
      jsonEncode({
        'success': false,
        'message': 'A boost entitlement is required.',
        'code': 'BOOST_ENTITLEMENT_REQUIRED',
        'errors': <dynamic>[],
      }),
      402,
    );
    final noEntitlement = await service.boost('flutter:boost:test-key-0002');
    expect(noEntitlement.success, isFalse);
    expect(noEntitlement.statusCode, 402);
    expect(noEntitlement.message, contains('entitlement'));
  });

  test('network failure cannot produce a local boost success', () async {
    final service = DiscoverApiService(
      accessTokenProvider: () async => 'test-access-token',
      client: MockClient((_) async => throw Exception('offline')),
    );

    final result = await service.boost('flutter:boost:test-key-0003');

    expect(result.success, isFalse);
    expect(result.statusCode, 0);
    expect(result.data, isNull);
  });

  test('generated keys are valid and unique for new attempts', () {
    final service = DiscoverApiService(accessTokenProvider: () async => null);

    final first = service.newIdempotencyKey('boost-activation');
    final second = service.newIdempotencyKey('boost-activation');

    expect(first, isNot(second));
    expect(first, matches(RegExp(r'^[A-Za-z0-9._:-]{8,100}$')));
    expect(second, matches(RegExp(r'^[A-Za-z0-9._:-]{8,100}$')));
  });
}
