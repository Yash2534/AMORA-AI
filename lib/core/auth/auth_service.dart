import 'dart:convert';

import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  const AuthException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;
}

class AmoraUser {
  const AmoraUser({required this.id, required this.name, required this.email, required this.phoneNumber, required this.isVerified});

  final int id;
  final String name;
  final String email;
  final String phoneNumber;
  final bool isVerified;

  factory AmoraUser.fromJson(Map<String, dynamic> json) => AmoraUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        isVerified: json['isVerified'] as bool? ?? false,
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

  Future<void> signUp({required String name, required String email, required String phoneNumber, required String password, required String confirmPassword}) async {
    await _post('/api/auth/signup', {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
      'confirmPassword': confirmPassword,
      'acceptedTerms': true,
    });
  }

  Future<void> resendVerification(String email) async => _post('/api/auth/resend-verification-code', {'email': email});

  Future<AmoraUser> verifyAccount(String email, String code) async {
    final response = await _post('/api/auth/verify-account', {'email': email, 'code': code});
    return _saveAuthentication(response);
  }

  Future<AmoraUser> login(String email, String password) async {
    final response = await _post('/api/auth/login', {'email': email, 'password': password});
    return _saveAuthentication(response);
  }

  Future<AmoraUser> googleSignIn() async {
    final account = await GoogleSignIn(scopes: const ['email']).signIn();
    if (account == null) throw const AuthException('Google sign-in was cancelled.');
    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null) throw const AuthException('Google did not return an ID token. Check the app OAuth configuration.');
    final response = await _post('/api/auth/google', {'idToken': idToken});
    return _saveAuthentication(response);
  }

  Future<void> forgotPassword(String email) async => _post('/api/auth/forgot-password', {'email': email});

  Future<String> verifyResetCode(String email, String code) async {
    final response = await _post('/api/auth/verify-reset-code', {'email': email, 'code': code});
    return _data(response)['recoveryToken'] as String;
  }

  Future<void> resetPassword(String email, String recoveryToken, String newPassword) async => _post('/api/auth/reset-password', {'email': email, 'recoveryToken': recoveryToken, 'newPassword': newPassword});

  Future<AmoraUser> me() async {
    final response = await _request('GET', '/api/auth/me', authenticated: true);
    return AmoraUser.fromJson(_data(response)['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null && _refreshToken != null) await _post('/api/auth/logout', {'refreshToken': _refreshToken}, authenticated: true);
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
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  Future<AmoraUser> _saveAuthentication(Map<String, dynamic> response) async {
    final data = _data(response);
    _accessToken = data['accessToken'] as String;
    _refreshToken = data['refreshToken'] as String;
    await _storage.write(key: _accessKey, value: _accessToken);
    await _storage.write(key: _refreshKey, value: _refreshToken);
    currentUser = AmoraUser.fromJson(data['user'] as Map<String, dynamic>);
    return currentUser!;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {bool authenticated = false}) => _request('POST', path, body: body, authenticated: authenticated);

  Future<Map<String, dynamic>> _request(String method, String path, {Map<String, dynamic>? body, bool authenticated = false, bool retried = false}) async {
    final uri = Uri.parse('${AmoraApiConfig.baseUrl}$path');
    try {
      final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
      if (authenticated && _accessToken != null) headers['Authorization'] = 'Bearer $_accessToken';
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 401 && authenticated && !retried && _refreshToken != null && await _refresh()) {
        return _request(method, path, body: body, authenticated: authenticated, retried: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300 || decoded['success'] != true) {
        throw AuthException(decoded['message'] as String? ?? 'The request could not be completed.', code: decoded['code'] as String?, statusCode: response.statusCode);
      }
      return decoded;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Unable to reach the service. Check your connection and try again.');
    }
  }

  Future<bool> _refresh() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _request('POST', '/api/auth/refresh-token', body: {'refreshToken': _refreshToken}, retried: true);
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

  Map<String, dynamic> _data(Map<String, dynamic> response) => (response['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
}
