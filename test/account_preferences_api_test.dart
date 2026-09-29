import 'dart:convert';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'production Discover path uses the refresh-capable authenticated client',
    () async {
      String? capturedMethod;
      String? capturedPath;
      Map<String, dynamic>? capturedBody;
      final service = DiscoverApiService(
        authenticatedRequester: (method, path, {body}) async {
          capturedMethod = method;
          capturedPath = path;
          capturedBody = body;
          return {
            'success': true,
            'message': 'Saved.',
            'data': {'preferences': body},
          };
        },
      );

      final result = await service.updateFilters({'minAge': 25, 'maxAge': 35});

      expect(result.success, isTrue);
      expect(capturedMethod, 'PUT');
      expect(capturedPath, '/api/me/preferences');
      expect(capturedBody, {'minAge': 25, 'maxAge': 35});
    },
  );

  test('authenticated Discover errors remain real failures', () async {
    final service = DiscoverApiService(
      authenticatedRequester: (_, _, {body}) async => throw const AuthException(
        'Your session has expired.',
        code: 'TOKEN_EXPIRED',
        statusCode: 401,
      ),
    );

    final result = await service.getFeed();

    expect(result.success, isFalse);
    expect(result.statusCode, 401);
    expect(result.data, isNull);
  });

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

  test(
    'current location is uploaded only to the authenticated self endpoint',
    () async {
      String? capturedMethod;
      String? capturedPath;
      Map<String, dynamic>? capturedBody;
      final service = DiscoverApiService(
        authenticatedRequester: (method, path, {body}) async {
          capturedMethod = method;
          capturedPath = path;
          capturedBody = body;
          return {
            'success': true,
            'data': {
              'location': {'locationAvailable': true},
            },
          };
        },
      );
      final result = await service.updateLocation(
        latitude: 23.0225,
        longitude: 72.5714,
      );
      expect(result.success, isTrue);
      expect(capturedMethod, 'PUT');
      expect(capturedPath, '/api/me/location');
      expect(capturedBody, {'latitude': 23.0225, 'longitude': 72.5714});
    },
  );

  test(
    'near-you query is explicit and retains server location metadata',
    () async {
      String? capturedPath;
      final service = DiscoverApiService(
        authenticatedRequester: (_, path, {body}) async {
          capturedPath = path;
          return {
            'success': true,
            'data': {
              'profiles': <dynamic>[],
              'locationMatching': {
                'viewerLocationAvailable': true,
                'distanceFilterActive': true,
              },
              'pagination': {'hasMore': false},
            },
          };
        },
      );
      final result = await service.getFeed(surface: 'near_you');
      expect(capturedPath, contains('surface=near_you'));
      expect(result.data?.viewerLocationAvailable, isTrue);
      expect(result.data?.distanceFilterActive, isTrue);
    },
  );
}
