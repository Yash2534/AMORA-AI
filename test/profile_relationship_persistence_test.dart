import 'dart:async';

import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _RelationshipRemote implements ProfileRelationshipRemoteDataSource {
  int likeCalls = 0;
  int unlikeCalls = 0;
  bool failLike = false;
  bool failUnlike = false;
  Completer<Map<String, dynamic>>? pendingLike;
  Completer<Map<String, dynamic>>? pendingLikesRefresh;
  List<Map<String, dynamic>> likes = <Map<String, dynamic>>[];

  Map<String, dynamic> response([
    List<Map<String, dynamic>> profiles = const [],
  ]) => <String, dynamic>{
    'success': true,
    'data': <String, dynamic>{
      'profiles': profiles,
      'pagination': <String, dynamic>{'hasMore': false, 'nextPage': null},
    },
  };

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (method == 'GET' && path.startsWith('/api/me/likes')) {
      final pending = pendingLikesRefresh;
      return pending == null ? response(likes) : pending.future;
    }
    if (method == 'GET') return response();
    if (method == 'POST' && path == '/api/discover/swipe') {
      likeCalls++;
      if (failLike) throw StateError('like failed');
      final pending = pendingLike;
      if (pending != null) return pending.future;
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'targetUserId': body?['targetUserId'].toString(),
          'action': 'like',
          'likeStatus': 'liked',
          'matched': false,
        },
      };
    }
    if (method == 'DELETE' && path.startsWith('/api/reactions/')) {
      unlikeCalls++;
      if (failUnlike) throw StateError('unlike failed');
      return <String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'liked': false},
      };
    }
    throw StateError('Unexpected request: $method $path');
  }
}

void main() {
  final profileJson = <String, dynamic>{
    'id': '42',
    'name': 'Persistent Like',
    'age': 28,
    'relationship': <String, dynamic>{'liked': true},
  };
  final profile = publicProfileFromJson(profileJson).profile;
  late _RelationshipRemote remote;
  late ProfileRelationshipController controller;

  setUp(() {
    remote = _RelationshipRemote();
    controller = ProfileRelationshipController(remote: remote);
  });

  test('an unliked profile starts unselected', () {
    expect(controller.isLiked(profile.id), isFalse);
  });

  test(
    'successful Like persists locally and duplicate taps call the API once',
    () async {
      remote.pendingLike = Completer<Map<String, dynamic>>();
      final first = controller.likeProfilePersisted(profile);
      final duplicate = controller.likeProfilePersisted(profile);
      expect(remote.likeCalls, 1);
      expect(controller.isReactionMutating(profile.id), isTrue);
      remote.pendingLike!.complete(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'likeStatus': 'liked', 'matched': false},
      });
      await Future.wait(<Future<void>>[first, duplicate]);
      expect(controller.isLiked(profile.id), isTrue);
      expect(controller.isReactionMutating(profile.id), isFalse);
    },
  );

  test('a failed Like does not leave false success state', () async {
    remote.failLike = true;
    await expectLater(
      controller.likeProfilePersisted(profile),
      throwsStateError,
    );
    expect(controller.isLiked(profile.id), isFalse);
  });

  test('explicit Unlike removes Like only after backend success', () async {
    controller.likeProfile(profile);
    await controller.removeLikePersisted(profile.id);
    expect(remote.unlikeCalls, 1);
    expect(controller.isLiked(profile.id), isFalse);
  });

  test('failed Unlike retains the Liked state', () async {
    controller.likeProfile(profile);
    remote.failUnlike = true;
    await expectLater(
      controller.removeLikePersisted(profile.id),
      throwsStateError,
    );
    expect(controller.isLiked(profile.id), isTrue);
  });

  test('backend refresh reconstructs Like after a new app session', () async {
    remote.likes = <Map<String, dynamic>>[profileJson];
    await controller.refreshRemote();
    expect(controller.isLiked(profile.id), isTrue);
    controller.clearSessionState();
    expect(controller.isLiked(profile.id), isFalse);
    await controller.refreshRemote();
    expect(controller.isLiked(profile.id), isTrue);
  });

  test(
    'stale refresh response cannot overwrite a newer successful Like',
    () async {
      remote.pendingLikesRefresh = Completer<Map<String, dynamic>>();
      final refresh = controller.refreshRemote();
      await Future<void>.delayed(Duration.zero);
      await controller.likeProfilePersisted(profile);
      expect(controller.isLiked(profile.id), isTrue);
      remote.pendingLikesRefresh!.complete(remote.response());
      await refresh;
      expect(controller.isLiked(profile.id), isTrue);
    },
  );

  test('stale profile response cannot overwrite a newer Like', () {
    final requestRevision = controller.relationshipRevisionFor(profile.id);
    controller.likeProfile(profile);
    controller.applyAuthoritativeRelationship(
      profile,
      const PublicRelationshipState(liked: false),
      unlessChangedSince: requestRevision,
    );
    expect(controller.isLiked(profile.id), isTrue);
  });

  test(
    'a completed request from an old logged-out session cannot reapply Like',
    () async {
      remote.pendingLike = Completer<Map<String, dynamic>>();
      final like = controller.likeProfilePersisted(profile);
      controller.clearSessionState();
      remote.pendingLike!.complete(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{'likeStatus': 'liked'},
      });
      await like;
      expect(controller.isLiked(profile.id), isFalse);
    },
  );
}
