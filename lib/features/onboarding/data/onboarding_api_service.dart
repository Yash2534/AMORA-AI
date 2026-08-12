import 'package:amora_ai/core/auth/auth_service.dart';

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
      final response = await _auth.authenticatedMultipartFiles(
        '/api/onboarding/photos',
        files: photos
            .map(
              (photo) => AuthenticatedMultipartFile(
                field: 'photos',
                bytes: photo.bytes,
                filename: photo.fileName,
                mimeType: photo.mimeType,
              ),
            )
            .toList(growable: false),
      );
      return _parse(response);
    } on AuthException catch (error) {
      return OnboardingApiResult.failure(error.userMessage);
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
