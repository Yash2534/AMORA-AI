import 'dart:convert';
import 'dart:developer' as developer;

import 'package:amora_ai/core/auth/auth_service.dart';
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
  OnboardingApiService({AuthService? auth})
    : _auth = auth ?? AuthService.instance;

  final AuthService _auth;

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
    try {
      OnboardingApiResult<OnboardingRemoteProfile>? result;
      for (final photo in photos) {
        developer.log('[Cloudinary] requesting signature', name: 'AmoraCloudinary');
        final signature = await _signature(photo.mimeType);
        if (!signature.success || signature.data == null) {
          return OnboardingApiResult.failure(signature.message);
        }
        developer.log('[Cloudinary] signature received', name: 'AmoraCloudinary');
        final uploaded = await _uploadToCloudinary(photo, signature.data!);
        developer.log('[Cloudinary] public_id=${uploaded['public_id']}', name: 'AmoraCloudinary');
        developer.log('[Cloudinary] persisting asset', name: 'AmoraCloudinary');
        result = await _request(
          'POST',
          '/api/onboarding/photos/cloudinary',
          body: {'publicId': uploaded['public_id']},
        );
        if (!result.success) return result;
        developer.log('[Cloudinary] persistence success', name: 'AmoraCloudinary');
      }
      return result ?? const OnboardingApiResult.failure('No photos were provided.');
    } on AuthException catch (error) {
      return OnboardingApiResult.failure(error.userMessage);
    } on Object {
      return const OnboardingApiResult.failure(
        'Unable to upload the photo right now. Please try again.',
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
    try {
      final response = await _auth.authenticatedRequest(
        method,
        path,
        body: body,
      );
      return _parse(response);
    } on AuthException catch (error) {
      return OnboardingApiResult.failure(error.userMessage);
    }
  }

  Future<OnboardingApiResult<Map<String, dynamic>>> _signature(
    String mimeType,
  ) async {
    try {
      final response = await _auth.authenticatedRequest(
        'POST',
        '/api/onboarding/photos/sign',
        body: {'mimeType': mimeType},
      );
      final data = response['data'] as Map?;
      if (data == null) {
        return const OnboardingApiResult.failure(
          'The upload service returned an invalid signature.',
        );
      }
      return OnboardingApiResult.success(data.cast<String, dynamic>());
    } on AuthException catch (error) {
      return OnboardingApiResult.failure(error.userMessage);
    }
  }

  Future<Map<String, dynamic>> _uploadToCloudinary(
    OnboardingPhotoUpload photo,
    Map<String, dynamic> signature,
  ) async {
    final cloudName = signature['cloudName'] as String?;
    final apiKey = signature['apiKey'] as String?;
    final timestamp = signature['timestamp'];
    final signedValue = signature['signature'] as String?;
    final uploadPreset = signature['uploadPreset'] as String?;
    final folder = signature['folder'] as String?;
    final publicId = signature['publicId'] as String?;
    final formats = (signature['allowedFormats'] as List?)?.join(',');
    if (cloudName == null || apiKey == null || timestamp == null || signedValue == null || uploadPreset == null || folder == null || publicId == null || formats == null) {
      throw const AuthException('The upload service returned an incomplete signature.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    )
      ..fields.addAll({
        'api_key': apiKey,
        'timestamp': timestamp.toString(),
        'signature': signedValue,
        'upload_preset': uploadPreset,
        'folder': folder,
        'public_id': publicId,
        'allowed_formats': formats,
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          photo.bytes,
          filename: photo.fileName,
          contentType: MediaType.parse(photo.mimeType),
        ),
      );
    developer.log('[Cloudinary] uploading image', name: 'AmoraCloudinary');
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 10)),
    );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || decoded['public_id'] is! String) {
      throw AuthException(
        decoded['error'] is Map
            ? (decoded['error']['message'] as String? ?? 'Cloudinary rejected the image upload.')
            : 'Cloudinary rejected the image upload.',
        statusCode: response.statusCode,
      );
    }
    developer.log('[Cloudinary] upload response received', name: 'AmoraCloudinary');
    return decoded;
  }

  OnboardingApiResult<OnboardingRemoteProfile> _parse(
    Map<String, dynamic> body,
  ) {
    try {
      if (body['success'] == true) {
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
