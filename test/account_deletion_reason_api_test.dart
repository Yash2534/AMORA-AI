import 'dart:convert';

import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('account deletion confirmation sends nullable reason fields', () async {
    late http.Request captured;
    final auth = AuthService.forTesting(
      storage: _MemoryCredentialStorage.withTokens(),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Your account has been deleted.',
            'data': {'deleted': true},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await auth.initialize();
    final service = PhaseTwoApiService(auth: auth);

    await service.confirmAccountDeletion(
      channel: 'EMAIL',
      otp: '123456',
      reasonCode: 'OTHER',
      reasonText: 'A custom reason',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/account/delete/confirm');
    expect(captured.headers['authorization'], 'Bearer access-token');
    expect(jsonDecode(captured.body), {
      'channel': 'EMAIL',
      'otp': '123456',
      'reasonCode': 'OTHER',
      'reasonText': 'A custom reason',
    });
  });

  test(
    'account deletion confirmation preserves no-reason compatibility',
    () async {
      late Map<String, dynamic> submitted;
      final auth = AuthService.forTesting(
        storage: _MemoryCredentialStorage.withTokens(),
        client: MockClient((request) async {
          submitted = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'deleted': true},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      await auth.initialize();

      await PhaseTwoApiService(
        auth: auth,
      ).confirmAccountDeletion(channel: 'PHONE', otp: '654321');

      expect(submitted['reasonCode'], isNull);
      expect(submitted['reasonText'], isNull);
    },
  );
}

class _MemoryCredentialStorage implements AuthCredentialStorage {
  _MemoryCredentialStorage(this.values);

  factory _MemoryCredentialStorage.withTokens() => _MemoryCredentialStorage({
    'amora_access_token': 'access-token',
    'amora_refresh_token': 'refresh-token',
  });

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
