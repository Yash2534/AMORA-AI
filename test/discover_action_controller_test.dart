import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiscoverApi extends DiscoverApiService {
  String? lastTargetUserId;
  String? lastAction;
  int swipeCalls = 0;

  @override
  Future<DiscoverApiResult<DiscoverSwipeResult>> swipe({
    required String targetUserId,
    required String action,
  }) async {
    swipeCalls++;
    lastTargetUserId = targetUserId;
    lastAction = action;
    return DiscoverApiResult.success(
      DiscoverSwipeResult(
        matched: targetUserId == '102',
        conversationId: targetUserId == '102' ? 'conversation-2' : null,
      ),
      statusCode: 200,
    );
  }

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> rewind() async =>
      const DiscoverApiResult.success(<String, dynamic>{}, statusCode: 200);
}

void main() {
  late _FakeDiscoverApi api;
  late DiscoverActionController controller;
  late int chatRefreshes;

  setUp(() {
    chatRefreshes = 0;
    api = _FakeDiscoverApi();
    controller = DiscoverActionController(
      profileIds: const ['101', '102', '103'],
      mutualLikeProfileIds: const ['102'],
      transitionDuration: Duration.zero,
      apiService: api,
      refreshChats: () async => chatRefreshes++,
    );
  });

  tearDown(() => controller.dispose());

  test('pass advances and rewind restores profile and image index', () async {
    controller.setImageIndex('101', 2);
    final result = await controller.passProfile();
    expect(result, isTrue);
    expect(api.lastTargetUserId, '101');
    expect(api.lastAction, 'pass');
    expect(controller.currentProfileId, '102');
    expect(controller.canRewind, isTrue);
    await controller.rewindProfile();
    expect(controller.currentProfileId, '101');
    expect(controller.imageIndexFor('101'), 2);
  });

  test('like exposes deterministic mutual match with numeric ID', () async {
    await controller.passProfile();
    final result = await controller.likeProfile();
    expect(result, isTrue);
    expect(api.lastTargetUserId, '102');
    expect(api.lastAction, 'like');
    expect(controller.likedProfileIds, contains('102'));
    expect(controller.matchedProfileId, '102');
    expect(chatRefreshes, 1);
  });

  test('deck exposes empty state', () async {
    await controller.passProfile();
    await controller.passProfile();
    await controller.passProfile();
    expect(controller.isEmpty, isTrue);
  });

  test('non-numeric profile ID blocks API call and sets lastError', () async {
    final invalidController = DiscoverActionController(
      profileIds: const ['female-1'],
      transitionDuration: Duration.zero,
      apiService: api,
    );
    final result = await invalidController.likeProfile();
    expect(result, isFalse);
    expect(invalidController.lastError, 'Unable to process this profile right now. Please try again.');
    expect(api.swipeCalls, 0);
    invalidController.dispose();
  });
}
