import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiscoverApi extends DiscoverApiService {
  @override
  Future<DiscoverApiResult<DiscoverSwipeResult>> swipe({
    required String targetUserId,
    required String action,
  }) async => DiscoverApiResult.success(
    DiscoverSwipeResult(
      matched: targetUserId == 'profile-2',
      conversationId: targetUserId == 'profile-2' ? 'conversation-2' : null,
    ),
    statusCode: 200,
  );

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> rewind() async =>
      const DiscoverApiResult.success(<String, dynamic>{}, statusCode: 200);
}

void main() {
  late DiscoverActionController controller;
  late int chatRefreshes;
  setUp(() {
    chatRefreshes = 0;
    controller = DiscoverActionController(
      profileIds: const ['profile-1', 'profile-2', 'profile-3'],
      mutualLikeProfileIds: const ['profile-2'],
      transitionDuration: Duration.zero,
      apiService: _FakeDiscoverApi(),
      refreshChats: () async => chatRefreshes++,
    );
  });
  tearDown(() => controller.dispose());

  test('pass advances and rewind restores profile and image index', () async {
    controller.setImageIndex('profile-1', 2);
    await controller.passProfile();
    expect(controller.currentProfileId, 'profile-2');
    expect(controller.canRewind, isTrue);
    await controller.rewindProfile();
    expect(controller.currentProfileId, 'profile-1');
    expect(controller.imageIndexFor('profile-1'), 2);
  });

  test('like exposes deterministic mutual match', () async {
    await controller.passProfile();
    await controller.likeProfile();
    expect(controller.likedProfileIds, contains('profile-2'));
    expect(controller.matchedProfileId, 'profile-2');
    expect(chatRefreshes, 1);
  });

  test('deck exposes empty state', () async {
    await controller.passProfile();
    await controller.passProfile();
    await controller.passProfile();
    expect(controller.isEmpty, isTrue);
  });
}
