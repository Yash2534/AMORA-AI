import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DiscoverActionController controller;

  setUp(() {
    controller = DiscoverActionController(
      profileIds: const ['profile-1', 'profile-2', 'profile-3'],
      mutualLikeProfileIds: const ['profile-2'],
      transitionDuration: Duration.zero,
    );
  });

  tearDown(() => controller.dispose());

  test('pass advances and rewind restores profile and image index', () async {
    controller.setImageIndex('profile-1', 2);
    await controller.passProfile();

    expect(controller.currentProfileId, 'profile-2');
    expect(controller.passedProfileIds, contains('profile-1'));
    expect(controller.canRewind, isTrue);

    await controller.rewindProfile();
    expect(controller.currentProfileId, 'profile-1');
    expect(controller.imageIndexFor('profile-1'), 2);
    expect(controller.passedProfileIds, isNot(contains('profile-1')));
  });

  test(
    'like records local state and exposes deterministic mutual match',
    () async {
      await controller.passProfile();
      await controller.likeProfile();

      expect(controller.likedProfileIds, contains('profile-2'));
      expect(controller.matchedProfileId, 'profile-2');
    },
  );

  test('super like advances and rapid repeated actions are guarded', () async {
    final guarded = DiscoverActionController(
      profileIds: const ['profile-1', 'profile-2'],
      transitionDuration: const Duration(milliseconds: 20),
    );
    addTearDown(guarded.dispose);

    final first = guarded.superLikeProfile();
    final repeated = guarded.passProfile();
    await Future.wait([first, repeated]);

    expect(guarded.superLikedProfileIds, contains('profile-1'));
    expect(guarded.passedProfileIds, isEmpty);
    expect(guarded.currentProfileId, 'profile-2');
  });

  test('boost requests a preview without changing the deck', () async {
    await controller.boostProfile();

    expect(controller.boostRequested, isTrue);
    expect(controller.currentProfileId, 'profile-1');
    controller.consumeBoostRequest();
    expect(controller.boostRequested, isFalse);
  });

  test('deck exposes a polished empty state condition', () async {
    await controller.passProfile();
    await controller.passProfile();
    await controller.passProfile();
    expect(controller.isEmpty, isTrue);
    expect(controller.currentProfileId, isNull);
  });
}
