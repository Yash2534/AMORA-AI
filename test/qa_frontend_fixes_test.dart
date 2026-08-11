import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/floating_ai_assistant.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_setup_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_form.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AmoraSession.logIn);
  tearDown(AmoraSession.logOut);

  testWidgets('Edit Profile opens an editable route and saves local fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          ProfileScreen.routeName: (_) => const ProfileScreen(),
          ProfileEditScreen.routeName: (_) => const ProfileEditScreen(),
          SubscriptionScreen.routeName: (_) => const SubscriptionScreen(),
        },
        initialRoute: ProfileScreen.routeName,
      ),
    );
    await tester.pump();

    await Scrollable.ensureVisible(
      tester.element(find.text('Edit Profile').first),
      alignment: .3,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('Profile completion opens without a duplicate preview card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          ProfileCompletionScreen.routeName: (_) =>
              const ProfileCompletionScreen(),
          ProfileSetupScreen.routeName: (_) => const ProfileSetupScreen(),
        },
        home: const ProfileScreen(),
      ),
    );
    await tester.pump();

    final completionCard = find.byKey(
      const ValueKey('profile-completion-card'),
    );
    await tester.scrollUntilVisible(
      completionCard,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final completionAction = find.descendant(
      of: completionCard,
      matching: find.byType(InkWell),
    );
    tester.widget<InkWell>(completionAction.first).onTap?.call();
    await tester.pumpAndSettle();
    expect(find.byType(AmoraaProfileForm), findsNothing);
    expect(find.text('Profile Completion'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Profile Photos'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile Photos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Back to Profile'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Back to Profile'), findsOneWidget);
    expect(find.text('Preview profile'), findsNothing);
  });

  testWidgets('AI assistant sheet scrolls at compact phone height', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(body: FloatingAiAssistant()),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('AMORAA Assistant'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Conversation Analysis'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Conversation Analysis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Events failure state survives large text on narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          theme: AmoraTheme.light(),
          home: const EventsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Unlock Events'), findsNothing);
    expect(find.text('View Membership'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Advanced Filter reset and active chip use shared tokens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const AdvancedFiltersScreen(),
      ),
    );
    expect(find.text('Reset'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: AmoraFilterChip(
            label: 'Verified',
            selected: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.selectedColor, AppColors.active);
  });

  test('profile completion and avatar update from local repository', () {
    final repository = LocalProfileRepository.instance;
    final before = repository.profile;
    final updated = before.copyWith(
      name: 'QA Profile',
      photos: const ['assets/images/profiles/male/male_11.jpg'],
      primaryPhotoIndex: 0,
    );
    repository.save(updated);
    expect(repository.profile.name, 'QA Profile');
    expect(repository.profile.primaryPhoto, contains('male_11.jpg'));
    repository.save(before);
  });
}
