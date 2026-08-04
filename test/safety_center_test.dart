import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/legal/presentation/community_guidelines_screen.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject({
    required ProfileRelationshipController controller,
    Size size = const Size(390, 844),
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          BlockedProfilesScreen.routeName: (_) =>
              const Scaffold(body: Center(child: Text('Blocked destination'))),
          CommunityGuidelinesScreen.routeName: (_) => const Scaffold(
            body: Center(child: Text('Guidelines destination')),
          ),
          FaqSupportScreen.routeName: (_) =>
              const Scaffold(body: Center(child: Text('Support destination'))),
        },
        home: SafetyPrivacyScreen(relationshipController: controller),
      ),
    );
  }

  test('Safety Center keeps its existing route', () {
    expect(SafetyPrivacyScreen.routeName, '/safety-center');
  });

  testWidgets('shows truthful unavailable state without dummy claims', (
    tester,
  ) async {
    final controller = ProfileRelationshipController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller: controller));

    expect(find.text('Safety Center'), findsOneWidget);
    expect(find.text('Identity status'), findsOneWidget);
    expect(find.text('Privacy controls unavailable'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('safety-emergency-unavailable')),
      300,
    );
    expect(find.text('Emergency tools unavailable'), findsOneWidget);
    expect(find.text('Fully Protected'), findsNothing);
    expect(find.text('98% Safe'), findsNothing);
    expect(find.text('Identity Verified'), findsNothing);
    expect(find.text('Aadhya'), findsNothing);
    expect(find.textContaining('Aadhaar number'), findsNothing);
    expect(find.textContaining('Document ID'), findsNothing);
  });

  testWidgets('omits the identity verification section and its spacing', (
    tester,
  ) async {
    final controller = ProfileRelationshipController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller: controller));

    expect(find.text('Identity verification'), findsNothing);
    expect(find.text('Aadhaar & selfie verification'), findsNothing);
    expect(
      find.text(
        'Aadhaar and selfie checks are completed together in the existing secure flow.',
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('safety-identity-verification')),
      findsNothing,
    );
    expect(find.text('Verified Profile'), findsNothing);
    expect(find.text('Face Verification'), findsNothing);
    expect(find.text('Photo Verification'), findsNothing);

    final overviewBottom = tester.getBottomLeft(
      find.byKey(const ValueKey('safety-overview')),
    );
    final privacyTop = tester.getTopLeft(find.text('Privacy & visibility'));
    expect(privacyTop.dy - overviewBottom.dy, 24);
  });

  testWidgets('blocked profile count comes from shared user-driven state', (
    tester,
  ) async {
    final controller = ProfileRelationshipController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller: controller));
    final count = find.byKey(const ValueKey('safety-blocked-count'));
    expect(
      find.descendant(of: count, matching: find.text('0')),
      findsOneWidget,
    );

    final profile = ImageRepository.profileAt(0);
    controller.blockProfile(profile);
    controller.blockProfile(profile);
    await tester.pump();

    expect(
      find.descendant(of: count, matching: find.text('1')),
      findsOneWidget,
    );
    expect(controller.blockedProfileIds, hasLength(1));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('safety-blocked-profiles')),
      240,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('safety-blocked-profiles')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('safety-blocked-profiles')));
    await tester.pumpAndSettle();
    expect(find.text('Blocked destination'), findsOneWidget);
  });

  testWidgets('unsupported report and emergency actions are absent', (
    tester,
  ) async {
    final controller = ProfileRelationshipController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller: controller));

    expect(find.text('Report a Problem'), findsNothing);
    expect(find.text('Report a Safety Concern'), findsNothing);
    expect(find.text('Emergency Contact & Check-in'), findsNothing);
    expect(find.text('SOS'), findsNothing);
    expect(find.byKey(const ValueKey('safety-report')), findsNothing);
    expect(
      find.byKey(const ValueKey('safety-emergency-contact')),
      findsNothing,
    );
  });

  testWidgets('guidance uses expandable approved safety copy', (tester) async {
    final controller = ProfileRelationshipController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller: controller));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('safety-guidance-privacy')),
      300,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('safety-guidance-privacy')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('safety-guidance-privacy')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Do not share account credentials'),
      findsOneWidget,
    );
  });

  testWidgets('remains overflow-free at 320 px', (tester) async {
    final controller = ProfileRelationshipController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      subject(controller: controller, size: const Size(320, 640)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Safety Center'), findsOneWidget);
  });
}
