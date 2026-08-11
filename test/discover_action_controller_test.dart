import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiscoverApi extends DiscoverApiService {
  bool failNextBoost = false;
  int failureStatusCode = 503;
  String failureMessage = 'temporary';
  int generatedKeys = 0;
  final List<String> boostKeys = <String>[];

  @override
  String newIdempotencyKey(String operation) =>
      'flutter:$operation:test-key-${++generatedKeys}';

  @override
  Future<DiscoverApiResult<DiscoverSwipeResult>> swipe({
    required String targetUserId,
    required String action,
  }) async => DiscoverApiResult.success(
    DiscoverSwipeResult(matched: targetUserId == 'profile-2'),
    statusCode: 200,
  );

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> rewind() async =>
      const DiscoverApiResult.success(<String, dynamic>{}, statusCode: 200);

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> boost(String key) async {
    boostKeys.add(key);
    if (failNextBoost) {
      failNextBoost = false;
      return DiscoverApiResult.failure(
        failureMessage,
        statusCode: failureStatusCode,
      );
    }
    return const DiscoverApiResult.success(<String, dynamic>{
      'active': true,
      'remainingSeconds': 1800,
    }, statusCode: 200);
  }
}

void main() {
  late DiscoverActionController controller;
  late _FakeDiscoverApi api;

  setUp(() {
    api = _FakeDiscoverApi();
    controller = DiscoverActionController(
      profileIds: const ['profile-1', 'profile-2', 'profile-3'],
      mutualLikeProfileIds: const ['profile-2'],
      transitionDuration: Duration.zero,
      apiService: api,
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
      apiService: _FakeDiscoverApi(),
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

  test(
    'boost retries reuse one idempotency key and wait for backend success',
    () async {
      api.failNextBoost = true;
      expect(await controller.boostProfile(), isFalse);
      expect(controller.boostRequested, isFalse);
      expect(await controller.boostProfile(), isTrue);
      expect(api.boostKeys, <String>[
        'flutter:boost-activation:test-key-1',
        'flutter:boost-activation:test-key-1',
      ]);
      expect(controller.boostState?['active'], isTrue);
    },
  );

  test('a new activation after success receives a new key', () async {
    expect(await controller.boostProfile(), isTrue);
    controller.consumeBoostRequest();
    expect(await controller.boostProfile(), isTrue);

    expect(api.boostKeys, <String>[
      'flutter:boost-activation:test-key-1',
      'flutter:boost-activation:test-key-2',
    ]);
  });

  test('rapid boost taps issue only one request', () async {
    final first = controller.boostProfile();
    final repeated = controller.boostProfile();

    expect(await repeated, isFalse);
    expect(await first, isTrue);
    expect(api.boostKeys, hasLength(1));
  });

  test('definitive Boost rejection does not show fake success', () async {
    api
      ..failNextBoost = true
      ..failureStatusCode = 402
      ..failureMessage = 'A boost entitlement is required.';

    expect(await controller.boostProfile(), isFalse);
    expect(controller.boostRequested, isFalse);
    expect(controller.boostState, isNull);
    expect(controller.lastError, contains('entitlement'));
    expect(controller.boostIdempotencyKey, isNull);
  });

  test('deck exposes a polished empty state condition', () async {
    await controller.passProfile();
    await controller.passProfile();
    await controller.passProfile();
    expect(controller.isEmpty, isTrue);
    expect(controller.currentProfileId, isNull);
  });
}
