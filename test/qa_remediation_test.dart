import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/profile/presentation/widgets/profile_attribute_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('event distance rendering only accepts numeric kilometre values', () {
    final base = events.first;
    EventModel copyWithDistance(String distance) => EventModel(
      id: base.id,
      title: base.title,
      category: base.category,
      city: base.city,
      date: base.date,
      time: base.time,
      price: base.price,
      seatsLeft: base.seatsLeft,
      compatibility: base.compatibility,
      image: base.image,
      organizer: base.organizer,
      venue: base.venue,
      distance: distance,
      dressCode: base.dressCode,
      ageRange: base.ageRange,
      language: base.language,
      palette: base.palette,
      intent: base.intent,
      interests: base.interests,
    );

    expect(copyWithDistance('46 km away').hasNumericDistance, isTrue);
    expect(copyWithDistance('Curated venue').hasNumericDistance, isFalse);
  });

  test('profile attribute icons match their displayed meaning', () {
    expect(ProfileAttributeIcons.smoking('Yes'), Icons.smoking_rooms_rounded);
    expect(ProfileAttributeIcons.smoking('Never'), Icons.smoke_free_rounded);
    expect(
      ProfileAttributeIcons.interest('Photography'),
      Icons.photo_camera_outlined,
    );
    expect(ProfileAttributeIcons.interest('Dogs'), Icons.pets_rounded);
    expect(ProfileAttributeIcons.pronouns, Icons.person_outline_rounded);
  });

  testWidgets(
    'shared filter rail protects complete labels at the scroll edge',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: Scaffold(
            body: AmoraaHorizontalFilterBar<String>(
              options: const ['Most Compatible', 'Verified'],
              selectedValues: const {},
              multiSelect: false,
              labelBuilder: (value) => value,
              optionKeyPrefix: 'qa-filter',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('qa-filter-scroll')),
      );
      expect(list.padding, const EdgeInsets.only(right: 20));
      expect(find.text('Most Compatible'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
