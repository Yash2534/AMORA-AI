import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Discover Target User ID Validation Tests', () {
    test('publicProfileFromJson maps only the canonical backend id', () {
      final res1 = publicProfileFromJson({'id': 123, 'name': 'Test User'});
      expect(res1.profile.id, '123');

      final res2 = publicProfileFromJson({
        'userId': '456',
        'name': 'Test User 2',
      });
      expect(res2.profile.id, isEmpty);

      final res3 = publicProfileFromJson({
        'user_id': 789,
        'name': 'Test User 3',
      });
      expect(res3.profile.id, isEmpty);

      final res4 = publicProfileFromJson({
        '_id': '101112',
        'name': 'Test User 4',
      });
      expect(res4.profile.id, isEmpty);
    });

    test('local demo profile IDs remain unique opaque fixture identities', () {
      expect(ImageRepository.profiles, isNotEmpty);
      final ids = ImageRepository.profiles
          .map((profile) => profile.id)
          .toList();
      expect(ids.every((id) => id.trim().isNotEmpty), isTrue);
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
