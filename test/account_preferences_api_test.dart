import 'dart:convert';

import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads account preferences with bearer authentication', () async {
    late http.Request captured;
    final service = DiscoverApiService(
      accessTokenProvider: () async => 'preference-token',
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'preferences': {'minAge': 24, 'maxAge': 36, 'maxDistanceKm': 50},
            },
          }),
          200,
        );
      }),
    );

    final result = await service.getFilters();

    expect(result.success, isTrue);
    expect(result.data?['minAge'], 24);
    expect(captured.method, 'GET');
    expect(captured.url.path, '/api/me/preferences');
    expect(captured.headers['authorization'], 'Bearer preference-token');
  });

  test('saves only through the canonical account preferences API', () async {
    late http.Request captured;
    final service = DiscoverApiService(
      accessTokenProvider: () async => 'preference-token',
      client: MockClient((request) async {
        captured = request;
        final submitted = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'preferences': submitted},
          }),
          200,
        );
      }),
    );

    final result = await service.updateFilters({
      'minAge': 27,
      'maxAge': 42,
      'verifiedOnly': true,
    });

    expect(result.success, isTrue);
    expect(result.data?['verifiedOnly'], isTrue);
    expect(captured.method, 'PUT');
    expect(captured.url.path, '/api/me/preferences');
    expect(captured.headers['authorization'], 'Bearer preference-token');
    expect(jsonDecode(captured.body), {
      'minAge': 27,
      'maxAge': 42,
      'verifiedOnly': true,
    });
  });

  test('preference failure cannot become local success', () async {
    final service = DiscoverApiService(
      accessTokenProvider: () async => 'preference-token',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'message': 'minAge cannot be greater than maxAge.',
          }),
          422,
        ),
      ),
    );

    final result = await service.updateFilters({'minAge': 50, 'maxAge': 20});

    expect(result.success, isFalse);
    expect(result.statusCode, 422);
    expect(result.data, isNull);
  });

  test('missing session prevents account preference request', () async {
    var requested = false;
    final service = DiscoverApiService(
      accessTokenProvider: () async => null,
      client: MockClient((_) async {
        requested = true;
        return http.Response('{}', 200);
      }),
    );

    final result = await service.getFilters();

    expect(result.success, isFalse);
    expect(result.statusCode, 401);
    expect(requested, isFalse);
  });
}
