import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/settings/data/notification_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _profile(String id, String name) => <String, dynamic>{
  'id': id,
  'name': name,
  'gender': 'Woman',
  'age': 28,
  'gallery': <String>['https://images.test/$id.jpg'],
};

class _RelationshipRemote implements ProfileRelationshipRemoteDataSource {
  final List<String> calls = <String>[];
  bool failSave = false;
  bool failLoad = false;
  bool failLike = false;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add('$method $path');
    if (failLoad && method == 'GET') {
      throw const AuthException('Relationship service unavailable.');
    }
    if (failSave && method == 'PUT') {
      throw const AuthException('Profile could not be saved.');
    }
    if (failLike && method == 'POST' && path == '/api/discover/swipe') {
      throw const AuthException('Like could not be saved.');
    }
    if (path.startsWith('/api/me/saved-profiles?page=2')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('5', 'Saved page two')],
          'pagination': <String, dynamic>{
            'page': 2,
            'limit': 20,
            'hasMore': false,
            'nextPage': null,
          },
        },
      };
    }
    if (path.startsWith('/api/me/saved-profiles?')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('2', 'Saved')],
          'pagination': <String, dynamic>{
            'page': 1,
            'limit': 20,
            'hasMore': true,
            'nextPage': 2,
          },
        },
      };
    }
    if (path.startsWith('/api/me/super-likes?page=2')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('7', 'Super page two')],
          'pagination': <String, dynamic>{'hasMore': false},
        },
      };
    }
    if (path.startsWith('/api/me/super-likes?')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('4', 'Super')],
          'pagination': <String, dynamic>{'hasMore': true, 'nextPage': 2},
        },
      };
    }
    if (path.startsWith('/api/me/likes?page=2')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('6', 'Liked page two')],
          'pagination': <String, dynamic>{'hasMore': false},
        },
      };
    }
    if (path.startsWith('/api/me/likes?')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('3', 'Liked')],
          'pagination': <String, dynamic>{'hasMore': true, 'nextPage': 2},
        },
      };
    }
    return <String, dynamic>{'data': <String, dynamic>{}};
  }
}

class _NotificationRemote implements NotificationPreferencesRemoteDataSource {
  Map<String, dynamic> values = <String, dynamic>{
    'newMatches': true,
    'messages': true,
    'eventReminders': true,
    'paymentsAndMembership': true,
    'offers': false,
    'safetyUpdates': true,
    'pushEnabled': false,
    'emailEnabled': true,
    'smsEnabled': false,
    'quietHoursEnabled': true,
    'quietStart': '22:00',
    'quietEnd': '07:00',
  };

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (body != null) {
      values = <String, dynamic>{...values, ...body, 'safetyUpdates': true};
    }
    return <String, dynamic>{
      'data': <String, dynamic>{'preferences': values},
    };
  }
}

void main() {
  test('Discover query sends server-backed online and event filters', () {
    expect(
      buildDiscoverFeedQuery(
        page: 1,
        limit: 10,
        onlineNow: true,
        hasEventInterest: true,
      ),
      containsPair('onlineNow', 'true'),
    );
    expect(
      buildDiscoverFeedQuery(
        page: 1,
        limit: 10,
        onlineNow: true,
        hasEventInterest: true,
      ),
      containsPair('hasEventInterest', 'true'),
    );
  });

  test(
    'saved, liked, and super-liked profiles reload from remote state',
    () async {
      final remote = _RelationshipRemote();
      final controller = ProfileRelationshipController(remote: remote);
      addTearDown(controller.dispose);
      await controller.refreshRemote();
      expect(controller.savedProfileIds, <String>['2']);
      expect(controller.likedProfileIds, <String>['3']);
      expect(controller.superLikedProfileIds, <String>['4']);
      expect(controller.savedHasMore, isTrue);
      await controller.loadMoreSaved();
      expect(controller.savedProfileIds, <String>['2', '5']);
      await controller.loadMoreReactions(ProfileReactionType.like);
      await controller.loadMoreReactions(ProfileReactionType.superLike);
      expect(controller.likedProfileIds, <String>['3', '6']);
      expect(controller.superLikedProfileIds, <String>['4', '7']);
      await controller.removeSavedPersisted('2');
      expect(controller.savedProfileIds, <String>['5']);
      expect(remote.calls, contains('DELETE /api/me/saved-profiles/2'));
      expect(
        remote.calls,
        contains('GET /api/me/saved-profiles?page=2&limit=20'),
      );
    },
  );

  test('save failure never creates local relationship state', () async {
    final remote = _RelationshipRemote()..failSave = true;
    final controller = ProfileRelationshipController(remote: remote);
    addTearDown(controller.dispose);
    final profile = ImageRepository.profileAt(2);

    await expectLater(
      controller.saveProfilePersisted(profile),
      throwsA(isA<AuthException>()),
    );
    expect(controller.savedProfileIds, isEmpty);
  });

  test('save and Like caches update only after backend success', () async {
    final remote = _RelationshipRemote();
    final controller = ProfileRelationshipController(remote: remote);
    addTearDown(controller.dispose);
    final profile = publicProfileFromJson(_profile('12', 'Persisted')).profile;

    await controller.saveProfilePersisted(profile);
    await controller.likeProfilePersisted(profile);
    expect(controller.savedProfileIds, <String>['12']);
    expect(controller.likedProfileIds, <String>['12']);
    expect(remote.calls, contains('PUT /api/me/saved-profiles/12'));
    expect(remote.calls, contains('POST /api/discover/swipe'));

    final failingRemote = _RelationshipRemote()..failLike = true;
    final failing = ProfileRelationshipController(remote: failingRemote);
    addTearDown(failing.dispose);
    await expectLater(
      failing.likeProfilePersisted(profile),
      throwsA(isA<AuthException>()),
    );
    expect(failing.likedProfileIds, isEmpty);
  });

  test(
    'relationship load failure exposes retryable error without dummy data',
    () async {
      final remote = _RelationshipRemote()..failLoad = true;
      final controller = ProfileRelationshipController(remote: remote);
      addTearDown(controller.dispose);

      await controller.refreshRemote();

      expect(controller.error, 'Relationship service unavailable.');
      expect(controller.savedProfiles, isEmpty);
      expect(controller.likedProfiles, isEmpty);
      expect(controller.superLikedProfiles, isEmpty);
    },
  );

  test(
    'notification settings update from canonical backend response',
    () async {
      final repository = NotificationPreferencesRepository(
        remote: _NotificationRemote(),
      );
      expect((await repository.get()).newMatches, isTrue);
      final updated = await repository.update(<String, dynamic>{
        'newMatches': false,
        'quietStart': '21:30',
      });
      expect(updated.newMatches, isFalse);
      expect(updated.quietStart, '21:30');
      expect(updated.safetyUpdates, isTrue);
    },
  );
}
