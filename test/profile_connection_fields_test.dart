import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_connection_profile_details.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_preference_selectors.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = LocalProfileRepository.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await repository.resetForTesting(_profile());
  });

  tearDown(() async => repository.resetForTesting());

  Widget app(Widget home) => MaterialApp(theme: AmoraTheme.light(), home: home);

  test('communication style is a stable six-option source of truth', () {
    expect(CommunicationStyle.values.map((style) => style.label), const [
      'Frequent texting',
      'Occasional texting',
      'Calls',
      'Voice notes',
      'Deep conversations',
      'Light/fun conversations',
    ]);
    expect(
      CommunicationStyle.deepConversations.storageValue,
      'deep_conversations',
    );
    expect(
      UserProfile.fromJson(_profile().toJson()).communicationStyle,
      CommunicationStyle.deepConversations,
    );
  });

  testWidgets(
    'Edit Profile offers the Ice Breaker and communication selector',
    (tester) async {
      await tester.pumpWidget(app(const ProfileEditScreen()));
      await tester.pumpAndSettle();

      final iceBreaker = find.byKey(
        const ValueKey('profile-ice-breaker-field'),
      );
      expect(iceBreaker, findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-communication-style-selector')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shared editor enforces the Ice Breaker limit and selects one communication style',
    (tester) async {
      final controller = ProfileFormController(repository: repository);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: AmoraaConnectionPreferencesEditor(controller: controller),
            ),
          ),
        ),
      );
      final iceBreaker = find.byKey(
        const ValueKey('profile-ice-breaker-field'),
      );
      await tester.enterText(iceBreaker, '${List.filled(179, 'x').join()}\nY');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(iceBreaker).controller!.text.length,
        180,
      );
      expect(find.text('180/180'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('profile-communication-style-selector')),
      );
      await tester.pumpAndSettle();
      for (final style in CommunicationStyle.values) {
        expect(find.text(style.label), findsWidgets);
      }
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();
      expect(controller.communicationStyle, CommunicationStyle.calls);
    },
  );

  testWidgets(
    'Profile Completion keeps the new fields optional without changing completion work',
    (tester) async {
      await tester.pumpWidget(app(const ProfileCompletionScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileCompletionScreen), findsOneWidget);
      expect(repository.profile.pendingFields, isNotEmpty);
    },
  );

  testWidgets(
    'Preview and Profile Detail show saved connection fields and hide an empty display',
    (tester) async {
      await tester.pumpWidget(app(const ProfilePreviewScreen()));
      await tester.pumpAndSettle();
      expect(find.text(_profile().iceBreaker), findsOneWidget);
      expect(find.text('Deep conversations'), findsOneWidget);

      final publicData = AmoraaPublicProfileData.fromProfile(
        repository.profile,
        repository.currentPhotos,
      );
      await tester.pumpWidget(
        app(ProfileDetailScreen(profile: publicData.toPublicDisplayProfile())),
      );
      await tester.pumpAndSettle();
      expect(find.text(_profile().iceBreaker), findsOneWidget);
      expect(find.text('Deep conversations'), findsOneWidget);

      await tester.pumpWidget(
        app(
          const Scaffold(
            body: AmoraaConnectionProfileDetails(
              iceBreaker: '',
              communicationStyle: null,
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('public-profile-section-connection-style')),
        findsNothing,
      );
    },
  );
}

UserProfile _profile() => const UserProfile(
  name: 'Priya Shah',
  email: 'priya@example.com',
  phoneNumber: '+91 90000 00000',
  birthdate: '04/08/1998',
  gender: 'Woman',
  bio: 'Warm, curious, and happiest over a long conversation.',
  profession: 'Designer',
  company: 'AMORAA',
  education: 'B.Tech',
  location: 'Ahmedabad',
  datingIntention: 'Serious',
  interests: ['Coffee Dates'],
  prompts: {'My ideal Sunday is...': 'A slow breakfast and a long walk.'},
  lifestyle: {'Height': '165', 'Languages': 'English', 'Religion': 'Hindu'},
  photos: [],
  primaryPhotoIndex: 0,
  iceBreaker:
      'Communication matters to me — disappearing during conflict is a dealbreaker.',
  communicationStyle: CommunicationStyle.deepConversations,
);
