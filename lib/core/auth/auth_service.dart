import 'dart:async';
import 'dart:convert';

import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:amora_ai/core/firebase/firebase_service.dart';
import 'package:amora_ai/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AuthenticatedMultipartFile {
  const AuthenticatedMultipartFile({
    required this.field,
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final String field;
  final List<int> bytes;
  final String filename;
  final String mimeType;
}

class AuthException implements Exception {
  const AuthException(
    this.message, {
    this.code,
    this.statusCode,
    this.errors = const <String, String>{},
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, String> errors;

  String get userMessage {
    if (errors.isEmpty) return message;
    return '$message ${errors.values.join(' ')}';
  }

  @override
  String toString() => userMessage;
}

String userFacingErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is! AuthException) return fallback;
  if (error.statusCode == 401 ||
      error.code == 'TOKEN_INVALID' ||
      error.code == 'TOKEN_EXPIRED') {
    return 'Your session has expired. Please log in again.';
  }
  final message = error.userMessage.trim();
  return message.isEmpty ? fallback : message;
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
  Future<bool>? _refreshInFlight;
  int _sessionGeneration = 0;
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
    final user = await _saveAuthentication(response);
    await FirebaseService.instance.logAuthEvent('sign_up', method: 'password');
    return user;
  }

  Future<AmoraUser> login(String email, String password) async {
    final response = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    final user = await _saveAuthentication(response);
    await FirebaseService.instance.logAuthEvent('login', method: 'password');
    return user;
  }

  Future<AmoraUser> googleSignIn() async {
    final account = await GoogleSignIn(
      clientId: DefaultFirebaseOptions.googleSignInClientId,
      scopes: const ['email'],
    ).signIn();
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
    try {
      await FirebaseService.instance.signInWithGoogleCredential(
        idToken: idToken,
        accessToken: authentication.accessToken,
      );
      final response = await _post('/api/auth/google', {'idToken': idToken});
      final user = await _saveAuthentication(response);
      await FirebaseService.instance.logAuthEvent('login', method: 'google');
      return user;
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        error.message ?? 'Google sign-in could not be completed.',
        code: error.code,
      );
    } on AuthException {
      await FirebaseService.instance.signOut();
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async =>
      _post('/api/auth/forgot-password', {'email': email});

  Future<String> verifyResetCode(String email, String code) async {
    final response = await _post('/api/auth/verify-reset-code', {
      'email': email,
      'code': code,
    });
    return _data(response)['recoveryToken'] as String;
  }

  Future<void> resetPassword(
    String email,
    String recoveryToken,
    String newPassword,
  ) async => _post('/api/auth/reset-password', {
    'email': email,
    'recoveryToken': recoveryToken,
    'newPassword': newPassword,
  });

  Future<AmoraUser> me() async {
    final response = await _request('GET', '/api/auth/me', authenticated: true);
    return AmoraUser.fromJson(_data(response)['user'] as Map<String, dynamic>);
  }

  Future<String?> realtimeAccessToken() async {
    await _request('GET', '/api/auth/me', authenticated: true);
    return _accessToken;
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null && _refreshToken != null) {
        final deviceToken = await FirebaseService.instance.currentToken();
        if (deviceToken != null) {
          await _request(
            'DELETE',
            '/api/devices',
            body: {'pushToken': deviceToken},
            authenticated: true,
          );
        }
        await _post('/api/auth/logout', {
          'refreshToken': _refreshToken,
        }, authenticated: true);
      }
    } on AuthException {
      // Local token removal is still required if the network is unavailable.
    } finally {
      FirebaseService.instance.clearAuthenticatedDevice();
      try {
        await FirebaseService.instance.signOut();
      } catch (error, stack) {
        await FirebaseService.instance.recordNonFatal(
          error,
          stack,
          reason: 'firebase_sign_out',
        );
      }
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    _sessionGeneration++;
    _refreshInFlight = null;
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

  Future<AmoraUser> _saveAuthentication(Map<String, dynamic> response) async {
    final data = _data(response);
    _sessionGeneration++;
    _refreshInFlight = null;
    _accessToken = data['accessToken'] as String;
    _refreshToken = data['refreshToken'] as String;
    await _storage.write(key: _accessKey, value: _accessToken);
    await _storage.write(key: _refreshKey, value: _refreshToken);
    currentUser = AmoraUser.fromJson(data['user'] as Map<String, dynamic>);
    registerCurrentFirebaseDevice();
    return currentUser!;
  }

  void registerCurrentFirebaseDevice() {
    if (_accessToken == null || currentUser == null) return;
    FirebaseService.instance.bindAuthenticatedDevice((token, platform) async {
      await authenticatedRequest(
        'POST',
        '/api/devices',
        body: {'pushToken': token, 'platform': platform},
      );
    });
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
  }) => authenticatedMultipartFiles(
    path,
    files: [
      AuthenticatedMultipartFile(
        field: field,
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      ),
    ],
    fields: fields,
    retried: retried,
  );

  Future<Map<String, dynamic>> authenticatedMultipartFiles(
    String path, {
    required List<AuthenticatedMultipartFile> files,
    Map<String, String> fields = const {},
    bool retried = false,
  }) async {
    if (files.isEmpty) {
      throw const AuthException('At least one upload file is required.');
    }
    final uri = Uri.parse('${AmoraApiConfig.baseUrl}$path');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json';
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      request.fields.addAll(fields);
      request.files.addAll(
        files.map(
          (file) => http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
            contentType: MediaType.parse(file.mimeType),
          ),
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
        return authenticatedMultipartFiles(
          path,
          files: files,
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
          errors: _errorDetails(decoded['errors']),
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
          errors: _errorDetails(decoded['errors']),
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

  Future<bool> _refresh() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    final operation = _performRefresh();
    _refreshInFlight = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_refreshInFlight, operation)) {
          _refreshInFlight = null;
        }
      }),
    );
    return operation;
  }

  Future<bool> _performRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) return false;
    final sessionGeneration = _sessionGeneration;
    try {
      final response = await _request(
        'POST',
        '/api/auth/refresh-token',
        body: {'refreshToken': refreshToken},
        retried: true,
      );
      if (_sessionGeneration != sessionGeneration ||
          _refreshToken != refreshToken) {
        return false;
      }
      final data = _data(response);
      _accessToken = data['accessToken'] as String;
      _refreshToken = data['refreshToken'] as String;
      await _storage.write(key: _accessKey, value: _accessToken);
      await _storage.write(key: _refreshKey, value: _refreshToken);
      return true;
    } on AuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      (response['data'] as Map?)?.cast<String, dynamic>() ??
      <String, dynamic>{};

  Map<String, String> _errorDetails(Object? value) {
    if (value is Map) {
      return value.map(
        (field, message) => MapEntry(field.toString(), message.toString()),
      );
    }
    if (value is! List) return const <String, String>{};
    final details = <String, String>{};
    for (final item in value.whereType<Map>()) {
      final field = item['field']?.toString().trim() ?? '';
      final message = item['message']?.toString().trim() ?? '';
      if (field.isNotEmpty && message.isNotEmpty) details[field] = message;
    }
    return details;
  }
}
