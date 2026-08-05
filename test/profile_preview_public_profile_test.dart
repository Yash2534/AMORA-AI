import 'dart:convert';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = LocalProfileRepository.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await repository.resetForTesting(_profileFixture());
    repository.addPhotoInSession(
      _localPhoto,
      bytes: _localPhotoBytes,
      mimeType: 'image/png',
    );
    repository.setPrimaryPhotoInSession(repository.profile.photos.length - 1);
  });

  tearDown(() async {
    await repository.resetForTesting();
  });

  test('public profile projection uses shared approved display mappings', () {
    final data = AmoraaPublicProfileData.fromProfile(
      repository.profile,
      repository.currentPhotos,
    );

    expect(data.city, 'Ahmedabad');
    expect(data.gender, 'Female');
    expect(data.education, 'Undergraduate');
    expect(data.occupation, 'Software Engineer');
    expect(data.datingIntention, 'Long-Term Relationship');
    expect(data.datingType, 'Coffee Dates');
    expect(data.height, '5\'5" · 165 cm');
    expect(data.languages, ['English', 'Hindi', 'Gujarati']);
    expect(data.religion, 'Hindu');
    expect(data.interests, ['Coffee', 'Heritage walks']);
    expect(data.interests, isNot(contains('Technology')));
    expect(data.primaryPhoto.source, _localPhoto);
    expect(data.additionalPhotos.map((photo) => photo.source), [
      AppImages.profileYash,
      'assets/images/profiles/female/female_02.jpg',
    ]);
    final display = data.toPublicDisplayProfile();
    expect(display.city, data.city);
    expect(display.education, data.education);
    expect(display.languages, data.languages);
    expect(display.intent, data.datingIntention);
    expect(
      display.promptAnswers,
      Map<String, String>.fromEntries(data.prompts),
    );
  });

  testWidgets('existing named Profile Preview route opens correctly', (
    tester,
  ) async {
    expect(ProfilePreviewScreen.routeName, '/profile-preview');
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        initialRoute: ProfilePreviewScreen.routeName,
        routes: {
          ProfilePreviewScreen.routeName: (_) => const ProfilePreviewScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfilePreviewScreen), findsOneWidget);
  });

  testWidgets('Detail and Preview share one ordered public presentation', (
    tester,
  ) async {
    const commonSections = <String>[
      'public-profile-section-quick-facts',
      'public-profile-section-about',
      'public-profile-section-relationship',
      'public-profile-section-lifestyle',
      'public-profile-section-interests',
      'public-profile-section-prompts',
    ];
    final viewedProfile = ImageRepository.profileAt(3);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: ProfileDetailScreen(profile: viewedProfile),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AmoraaPublicProfileView>(find.byType(AmoraaPublicProfileView))
          .mode,
      PublicProfileViewMode.otherUser,
    );
    expect(find.byType(ProfileMediaGallery), findsOneWidget);
    expect(find.byType(AmoraaProfilePhotoView), findsWidgets);
    expect(find.byType(ProfileStory), findsOneWidget);
    expect(find.byType(ProfileAboutSection), findsOneWidget);
    expect(find.byType(RelationshipIntentionsSection), findsOneWidget);
    expect(find.byType(LifestyleGrid), findsOneWidget);
    expect(find.byType(ProfilePromptCard), findsWidgets);
    expect(find.byType(ProfileActionBar), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-report-button')), findsOneWidget);
    expect(
      find.textContaining('${viewedProfile.name.split(' ').first},'),
      findsOneWidget,
    );
    expect(_sectionOrder(tester, commonSections), commonSections);

    await _pumpPreview(tester, const Size(390, 844));
    expect(
      tester
          .widget<AmoraaPublicProfileView>(find.byType(AmoraaPublicProfileView))
          .mode,
      PublicProfileViewMode.preview,
    );
    expect(find.byType(ProfileMediaGallery), findsOneWidget);
    expect(find.byType(AmoraaProfilePhotoView), findsWidgets);
    expect(find.byType(ProfileStory), findsOneWidget);
    expect(find.byType(ProfileAboutSection), findsOneWidget);
    expect(find.byType(RelationshipIntentionsSection), findsOneWidget);
    expect(find.byType(LifestyleGrid), findsOneWidget);
    expect(find.byType(ProfilePromptCard), findsWidgets);
    expect(find.byType(ProfileActionBar), findsNothing);
    expect(find.text('Priya, 28'), findsOneWidget);
    expect(_sectionOrder(tester, commonSections), commonSections);
  });

  testWidgets('preview is a complete public profile, not an edit form', (
    tester,
  ) async {
    await _pumpPreview(tester, const Size(390, 844));

    expect(find.text('Profile Preview'), findsOneWidget);
    expect(find.byType(AmoraaPublicProfileView), findsOneWidget);
    expect(find.byType(ProfileMediaGallery), findsOneWidget);
    expect(find.byType(ProfileStory), findsOneWidget);
    expect(
      tester
          .widget<AmoraaPublicProfileView>(find.byType(AmoraaPublicProfileView))
          .mode,
      PublicProfileViewMode.preview,
    );
    expect(find.text('Priya, 28'), findsOneWidget);
    expect(find.text('Ahmedabad'), findsOneWidget);
    expect(find.text('Long-Term Relationship'), findsOneWidget);
    expect(find.text('Coffee Dates'), findsOneWidget);
    expect(find.text('Undergraduate'), findsOneWidget);
    expect(find.text('English · Hindi · Gujarati'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Weed'), findsOneWidget);
    expect(find.text('Prefer not to say'), findsOneWidget);

    expect(find.byType(ProfilePromptCard), findsNWidgets(2));
    final firstPrompt = tester.getTopLeft(find.byType(ProfilePromptCard).at(0));
    final secondPrompt = tester.getTopLeft(
      find.byType(ProfilePromptCard).at(1),
    );
    expect(secondPrompt.dy, greaterThan(firstPrompt.dy));

    final photoViews = tester.widgetList<AmoraaProfilePhotoView>(
      find.byType(AmoraaProfilePhotoView),
    );
    expect(photoViews.first.photo.source, _localPhoto);
    expect(
      photoViews.where((view) => view.photo.source == _localPhoto),
      hasLength(1),
    );
    expect(find.textContaining('Ahmedabad'), findsOneWidget);
    expect(find.text('Long-Term Relationship'), findsOneWidget);
    expect(find.text('Technology'), findsNothing);
    expect(find.text('Children'), findsNothing);
    expect(find.text('Voice Introduction'), findsNothing);
    expect(find.byKey(const ValueKey('profile-like-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('profile-super-like-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('profile-message-button')), findsNothing);
    expect(find.byKey(const ValueKey('profile-gift-button')), findsNothing);
    expect(find.byKey(const ValueKey('profile-save-button')), findsNothing);
    expect(find.byKey(const ValueKey('profile-block-button')), findsNothing);
    expect(find.byKey(const ValueKey('profile-report-button')), findsNothing);
    expect(find.text('Reply'), findsNothing);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved profile and photo changes update preview immediately', (
    tester,
  ) async {
    await _pumpPreview(tester, const Size(390, 844));

    final current = repository.profile;
    repository.save(
      current.copyWith(
        location: 'Surat',
        education: 'Master\'s Degree',
        gender: 'Man',
        datingIntention: 'Marriage',
        bio: 'A newly saved public biography.',
        prompts: const {
          'Together we could...': 'Plan a thoughtful weekend escape.',
        },
        lifestyle: {
          ...current.lifestyle,
          'Languages': 'Gujarati & English',
          'Drinking': 'Sometimes',
          'Weed': 'Never',
        },
        photos: [
          'assets/images/profiles/female/female_02.jpg',
          _localPhoto,
          AppImages.profileYash,
        ],
        primaryPhotoIndex: 0,
      ),
    );
    await tester.pump();

    expect(find.text('Priya, 28'), findsOneWidget);
    expect(find.text('Surat'), findsOneWidget);
    expect(find.text('Postgraduate'), findsOneWidget);
    expect(find.text('Marriage Minded'), findsOneWidget);
    expect(find.text('A newly saved public biography.'), findsOneWidget);
    expect(
      find.textContaining('Plan a thoughtful weekend escape.'),
      findsOneWidget,
    );
    expect(find.text('Gujarati · English'), findsOneWidget);
    expect(find.text('Sometimes'), findsOneWidget);
    expect(find.text('Weed'), findsOneWidget);
    expect(find.text('Never'), findsOneWidget);
    expect(find.text('Ahmedabad'), findsNothing);
    expect(find.text('Undergraduate'), findsNothing);

    final photoViews = tester.widgetList<AmoraaProfilePhotoView>(
      find.byType(AmoraaProfilePhotoView),
    );
    expect(
      photoViews.first.photo.source,
      'assets/images/profiles/female/female_02.jpg',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty public values do not render blank public rows', (
    tester,
  ) async {
    await repository.resetForTesting(
      _profileFixture().copyWith(
        bio: '',
        profession: '',
        company: '',
        education: '',
        gender: '',
        datingIntention: '',
        interests: const [],
        prompts: const {},
        lifestyle: const {},
      ),
    );
    await _pumpPreview(tester, const Size(320, 640));

    expect(
      find.byKey(const ValueKey('public-profile-section-about')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('public-profile-section-prompts')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('public-profile-section-interests')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('public-profile-section-lifestyle')),
      findsNothing,
    );
    expect(find.text('null'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public profile remains responsive at supported widths', (
    tester,
  ) async {
    final viewedProfile = ImageRepository.profileAt(7);
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      await _pumpPreview(
        tester,
        Size(width, width >= 600 ? 900 : 760),
        textScale: width == 320 ? 1.3 : 1,
      );
      expect(
        find.byType(AmoraaPublicProfileView),
        findsOneWidget,
        reason: '$width px',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Profile Preview overflowed at $width px',
      );
      final previewWidth = tester
          .getSize(find.byType(AmoraaPublicProfileView))
          .width;
      expect(find.byType(ProfileActionBar), findsNothing);

      await _pumpDetail(
        tester,
        viewedProfile,
        Size(width, width >= 600 ? 900 : 760),
        textScale: width == 320 ? 1.3 : 1,
      );
      expect(
        tester.getSize(find.byType(AmoraaPublicProfileView)).width,
        previewWidth,
      );
      expect(find.byType(ProfileActionBar), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Profile Detail overflowed at $width px',
      );
    }
  });
}

List<String> _sectionOrder(WidgetTester tester, List<String> keys) {
  final positions = <(String, double)>[
    for (final key in keys)
      (key, tester.getTopLeft(find.byKey(ValueKey(key))).dy),
  ]..sort((left, right) => left.$2.compareTo(right.$2));
  return positions.map((entry) => entry.$1).toList(growable: false);
}

Future<void> _pumpPreview(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AmoraTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const ProfilePreviewScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDetail(
  WidgetTester tester,
  DummyProfile profile,
  Size size, {
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AmoraTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ProfileDetailScreen(profile: profile),
    ),
  );
  await tester.pumpAndSettle();
}

UserProfile _profileFixture() => const UserProfile(
  name: 'Priya Shah',
  email: 'priya@example.com',
  phoneNumber: '+91 90000 00000',
  birthdate: '04/08/1998',
  gender: 'Woman',
  bio: 'Warm, curious, and happiest over a long conversation.',
  profession: 'Flutter Engineer',
  company: 'AMORAA Studio',
  education: 'B.Tech',
  location: 'Ahemdabad',
  datingIntention: 'Serious',
  interests: ['Coffee Dates', 'Heritage Walks', 'Technology'],
  prompts: {
    'My ideal Sunday is...': 'A slow breakfast and a long walk.',
    'Together we could...': 'Find the best coffee in the city.',
  },
  lifestyle: {
    'Type of Dating': 'Coffee Dates',
    'Height': '5\'5" · 165 cm',
    'Languages': 'English, Hindi & Gujarati',
    'Religion': 'Hindu',
    'Drinking': 'Yes',
    'Smoking': 'No',
    'Weed': 'Prefer not to say',
    'Exercise': 'Daily',
  },
  photos: [
    AppImages.profileYash,
    'assets/images/profiles/female/female_02.jpg',
  ],
  primaryPhotoIndex: 0,
  voicePrompt: null,
  videoPrompt: null,
);

const _localPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
final _localPhotoBytes = base64Decode(_localPhoto.split(',').last);
