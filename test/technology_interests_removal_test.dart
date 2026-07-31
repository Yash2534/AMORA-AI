import 'dart:io';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/profile_card.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_metrics.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_section_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const retired = ['Flutter', 'Startups', 'Product design', 'Gaming'];
  const visible = ['Coffee', 'Cooking', 'Road trips', 'Yoga'];
  late UserProfile original;

  setUp(() {
    original = LocalProfileRepository.instance.profile;
  });

  tearDown(() {
    LocalProfileRepository.instance.save(original);
  });

  UserProfile legacyProfile() =>
      original.copyWith(interests: const [...visible, ...retired]);

  void expectRetiredInterestsAbsent() {
    expect(find.text('Technology'), findsNothing);
    for (final interest in retired) {
      expect(find.text(interest), findsNothing);
    }
  }

  test('retired values are invisible without being mutated', () {
    final stored = legacyProfile().interests;

    expect(ProfileInterestPolicy.visible(stored), visible);
    expect(ProfileInterestPolicy.visibleCount(stored), visible.length);
    expect(ProfileInterestPolicy.retired(stored), retired);
    expect(stored, const [...visible, ...retired]);
  });

  test('retired values do not contribute to either completion calculator', () {
    final fourVisible = original.copyWith(interests: visible);
    final fourVisibleWithLegacy = legacyProfile();
    final fiveVisible = original.copyWith(
      interests: const [...visible, 'Reading'],
    );

    expect(
      fourVisibleWithLegacy.presentationCompletionPercent,
      fourVisible.presentationCompletionPercent,
    );
    expect(
      fourVisibleWithLegacy.completionPercent,
      fourVisible.completionPercent,
    );
    expect(
      fiveVisible.presentationCompletionPercent,
      fourVisible.presentationCompletionPercent + 2,
    );
    expect(fiveVisible.completionPercent, fourVisible.completionPercent + 2);
  });

  testWidgets(
    'Interests editor removes the category and saves visible choices',
    (tester) async {
      LocalProfileRepository.instance.save(legacyProfile());
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: const ProfileSectionEditorScreen(
            section: ProfileSection.interests,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expectRetiredInterestsAbsent();
      expect(find.text('Lifestyle'), findsOneWidget);
      expect(find.text('Nature & pets'), findsOneWidget);
      expect(find.text('4/10 selected'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Reading'));
      await tester.pumpAndSettle();
      expect(find.text('5/10 selected'), findsOneWidget);

      await tester.tap(find.text('Save interests'));
      await tester.pumpAndSettle();

      final saved = LocalProfileRepository.instance.profile.interests;
      expect(saved, containsAll(const [...visible, 'Reading']));
      expect(saved, containsAll(retired));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Profile summary filters legacy Technology interests', (
    tester,
  ) async {
    LocalProfileRepository.instance.save(legacyProfile());
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileScreen(showNavigation: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Interests'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Coffee'), findsOneWidget);
    expectRetiredInterestsAbsent();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reusable profile cards filter legacy Technology interests', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: ProfileCard(
            profile: const AmoraProfileCardData(
              name: 'AMORAA Member',
              age: 28,
              city: 'Ahmedabad',
              distance: '4 km',
              score: 91,
              intent: 'Long-Term Relationship',
              imageUrl: '',
              interests: [...retired, 'Coffee'],
            ),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expectRetiredInterestsAbsent();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Complete, Edit, and Preview filter legacy values', (
    tester,
  ) async {
    LocalProfileRepository.instance.save(legacyProfile());
    await tester.binding.setSurfaceSize(const Size(390, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final screen in <Widget>[
      const ProfileCompletionScreen(),
      const ProfileEditScreen(),
      const ProfilePreviewScreen(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(theme: AmoraTheme.light(), home: screen),
      );
      await tester.pumpAndSettle();

      if (screen is ProfileCompletionScreen) {
        await tester.ensureVisible(find.text('Interests'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Interests'));
        await tester.pumpAndSettle();
      }

      final interestsHeading = screen is ProfilePreviewScreen
          ? find.text('Interests')
          : find.textContaining('Interests');
      expect(interestsHeading, findsOneWidget, reason: '${screen.runtimeType}');
      expect(find.text('Coffee'), findsOneWidget);
      expectRetiredInterestsAbsent();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('remaining interest categories stay responsive', (tester) async {
    LocalProfileRepository.instance.save(legacyProfile());
    for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
      await tester.binding.setSurfaceSize(
        Size(width, width >= 600 ? 900 : 760),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: const ProfileSectionEditorScreen(
            section: ProfileSection.interests,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expectRetiredInterestsAbsent();
      expect(find.text('Lifestyle'), findsOneWidget);
      expect(find.text('Nature & pets'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Overflow at $width px');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  test('Technology category is deleted rather than hidden', () {
    final source = File(
      'lib/features/profile/presentation/profile_section_editor_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("'Technology':")));
    expect(source, isNot(contains('Visibility(')));
    expect(source, isNot(contains('Offstage(')));
  });
}
