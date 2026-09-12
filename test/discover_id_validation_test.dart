import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Discover Target User ID Validation Tests', () {
    test('publicProfileFromJson correctly maps id from id, userId, user_id, and _id', () {
      final res1 = publicProfileFromJson({'id': 123, 'name': 'Test User'});
      expect(res1.profile.id, '123');

      final res2 = publicProfileFromJson({'userId': '456', 'name': 'Test User 2'});
      expect(res2.profile.id, '456');

      final res3 = publicProfileFromJson({'user_id': 789, 'name': 'Test User 3'});
      expect(res3.profile.id, '789');

      final res4 = publicProfileFromJson({'_id': '101112', 'name': 'Test User 4'});
      expect(res4.profile.id, '101112');
    });

    test('All ImageRepository profiles have valid positive integer IDs', () {
      expect(ImageRepository.profiles, isNotEmpty);
      for (final profile in ImageRepository.profiles) {
        final parsedId = int.tryParse(profile.id);
        expect(parsedId, isNotNull, reason: 'Profile ID ${profile.id} for ${profile.name} must be numeric integer string');
        expect(parsedId! > 0, isTrue, reason: 'Profile ID ${profile.id} must be >= 1');
      }
    });

    test('DiscoverApiService.swipe rejects invalid non-numeric targetUserId locally', () async {
      final service = DiscoverApiService();

      final res1 = await service.swipe(targetUserId: 'female-1', action: 'like');
      expect(res1.success, isFalse);
      expect(res1.message, 'Unable to process this profile right now. Please try again.');
      expect(res1.statusCode, 400);

      final res2 = await service.swipe(targetUserId: '', action: 'pass');
      expect(res2.success, isFalse);
      expect(res2.message, 'Unable to process this profile right now. Please try again.');
      expect(res2.statusCode, 400);

      final res3 = await service.swipe(targetUserId: '-5', action: 'superLike');
      expect(res3.success, isFalse);
      expect(res3.message, 'Unable to process this profile right now. Please try again.');
      expect(res3.statusCode, 400);
    });
  });
}
