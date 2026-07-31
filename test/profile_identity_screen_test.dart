import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalProfileDraft original;

  setUp(() {
    original = LocalProfileRepository.instance.profile;
  });

  tearDown(() {
    LocalProfileRepository.instance.save(original);
  });

  testWidgets('profile is an identity-first story at compact phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileScreen(showNavigation: false),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(child: Text('${settings.name} destination')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My dating identity'), findsOneWidget);
    expect(find.textContaining(original.name), findsOneWidget);
    expect(find.text('Aquarius'), findsWidgets);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-settings-button')), findsNothing);
    // Overflow assertions are checked after the responsive scroll pass below.

    final scrollable = find.byType(Scrollable).first;
    for (final section in [
      'Photo gallery',
      'Profile prompts',
      'Dating intentions',
      'Interests',
      'Personality',
      'Verification & trust',
      'Support',
      'Legal',
      'Log out',
      'Delete account',
    ]) {
      for (
        var attempt = 0;
        attempt < 16 && find.text(section).evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(scrollable, const Offset(0, -360));
        await tester.pumpAndSettle();
      }
      expect(find.text(section), findsWidgets);
    }

    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(find.textContaining('Create Ticket'), findsNothing);
    expect(find.textContaining('Phone Support'), findsNothing);
  });

  testWidgets('profile uses a centred responsive identity canvas on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileScreen(showNavigation: false),
      ),
    );
    await tester.pumpAndSettle();

    final scroll = find.byKey(
      const PageStorageKey<String>('main-profile-scroll'),
    );
    expect(tester.getSize(scroll).width, lessThanOrEqualTo(1040));
    expect(tester.getCenter(scroll).dx, moreOrLessEquals(640, epsilon: 1));
    expect(find.byType(ProfileHero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit profile saves through the existing local repository', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const ProfileEditScreen()),
    );
    await tester.pumpAndSettle();

    final existingVoicePrompt = original.voicePrompt;
    expect(
      find.textContaining(RegExp('voice introduction', caseSensitive: false)),
      findsNothing,
    );
    expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Updated AMORAA Member');
    await tester.tap(find.byKey(const ValueKey('profile-save-button')));
    await tester.pump(const Duration(milliseconds: 260));

    expect(
      LocalProfileRepository.instance.profile.name,
      'Updated AMORAA Member',
    );
    expect(
      LocalProfileRepository.instance.profile.voicePrompt,
      existingVoicePrompt,
    );
    expect(find.text('Profile changes saved'), findsOneWidget);
  });
}
