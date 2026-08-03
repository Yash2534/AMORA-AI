import 'dart:convert';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
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

  testWidgets('preview is a complete public profile, not an edit form', (
    tester,
  ) async {
    await _pumpPreview(tester, const Size(390, 844));

    expect(find.text('Profile Preview'), findsOneWidget);
    expect(
      find.text('See how your profile appears to others.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('public-profile-details')),
      findsOneWidget,
    );
    expect(find.text('Priya Shah'), findsOneWidget);
    expect(find.text('28 · Ahmedabad'), findsOneWidget);
    expect(find.text('Long-Term Relationship'), findsOneWidget);
    expect(find.text('Coffee Dates'), findsOneWidget);
    expect(find.text('Undergraduate'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('English · Hindi · Gujarati'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);
    expect(find.text('Not verified'), findsOneWidget);

    expect(find.byKey(const ValueKey('preview-prompt-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('preview-prompt-1')), findsOneWidget);
    final firstPrompt = tester.getTopLeft(
      find.byKey(const ValueKey('preview-prompt-0')),
    );
    final secondPrompt = tester.getTopLeft(
      find.byKey(const ValueKey('preview-prompt-1')),
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
    expect(find.text('Save'), findsNothing);
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

    expect(find.text('28 · Surat'), findsOneWidget);
    expect(find.text('Postgraduate'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Marriage Minded'), findsOneWidget);
    expect(find.text('A newly saved public biography.'), findsOneWidget);
    expect(
      find.textContaining('Plan a thoughtful weekend escape.'),
      findsOneWidget,
    );
    expect(find.text('Gujarati · English'), findsOneWidget);
    expect(find.text('Sometimes'), findsOneWidget);
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

    expect(find.byKey(const ValueKey('preview-bio-section')), findsNothing);
    expect(find.byKey(const ValueKey('preview-prompts-section')), findsNothing);
    expect(
      find.byKey(const ValueKey('preview-interests-section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('preview-lifestyle-section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('preview-work-education-section')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('preview-personal-details-section')),
      findsNothing,
    );
    expect(find.text('null'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public profile remains responsive at supported widths', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      await _pumpPreview(
        tester,
        Size(width, width >= 600 ? 900 : 760),
        textScale: width == 320 ? 1.3 : 1,
      );
      expect(
        find.byKey(const ValueKey('public-profile-details')),
        findsOneWidget,
        reason: '$width px',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Profile Preview overflowed at $width px',
      );
    }
  });
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
