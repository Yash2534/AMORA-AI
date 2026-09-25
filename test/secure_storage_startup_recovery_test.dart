import 'dart:convert';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/storage/amora_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthService secure-storage startup recovery', () {
    test('valid stored credentials restore normally', () async {
      final storage = _FakeCredentialStorage.withTokens();
      var authenticatedRequestSeen = false;
      final service = AuthService.forTesting(
        storage: storage,
        client: MockClient((request) async {
          authenticatedRequestSeen =
              request.headers['Authorization'] == 'Bearer access-token';
          return _userResponse();
        }),
      );

      await service.initialize();

      expect(await service.restoreSession(), isTrue);
      expect(authenticatedRequestSeen, isTrue);
      expect(service.currentUser?.id, 7);
    });

    test('no stored credentials starts signed out', () async {
      final service = AuthService.forTesting(storage: _FakeCredentialStorage());

      await service.initialize();

      expect(await service.restoreSession(), isFalse);
      expect(service.currentUser, isNull);
    });

    test('BAD_DECRYPT read failure recovers signed out', () async {
      final storage = _FakeCredentialStorage(
        readError: PlatformException(
          code: 'Exception encountered',
          message: 'read',
          details:
              'javax.crypto.BadPaddingException: '
              'OPENSSL_internal:BAD_DECRYPT',
        ),
      );
      final service = AuthService.forTesting(storage: storage);

      await expectLater(service.initialize(), completes);

      expect(await service.restoreSession(), isFalse);
      expect(
        storage.deletedKeys,
        containsAll(<String>['amora_access_token', 'amora_refresh_token']),
      );
    });

    test(
      'failed key unwrap and InvalidKeyException recover signed out',
      () async {
        final service = AuthService.forTesting(
          storage: _FakeCredentialStorage(
            readError: PlatformException(
              code: 'Exception encountered',
              message: 'read',
              details:
                  'StorageCipher18Impl: unwrap key failed; '
                  'java.security.InvalidKeyException: Failed to unwrap key',
            ),
          ),
        );

        await expectLater(service.initialize(), completes);

        expect(await service.restoreSession(), isFalse);
      },
    );

    test('a partial/corrupt credential pair is never reused', () async {
      final storage = _FakeCredentialStorage(
        values: <String, String>{'amora_access_token': 'stale-access'},
      );
      var requests = 0;
      final service = AuthService.forTesting(
        storage: storage,
        client: MockClient((request) async {
          requests++;
          return _userResponse();
        }),
      );

      await service.initialize();

      expect(await service.restoreSession(), isFalse);
      expect(requests, 0);
      expect(storage.values, isEmpty);
    });

    test('unrelated PlatformException is not treated as corruption', () async {
      final service = AuthService.forTesting(
        storage: _FakeCredentialStorage(
          readError: PlatformException(
            code: 'permission_denied',
            message: 'The operation is not permitted.',
          ),
        ),
      );

      await expectLater(
        service.initialize(),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'permission_denied',
          ),
        ),
      );
    });

    test('normal logout still clears both credentials', () async {
      final storage = _FakeCredentialStorage.withTokens();
      final service = AuthService.forTesting(
        storage: storage,
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(<String, Object?>{
              'success': true,
              'data': <String, Object?>{},
            }),
            200,
          ),
        ),
      );
      await service.initialize();

      await service.logout();

      expect(storage.values, isEmpty);
      expect(await service.restoreSession(), isFalse);
    });

    test(
      'delete failure during confirmed corruption does not loop or crash',
      () async {
        final service = AuthService.forTesting(
          storage: _FakeCredentialStorage(
            readError: PlatformException(
              code: 'read_failed',
              details: 'OPENSSL_internal:BAD_DECRYPT',
            ),
            deleteError: PlatformException(
              code: 'delete_failed',
              details: 'Failed to unwrap key',
            ),
          ),
        );

        await expectLater(service.initialize(), completes);

        expect(await service.restoreSession(), isFalse);
      },
    );

    test('authoritative Android storage enables package resetOnError', () {
      expect(
        AmoraSecureStorage.instance.aOptions.toMap()['resetOnError'],
        'true',
      );
    });
  });
}

http.Response _userResponse() => http.Response(
  jsonEncode(<String, Object?>{
    'success': true,
    'data': <String, Object?>{
      'user': <String, Object?>{
        'id': 7,
        'name': 'Storage Test User',
        'email': 'storage-test@example.invalid',
        'phoneNumber': '',
        'isVerified': true,
        'accountStatus': 'active',
        'authProvider': 'local',
      },
    },
  }),
  200,
);

class _FakeCredentialStorage implements AuthCredentialStorage {
  _FakeCredentialStorage({
    Map<String, String>? values,
    this.readError,
    this.deleteError,
  }) : values = values ?? <String, String>{};

  factory _FakeCredentialStorage.withTokens() => _FakeCredentialStorage(
    values: <String, String>{
      'amora_access_token': 'access-token',
      'amora_refresh_token': 'refresh-token',
    },
  );

  final Map<String, String> values;
  final Object? readError;
  final Object? deleteError;
  final List<String> deletedKeys = <String>[];

  @override
  Future<String?> read(String key) async {
    final error = readError;
    if (error != null) throw error;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletedKeys.add(key);
    final error = deleteError;
    if (error != null) throw error;
    values.remove(key);
  }
}
