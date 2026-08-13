import 'dart:async';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _canonicalProfile({
  String name = 'Server Profile',
  String bio = 'A canonical profile biography returned by the backend.',
  String education = 'Graduate',
  int completion = 74,
}) => <String, dynamic>{
  'name': name,
  'email': 'profile@test.example',
  'phoneNumber': '+910000000000',
  'birthdate': '03/04/1997',
  'gender': 'Female',
  'customGender': '',
  'bio': bio,
  'profession': 'Engineer',
  'company': 'AMORAA',
  'education': education,
  'location': 'Ahmedabad',
  'datingIntention': 'Meaningful Dating',
  'interests': <String>['Coffee', 'Travel', 'Music', 'Reading', 'Fitness'],
  'prompts': <String, String>{'A perfect day': 'Coffee and a walk.'},
  'lifestyle': <String, String>{
    'Height': '165 cm',
    'Languages': 'Gujarati & English',
    'Religion': 'Hindu',
    'Smoking': 'Never',
  },
  'photos': <String>[
    'https://images.test/one.jpg',
    'https://images.test/two.jpg',
  ],
  'primaryPhotoIndex': 0,
  'hometown': 'Ahmedabad',
  'valuedQualities': <String>['Kindness'],
  'pronouns': <String>['she'],
  'sexuality': 'Straight',
  'preferredTalkingHours': <String>['Evening'],
  'loveLanguages': <String>['Quality Time'],
  'iceBreaker': 'Tell me about your favorite place.',
  'communicationStyle': 'calls',
  'profileCompletion': <String, dynamic>{
    'percentage': completion,
    'complete': completion == 100,
  },
};

class _FakeOwnProfileRemote implements OwnProfileRemoteDataSource {
  _FakeOwnProfileRemote({Map<String, dynamic>? profile})
    : profile = profile ?? _canonicalProfile();

  Map<String, dynamic> profile;
  final List<String> calls = <String>[];
  Map<String, dynamic>? lastBody;
  Object? failure;
  Completer<Map<String, dynamic>>? pendingGet;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add('$method $path');
    if (failure case final error?) throw error;
    if (method == 'GET' && pendingGet != null) {
      return pendingGet!.future;
    }
    if (method == 'PUT') {
      lastBody = body;
      profile = _canonicalProfile(
        name: 'Server Normalized Name',
        bio: body?['bio'] as String? ?? profile['bio'] as String,
        education:
            body?['education'] as String? ?? profile['education'] as String,
        completion: 88,
      );
      if (body?['photos'] case final List<String> photos) {
        profile['photos'] = photos;
      }
      if (body?['primaryPhotoIndex'] case final int primaryPhotoIndex) {
        profile['primaryPhotoIndex'] = primaryPhotoIndex;
      }
    }
    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'profile': profile},
    };
  }
}

