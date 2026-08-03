import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_story_image.dart';
import 'package:amora_ai/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = LocalProfileRepository.instance;
  late UserProfile originalProfile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalProfile = repository.profile;
    await repository.resetForTesting(originalProfile);
  });

  tearDown(() async {
    await repository.resetForTesting(originalProfile);
  });

  test('profile-completion hash resolves to the dedicated route', () {
    expect(
      app.resolveAmoraInitialRoute('#/profile-completion'),
      ProfileCompletionScreen.routeName,
    );
    expect(
      app.resolveAmoraInitialRoute('/#/profile-completion'),
      ProfileCompletionScreen.routeName,
    );
  });

  testWidgets('resolved profile-completion route renders a loaded page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        initialRoute: app.resolveAmoraInitialRoute('#/profile-completion'),
        routes: {
          ProfileCompletionScreen.routeName: (_) =>
              const ProfileCompletionScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProfileCompletionScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('completion-progress-header')),
      findsOneWidget,
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Edit Profile opens Photo Manager', (tester) async {
    await _pump(
      tester,
      const ProfileEditScreen(),
      routes: {
        PhotoManagerScreen.routeName: (_) => const PhotoManagerScreen(),
        ProfilePreviewScreen.routeName: (_) => const ProfilePreviewScreen(),
      },
    );

    await tester.tap(find.text('Manage photos'));
    await tester.pumpAndSettle();
    expect(find.text('Photo Manager'), findsOneWidget);
  });

  testWidgets('local photo synchronizes immediately with Profile', (
    tester,
  ) async {
    await _pump(tester, const ProfileScreen(showNavigation: false));
    repository.addPhotoInSession(_localPhoto);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-horizontal-photo-gallery')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<AmoraProfileImage>(find.byType(AmoraProfileImage))
          .where((image) => image.imageUrl == _localPhoto),
      isNotEmpty,
    );
  });

  testWidgets('Profile Preview listens to the same live photo collection', (
    tester,
  ) async {
    await _pump(tester, const ProfilePreviewScreen());
    repository.addPhotoInSession(_localPhoto);
    repository.setPrimaryPhotoInSession(repository.profile.photos.length - 1);
    await tester.pump();

    final stories = tester.widgetList<AmoraaProfileStoryImage>(
      find.byType(AmoraaProfileStoryImage),
    );
    expect(stories.first.image, _localPhoto);
    expect(stories.where((story) => story.image == _localPhoto), hasLength(1));
  });

  test('primary, reorder, and delete update the shared collection', () {
    repository.addPhotoInSession(_localPhoto);
    final addedIndex = repository.profile.photos.length - 1;
    repository.setPrimaryPhotoInSession(addedIndex);
    expect(repository.profile.primaryPhoto, _localPhoto);

    repository.reorderPhotosInSession(addedIndex, 0);
    expect(repository.profile.photos.first, _localPhoto);
    expect(repository.profile.primaryPhotoIndex, 0);

    repository.removePhotoInSession(0);
    expect(repository.profile.photos, isNot(contains(_localPhoto)));
    expect(repository.currentPhotos.length, repository.profile.photos.length);
  });

  test('remote and local photos coexist with distinct frontend states', () {
    final profile = originalProfile.copyWith(
      photos: const ['https://images.example/profile.jpg', _localPhoto],
      primaryPhotoIndex: 0,
    );
    repository.save(profile);

    expect(repository.currentPhotos, hasLength(2));
    expect(
      repository.currentPhotos.first.uploadState,
      ProfilePhotoUploadState.uploaded,
    );
    expect(
      repository.currentPhotos.last.uploadState,
      ProfilePhotoUploadState.localOnly,
    );
  });

  testWidgets('every Photo Manager tile opens the full preview', (
    tester,
  ) async {
    await _pump(tester, const PhotoManagerScreen());
    final ids = repository.currentPhotos.map((photo) => photo.id).toList();

    for (final id in ids) {
      await tester.tap(find.byKey(ValueKey(id)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo-full-preview')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('photo-preview-close')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('upload failure keeps the local preview and exposes Retry', (
    tester,
  ) async {
    final picker = _FakePhotoPicker();
    await _pump(
      tester,
      PhotoManagerScreen(
        mediaPicker: picker,
        cropPreviewRenderer: (_) async => _localPhoto,
        photoUploader: (_) async => throw StateError('offline'),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_photo_alternate_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from photo library'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-crop-review-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-crop-use-button')));
    await tester.pumpAndSettle();

    final localEntry = repository.currentPhotos.singleWhere(
      (photo) => photo.source == _localPhoto,
    );
    expect(localEntry.uploadState, ProfilePhotoUploadState.failed);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      tester
          .widgetList<AmoraProfileImage>(find.byType(AmoraProfileImage))
          .where((image) => image.imageUrl == _localPhoto),
      isNotEmpty,
    );
  });

  testWidgets('Photo Manager grid remains usable at supported widths', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      await _pump(
        tester,
        PhotoManagerScreen(key: UniqueKey()),
        size: Size(width, width >= 600 ? 900 : 700),
      );
      expect(find.byKey(const ValueKey('profile-photo-grid')), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Photo Manager overflowed at $width px',
      );
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(390, 844),
  Map<String, WidgetBuilder> routes = const {},
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(theme: AmoraTheme.light(), routes: routes, home: home),
  );
  await tester.pumpAndSettle();
}

const _localPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

class _FakePhotoPicker implements AmoraMediaPicker {
  @override
  Future<bool> openSettings() async => true;

  @override
  Future<AmoraMediaPickResult> pickImage({
    required AmoraMediaSource source,
  }) async => const AmoraMediaPickResult.success(
    AmoraPickedMedia(dataUri: _localPhoto, name: 'local.png', byteLength: 68),
  );
}
