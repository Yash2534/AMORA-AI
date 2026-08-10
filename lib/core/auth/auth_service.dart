import 'dart:convert';

import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;
}

class AmoraUser {
  const AmoraUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.isVerified,
    this.accountStatus = 'active',
  });

  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final bool isVerified;
  final String accountStatus;

  factory AmoraUser.fromJson(Map<String, dynamic> json) => AmoraUser(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    isVerified: json['isVerified'] as bool? ?? false,
    accountStatus: json['accountStatus'] as String? ?? 'active',
  );
}

/// Authentication client. Configure a deployed API with
/// `--dart-define=AMORA_API_BASE_URL=https://api.example.com`.
class AuthService {
  AuthService._();

  static final instance = AuthService._();
  static const _accessKey = 'amora_access_token';
  static const _refreshKey = 'amora_refresh_token';
  static const _storage = FlutterSecureStorage();

  final http.Client _client = http.Client();
  String? _accessToken;
  String? _refreshToken;
  AmoraUser? currentUser;

  Future<void> initialize() async {
    _accessToken = await _storage.read(key: _accessKey);
    _refreshToken = await _storage.read(key: _refreshKey);
  }

  Future<bool> restoreSession() async {
    if (_accessToken == null || _refreshToken == null) return false;
    try {
      currentUser = await me();
      return true;
    } on AuthException {
      await clearSession();
      return false;
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
  }) async {
    await _post('/api/auth/signup', {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'confirmPassword': confirmPassword,
      'acceptedTerms': true,
    });
  }

  Future<void> resendVerification(String phoneNumber) async =>
      _post('/api/auth/resend-verification-code', {'phoneNumber': phoneNumber});

  Future<AmoraUser> verifyAccount(String phoneNumber, String code) async {
    final response = await _post('/api/auth/verify-account', {
      'phoneNumber': phoneNumber,
      'code': code,
    });
    return _saveAuthentication(response);
  }

  Future<AmoraUser> login(String email, String password) async {
    final response = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return _saveAuthentication(response, reactivateIfRequired: true);
  }

  Future<AmoraUser> googleSignIn() async {
    final account = await GoogleSignIn(scopes: const ['email']).signIn();
    if (account == null) {
      throw const AuthException('Google sign-in was cancelled.');
    }
    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) {
      throw const AuthException(
        'Google did not return an ID token. Check the app OAuth configuration.',
      );
    }
    final response = await _post('/api/auth/google', {'idToken': idToken});
    return _saveAuthentication(response, reactivateIfRequired: true);
  }

  Future<void> forgotPassword(String phoneNumber) async =>
      _post('/api/auth/forgot-password', {'phoneNumber': phoneNumber});

  Future<String> verifyResetCode(String phoneNumber, String code) async {
    final response = await _post('/api/auth/verify-reset-code', {
      'phoneNumber': phoneNumber,
      'code': code,
    });
    return _data(response)['recoveryToken'] as String;
  }

  Future<void> resetPassword(
    String phoneNumber,
    String recoveryToken,
    String newPassword,
  ) async => _post('/api/auth/reset-password', {
    'phoneNumber': phoneNumber,
    'recoveryToken': recoveryToken,
    'newPassword': newPassword,
  });

  Future<AmoraUser> me() async {
    final response = await _request('GET', '/api/auth/me', authenticated: true);
    return AmoraUser.fromJson(_data(response)['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null && _refreshToken != null) {
        await _post('/api/auth/logout', {
          'refreshToken': _refreshToken,
        }, authenticated: true);
      }
    } on AuthException {
      // Local token removal is still required if the network is unavailable.
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    currentUser = null;
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } on MissingPluginException {
      // The secure-storage platform channel is absent in widget tests.
    }
  }

  Future<AmoraUser> _saveAuthentication(
    Map<String, dynamic> response, {
    bool reactivateIfRequired = false,
  }) async {
    final data = _data(response);
    _accessToken = data['accessToken'] as String;
    _refreshToken = data['refreshToken'] as String;
    await _storage.write(key: _accessKey, value: _accessToken);
    await _storage.write(key: _refreshKey, value: _refreshToken);
    currentUser = AmoraUser.fromJson(data['user'] as Map<String, dynamic>);
    if (reactivateIfRequired && data['requiresReactivation'] == true) {
      try {
        final reactivated = await authenticatedRequest(
          'POST',
          '/api/account/reactivate',
        );
        currentUser = AmoraUser.fromJson(
          _data(reactivated)['user'] as Map<String, dynamic>,
        );
      } catch (_) {
        await clearSession();
        rethrow;
      }
    }
    return currentUser!;
  }

  Future<Map<String, dynamic>> authenticatedRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => _request(method, path, body: body, authenticated: true);

  Future<Uint8List> authenticatedBytes(
    String path, {
    bool retried = false,
  }) async {
    final request = http.Request(
      'GET',
      Uri.parse('${AmoraApiConfig.baseUrl}$path'),
    )..headers['Accept'] = 'image/*';
    if (_accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }
    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      );
      if (response.statusCode == 401 &&
          !retried &&
          _refreshToken != null &&
          await _refresh()) {
        return authenticatedBytes(path, retried: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          'Media is unavailable.',
          statusCode: response.statusCode,
        );
      }
      return response.bodyBytes;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Unable to load this media.');
    }
  }

  Future<Map<String, dynamic>> authenticatedMultipart(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    required String mimeType,
    Map<String, String> fields = const {},
    bool retried = false,
  }) async {
    final uri = Uri.parse('${AmoraApiConfig.baseUrl}$path');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json';
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      request.fields.addAll(fields);
      request.files.add(
        http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 401 &&
          !retried &&
          _refreshToken != null &&
          await _refresh()) {
        return authenticatedMultipart(
          path,
          field: field,
          bytes: bytes,
          filename: filename,
          mimeType: mimeType,
          fields: fields,
          retried: true,
        );
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw AuthException(
          decoded['message'] as String? ?? 'The upload could not be completed.',
          code: decoded['code'] as String?,
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to reach the service. Check your connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) => _request('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    bool retried = false,
  }) async {
    final uri = Uri.parse('${AmoraApiConfig.baseUrl}$path');
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authenticated && _accessToken != null) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 401 &&
          authenticated &&
          !retried &&
          _refreshToken != null &&
          await _refresh()) {
        return _request(
          method,
          path,
          body: body,
          authenticated: authenticated,
          retried: true,
        );
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw AuthException(
          decoded['message'] as String? ??
              'The request could not be completed.',
          code: decoded['code'] as String?,
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Unable to reach the service. Check your connection and try again.',
      );
    }
  }

  Future<bool> _refresh() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _request(
        'POST',
        '/api/auth/refresh-token',
        body: {'refreshToken': _refreshToken},
        retried: true,
      );
      final data = _data(response);
      _accessToken = data['accessToken'] as String;
      _refreshToken = data['refreshToken'] as String;
      await _storage.write(key: _accessKey, value: _accessToken);
      await _storage.write(key: _refreshKey, value: _refreshToken);
      return true;
    } on AuthException {
      return false;
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      (response['data'] as Map?)?.cast<String, dynamic>() ??
      <String, dynamic>{};
}