void main() {
  setUp(() {
    AuthService.instance.currentUser = const AmoraUser(
      id: 42,
      name: 'Authenticated User',
      email: 'profile@test.example',
      phoneNumber: '+910000000000',
      isVerified: true,
    );
  });

  tearDown(() {
    AuthService.instance.currentUser = null;
  });

  test(
    'loads the authenticated profile from the exact Own Profile API',
    () async {
      final remote = _FakeOwnProfileRemote();
      final repository = LocalProfileRepository.testing(remote: remote);
      addTearDown(repository.dispose);

      await repository.refreshFromServer();

      expect(remote.calls, <String>['GET /api/me/profile']);
      expect(repository.hasHydratedAuthenticatedProfile, isTrue);
      expect(repository.profile.name, 'Server Profile');
      expect(
        repository.profile.prompts,
        containsPair('A perfect day', 'Coffee and a walk.'),
      );
      expect(repository.profile.completionPercent, 74);
    },
  );

  test('authenticated defaults are never reported as server hydration', () {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);

    repository.prepareForAuthenticatedUser();

    expect(repository.hasHydratedAuthenticatedProfile, isFalse);
    expect(repository.profile.name, 'Authenticated User');
  });

  test('save waits for and applies the canonical backend response', () async {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();

    await repository.savePersisted(
      repository.profile.copyWith(
        name: 'Unnormalized local form value',
        bio: 'Saved through the authenticated API.',
      ),
    );

    expect(remote.calls.last, 'PUT /api/me/profile');
    expect(remote.lastBody?['bio'], 'Saved through the authenticated API.');
    expect(remote.lastBody?.keys.toSet(), <String>{'name', 'bio'});
    expect(remote.lastBody, isNot(contains('email')));
    expect(remote.lastBody, isNot(contains('userId')));
    expect(repository.profile.name, 'Server Normalized Name');
    expect(repository.profile.completionPercent, 88);
  });

  test('section save sends only changed fields', () async {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();

    await repository.savePersisted(
      repository.profile.copyWith(bio: 'Only this section changed.'),
    );

    expect(remote.lastBody, <String, dynamic>{
      'bio': 'Only this section changed.',
    });
  });

  test('height-only save submits only the changed lifestyle field', () async {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();
    final lifestyle = Map<String, String>.of(repository.profile.lifestyle)
      ..['Height'] = '172 cm';

    await repository.savePersisted(
      repository.profile.copyWith(lifestyle: lifestyle),
    );

    expect(remote.lastBody, <String, dynamic>{'lifestyle': lifestyle});
  });

  test('communication-style-only save submits no unrelated fields', () async {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();

    await repository.savePersisted(
      repository.profile.copyWith(
        communicationStyle: CommunicationStyle.voiceNotes,
      ),
    );

    expect(remote.lastBody, <String, dynamic>{
      'communicationStyle': 'voice_notes',
    });
  });

  test(
    'custom education survives the API response and a fresh reload',
    () async {
      final remote = _FakeOwnProfileRemote();
      final repository = LocalProfileRepository.testing(remote: remote);
      await repository.refreshFromServer();

      await repository.savePersisted(
        repository.profile.copyWith(education: 'Diploma in Fashion Design'),
      );

      expect(remote.lastBody, <String, dynamic>{
        'education': 'Diploma in Fashion Design',
      });
      expect(repository.profile.education, 'Diploma in Fashion Design');
      repository.dispose();

      final reopened = LocalProfileRepository.testing(remote: remote);
      addTearDown(reopened.dispose);
      await reopened.refreshFromServer();
      expect(reopened.profile.education, 'Diploma in Fashion Design');
    },
  );

  test('gender edits send the backend enum instead of legacy labels', () async {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();

    await repository.savePersisted(
      repository.profile.copyWith(
        gender: ProfileFormOptions.storedGenderValue('Male'),
      ),
    );

    expect(remote.lastBody, containsPair('gender', 'Male'));
    expect(remote.lastBody?['gender'], isNot('Man'));
  });

  test(
    'photo order and primary selection are always written remotely',
    () async {
      final remote = _FakeOwnProfileRemote();
      final repository = LocalProfileRepository.testing(remote: remote);
      addTearDown(repository.dispose);
      await repository.refreshFromServer();
      final reordered = repository.profile.photos.reversed.toList();

      repository.updatePhotosInSession(reordered, 1);
      await repository.updatePhotosPersisted(reordered, 1);

      expect(remote.calls.last, 'PUT /api/me/profile');
      expect(remote.lastBody, <String, dynamic>{
        'photos': reordered,
        'primaryPhotoIndex': 1,
      });
      expect(repository.profile.photos, reordered);
      expect(repository.profile.primaryPhotoIndex, 1);
    },
  );

  test('repository enforces the six-photo limit below the UI layer', () async {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();
    repository.updatePhotosInSession(
      List<String>.generate(6, (index) => 'https://images.test/$index.jpg'),
      0,
    );

    repository.addPhotoInSession('data:image/png;base64,AA==');

    expect(repository.profile.photos, hasLength(6));
  });

  test(
    'network or 401 failure does not create fake saved profile state',
    () async {
      final remote = _FakeOwnProfileRemote();
      final repository = LocalProfileRepository.testing(remote: remote);
      addTearDown(repository.dispose);
      await repository.refreshFromServer();
      final before = repository.profile;
      remote.failure = const AuthException(
        'Session expired.',
        code: 'TOKEN_EXPIRED',
        statusCode: 401,
      );

      await expectLater(
        repository.savePersisted(before.copyWith(name: 'Fake success')),
        throwsA(isA<AuthException>()),
      );

      expect(repository.profile.name, before.name);
      expect(repository.lastSyncError, isNull);
    },
  );

  test('background save sanitizes unexpected internal failures', () async {
    final remote = _FakeOwnProfileRemote();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();
    final before = repository.profile;
    remote.failure = StateError('internal profile failure');

    repository.save(before.copyWith(bio: 'Must roll back'));
    await Future<void>.delayed(Duration.zero);

    expect(
      repository.lastSyncError,
      'Profile changes could not be saved. Please try again.',
    );
    expect(
      repository.lastSyncError,
      isNot(contains('internal profile failure')),
    );
    expect(repository.profile.bio, before.bio);
  });

  test('a fresh repository reloads the persisted server profile', () async {
    final remote = _FakeOwnProfileRemote();
    final first = LocalProfileRepository.testing(remote: remote);
    await first.refreshFromServer();
    await first.savePersisted(first.profile.copyWith(bio: 'Persisted bio'));
    first.dispose();

    final reopened = LocalProfileRepository.testing(remote: remote);
    addTearDown(reopened.dispose);
    await reopened.refreshFromServer();

    expect(reopened.profile.bio, 'Persisted bio');
    expect(
      remote.calls.where((call) => call == 'GET /api/me/profile').length,
      2,
    );
  });

  testWidgets('Edit Profile shows loading until canonical GET completes', (
    tester,
  ) async {
    final remote = _FakeOwnProfileRemote()
      ..pendingGet = Completer<Map<String, dynamic>>();
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AmoraaProfileForm(
          repository: repository,
          onSaved: (_, _) async {},
        ),
      ),
    );
    expect(find.byKey(const ValueKey('own-profile-loading')), findsOneWidget);

    remote.pendingGet!.complete(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'profile': _canonicalProfile()},
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('own-profile-loading')), findsNothing);
    expect(find.text('All profile details'), findsOneWidget);
  });

  testWidgets(
    'Edit Profile load error is retryable and exposes server message',
    (tester) async {
      final remote = _FakeOwnProfileRemote()
        ..failure = const AuthException('Unable to load canonical profile.');
      final repository = LocalProfileRepository.testing(remote: remote);
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AmoraaProfileForm(
            repository: repository,
            onSaved: (_, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unable to load canonical profile.'), findsOneWidget);

      remote.failure = null;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('All profile details'), findsOneWidget);
      expect(
        remote.calls.where((call) => call == 'GET /api/me/profile').length,
        2,
      );
    },
  );
}
