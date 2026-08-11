import 'package:amora_ai/features/discover/data/discover_api_service.dart';
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

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add('$method $path');
    if (path.startsWith('/api/saved-profiles?')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('2', 'Saved')],
        },
      };
    }
    if (path.contains('type=superLike')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('4', 'Super')],
        },
      };
    }
    if (path.contains('type=like')) {
      return <String, dynamic>{
        'data': <String, dynamic>{
          'profiles': <dynamic>[_profile('3', 'Liked')],
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
    if (body != null)
      values = <String, dynamic>{...values, ...body, 'safetyUpdates': true};
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
      await controller.removeSavedPersisted('2');
      expect(controller.savedProfiles, isEmpty);
      expect(remote.calls, contains('DELETE /api/saved-profiles/2'));
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
