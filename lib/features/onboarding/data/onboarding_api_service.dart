import 'dart:async';
import 'dart:convert';

import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class OnboardingApiResult<T> {
  const OnboardingApiResult.success(this.data) : success = true, message = '';
  const OnboardingApiResult.failure(this.message)
    : success = false,
      data = null;

  final bool success;
  final T? data;
  final String message;
}

class OnboardingRemoteProfile {
  const OnboardingRemoteProfile(this.values);

  final Map<String, dynamic> values;
}

class OnboardingPhotoUpload {
  const OnboardingPhotoUpload({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final List<int> bytes;
  final String mimeType;
  final String fileName;
}

class OnboardingApiService {
  OnboardingApiService({http.Client? client})
    : _client = client ?? http.Client();

  static const _accessTokenKey = 'amora_access_token';
  static const _timeout = Duration(seconds: 10);
  static const _storage = FlutterSecureStorage();
  final http.Client _client;

  Future<OnboardingApiResult<OnboardingRemoteProfile>> status() =>
      _request('GET', '/api/onboarding/status');

  Future<OnboardingApiResult<OnboardingRemoteProfile>> saveAge(
    DateTime birthDate,
  ) => _request(
    'PUT',
    '/api/onboarding/age',
    body: {'birthDate': birthDate.toIso8601String().split('T').first},
  );

  Future<OnboardingApiResult<OnboardingRemoteProfile>> saveGender(
    String gender, {
    String customGender = '',
  }) => _request(
    'PUT',
    '/api/onboarding/gender',
    body: {'gender': gender, 'customGender': customGender},
  );

  Future<OnboardingApiResult<OnboardingRemoteProfile>> saveInterestedIn(
    Iterable<String> interestedIn,
  ) => _request(
    'PUT',
    '/api/onboarding/interested-in',
    body: {'interestedIn': interestedIn.toList(growable: false)},
  );

  Future<OnboardingApiResult<OnboardingRemoteProfile>> saveRelationshipGoals(
    Iterable<String> relationshipGoals,
  ) => _request(
    'PUT',
    '/api/onboarding/relationship-goal',
    body: {'relationshipGoals': relationshipGoals.toList(growable: false)},
  );

  Future<OnboardingApiResult<OnboardingRemoteProfile>> saveLocation(
    String city,
    double preferredDistance,
  ) => _request(
    'PUT',
    '/api/onboarding/location',
    body: {'city': city, 'preferredDistance': preferredDistance.round()},
  );

  Future<OnboardingApiResult<OnboardingRemoteProfile>> saveStarterProfile({
    required String profession,
    required String company,
    required String education,
  }) => _request(
    'PUT',
    '/api/onboarding/starter-profile',
    body: {
      'profession': profession,
      'company': company,
      'education': education,
    },
  );

  Future<OnboardingApiResult<OnboardingRemoteProfile>> saveProfileCompletion(
    Map<String, dynamic> values,
  ) => _request('PUT', '/api/onboarding/profile-completion', body: values);

  Future<OnboardingApiResult<OnboardingRemoteProfile>> uploadPhotos(
    List<OnboardingPhotoUpload> photos,
  ) async {
    final setup = await _requestSetup('/api/onboarding/photos');
    if (setup == null) {
      return const OnboardingApiResult.failure(
        'Onboarding service is not configured or authenticated.',
      );
    }
    try {
      final request = http.MultipartRequest('POST', setup.uri)
        ..headers.addAll(
          Map<String, String>.from(setup.headers)..remove('Content-Type'),
        );
      for (final photo in photos) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photos',
            photo.bytes,
            filename: photo.fileName,
            contentType: MediaType.parse(photo.mimeType),
          ),
        );
      }
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
      return _parse(response);
    } on TimeoutException {
      return const OnboardingApiResult.failure(
        'The onboarding request timed out.',
      );
    } catch (_) {
      return const OnboardingApiResult.failure(
        'Unable to sync onboarding data right now.',
      );
    }
  }

  Future<OnboardingApiResult<OnboardingRemoteProfile>> deletePhoto(int index) =>
      _request('DELETE', '/api/onboarding/photos/$index');

  Future<OnboardingApiResult<OnboardingRemoteProfile>> setPrimaryPhoto(
    int index,
  ) => _request(
    'PUT',
    '/api/onboarding/photos/primary',
    body: {'primaryPhotoIndex': index},
  );

  Future<OnboardingApiResult<OnboardingRemoteProfile>> complete() =>
      _request('POST', '/api/onboarding/complete');

  Future<OnboardingApiResult<OnboardingRemoteProfile>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final setup = await _requestSetup(path);
    if (setup == null) {
      return const OnboardingApiResult.failure(
        'Onboarding service is not configured or authenticated.',
      );
    }
    try {
      final request = http.Request(method, setup.uri)
        ..headers.addAll(setup.headers);
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
      return _parse(response);
    } on TimeoutException {
      return const OnboardingApiResult.failure(
        'The onboarding request timed out.',
      );
    } catch (_) {
      return const OnboardingApiResult.failure(
        'Unable to sync onboarding data right now.',
      );
    }
  }

  Future<_RequestSetup?> _requestSetup(String path) async {
    try {
      final baseUrl = AmoraApiConfig.baseUrl;
      final token = await _storage.read(key: _accessTokenKey);
      if (baseUrl.isEmpty || token == null || token.isEmpty) return null;
      return _RequestSetup(Uri.parse('$baseUrl$path'), {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      });
    } catch (_) {
      return null;
    }
  }

  OnboardingApiResult<OnboardingRemoteProfile> _parse(http.Response response) {
    try {
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
        final data = body['data'] as Map?;
        final profile = data?['onboarding'] as Map?;
        if (profile != null) {
          return OnboardingApiResult.success(
            OnboardingRemoteProfile(profile.cast<String, dynamic>()),
          );
        }
      }
      return OnboardingApiResult.failure(
        body['message'] as String? ??
            'Unable to sync onboarding data right now.',
      );
    } catch (_) {
      return const OnboardingApiResult.failure(
        'Unable to read the onboarding service response.',
      );
    }
  }
}

class _RequestSetup {
  const _RequestSetup(this.uri, this.headers);

  final Uri uri;
  final Map<String, String> headers;
}
