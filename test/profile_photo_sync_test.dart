import 'dart:async';
import 'dart:convert';

import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
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

  test('photo-manager hash resolves to the existing Photo Manager route', () {
    expect(
      app.resolveAmoraInitialRoute('#/photo-manager'),
      PhotoManagerScreen.routeName,
    );
    expect(
      app.resolveAmoraInitialRoute('/#/photo-manager'),
      PhotoManagerScreen.routeName,
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

  testWidgets('resolved photo-manager route renders the existing screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        initialRoute: app.resolveAmoraInitialRoute('#/photo-manager'),
        routes: {
          PhotoManagerScreen.routeName: (_) => const PhotoManagerScreen(),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PhotoManagerScreen), findsOneWidget);
    expect(find.text('Photo Manager'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-photo-grid')), findsOneWidget);
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

    final managePhotos = find.text('Manage photos');
    await tester.scrollUntilVisible(
      managePhotos,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(managePhotos);
    await tester.pumpAndSettle();
    expect(find.text('Photo Manager'), findsOneWidget);
  });

  testWidgets('Edit Profile Add Photo opens the shared picker flow', (
    tester,
  ) async {
    await _pump(tester, const ProfileEditScreen());

    final addPhoto = find.byKey(const ValueKey('profile-add-photo-action'));
    await tester.scrollUntilVisible(
      addPhoto,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(addPhoto);
    await tester.pumpAndSettle();

    expect(find.text('Photo Manager'), findsOneWidget);
    expect(find.text('Add a profile photo'), findsOneWidget);
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
          .widgetList<AmoraaProfilePhotoView>(
            find.byType(AmoraaProfilePhotoView),
          )
          .where((image) => image.photo.source == _localPhoto),
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

    final previewImages = tester.widgetList<AmoraaProfilePhotoView>(
      find.byType(AmoraaProfilePhotoView),
    );
    expect(previewImages.first.photo.source, _localPhoto);
    expect(
      previewImages.where((view) => view.photo.source == _localPhoto),
      hasLength(1),
    );
  });

  testWidgets('Edit Profile and Profile Completion use shared local bytes', (
    tester,
  ) async {
    repository.addPhotoInSession(
      _localPhoto,
      bytes: _localPhotoBytes,
      mimeType: 'image/png',
    );
    final localIndex = repository.profile.photos.indexOf(_localPhoto);
    repository.setPrimaryPhotoInSession(localIndex);
    repository.reorderPhotosInSession(localIndex, 0);

    await _pump(tester, const ProfileEditScreen());
    expect(
      tester
          .widgetList<AmoraaProfilePhotoView>(
            find.byType(AmoraaProfilePhotoView),
          )
          .where(
            (view) =>
                view.photo.source == _localPhoto &&
                identical(view.photo.bytes, _localPhotoBytes),
          ),
      isNotEmpty,
    );

    await _pump(tester, const ProfileCompletionScreen());
    final photosSection = find.byKey(
      const ValueKey('completion-section-photos'),
    );
    await tester.ensureVisible(photosSection);
    await tester.tap(photosSection);
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<AmoraaProfilePhotoView>(
            find.byType(AmoraaProfilePhotoView),
          )
          .where((view) => view.photo.source == _localPhoto),
      isNotEmpty,
    );
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

  test('adding and deleting photos refreshes completion immediately', () {
    repository.updatePhotosInSession([originalProfile.photos.first], 0);
    final before = repository.profile.completionResult.sections.firstWhere(
      (section) => section.id == ProfileCompletionSectionId.photos,
    );
    expect(before.isComplete, isFalse);

    repository.addPhotoInSession(
      _localPhoto,
      bytes: _localPhotoBytes,
      mimeType: 'image/png',
    );
    final afterAdd = repository.profile.completionResult.sections.firstWhere(
      (section) => section.id == ProfileCompletionSectionId.photos,
    );
    expect(afterAdd.isComplete, isTrue);

    repository.removePhotoInSession(1);
    final afterDelete = repository.profile.completionResult.sections.firstWhere(
      (section) => section.id == ProfileCompletionSectionId.photos,
    );
    expect(afterDelete.isComplete, isFalse);
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

  testWidgets('shared renderer prioritizes web-safe memory bytes', (
    tester,
  ) async {
    final bytes = base64Decode(_localPhoto.split(',').last);
    await _pump(
      tester,
      Center(
        child: SizedBox(
          width: 120,
          height: 150,
          child: AmoraaProfilePhotoView(
            photo: ProfilePhotoViewData(
              id: 'memory-photo',
              source: r'C:\browser\local-photo.png',
              order: 0,
              isPrimary: true,
              uploadState: ProfilePhotoUploadState.localOnly,
              bytes: bytes,
            ),
            semanticLabel: 'Memory profile photo',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(_unwrapResizedProvider(image.image), isA<MemoryImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank photo source uses the clean fallback', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 120,
        height: 150,
        child: AmoraaProfilePhotoView(
          photo: ProfilePhotoViewData(
            id: 'blank-photo',
            source: '',
            order: 0,
            isPrimary: false,
            uploadState: ProfilePhotoUploadState.localOnly,
          ),
          semanticLabel: 'Fallback profile photo',
        ),
      ),
    );

    expect(find.byType(AmoraaProfilePhotoView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uploading state overlays the real local image', (tester) async {
    repository.addPhotoInSession(
      _localPhoto,
      uploadState: ProfilePhotoUploadState.uploading,
      bytes: _localPhotoBytes,
      mimeType: 'image/png',
    );
    await _pump(tester, const PhotoManagerScreen(), settle: false);

    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => _unwrapResizedProvider(image.image)),
      contains(isA<MemoryImage>()),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Uploading'), findsOneWidget);
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
    expect(find.text('Preview Photo'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('photo-crop-use-button')));
    await tester.pumpAndSettle();

    final localEntry = repository.currentPhotos.singleWhere(
      (photo) => photo.source == _localPhoto,
    );
    expect(localEntry.uploadState, ProfilePhotoUploadState.failed);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      tester
          .widgetList<AmoraaProfilePhotoView>(
            find.byType(AmoraaProfilePhotoView),
          )
          .where((image) => image.photo.source == _localPhoto),
      isNotEmpty,
    );
  });

  testWidgets('upload success preserves identity and replaces the source', (
    tester,
  ) async {
    const remotePhoto = 'https://images.example/new-profile.jpg';
    final picker = _FakePhotoPicker();
    await _pump(
      tester,
      PhotoManagerScreen(
        mediaPicker: picker,
        cropPreviewRenderer: (_) async => _localPhoto,
        photoUploader: (_) async => remotePhoto,
      ),
    );

    await tester.tap(find.byIcon(Icons.add_photo_alternate_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from photo library'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-crop-use-button')));
    await tester.pumpAndSettle();

    final uploaded = repository.currentPhotos.singleWhere(
      (photo) => photo.source == remotePhoto,
    );
    expect(uploaded.uploadState, ProfilePhotoUploadState.uploaded);
    expect(uploaded.bytes, isNotEmpty);
    expect(uploaded.order, repository.profile.photos.indexOf(remotePhoto));
  });

  testWidgets('picker opens once while a selection is in progress', (
    tester,
  ) async {
    final picker = _BlockingPhotoPicker();
    await _pump(tester, PhotoManagerScreen(mediaPicker: picker));

    await tester.tap(find.byKey(const ValueKey('add-photo-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from photo library'));
    await tester.pump();
    expect(picker.calls, 1);

    await tester.tap(find.byKey(const ValueKey('add-photo-card')));
    await tester.pump();
    expect(picker.calls, 1);

    picker.complete(
      const AmoraMediaPickResult.failure(
        AmoraMediaIssue.cancelled,
        'Image selection was cancelled.',
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty selected bytes are rejected without a blank card', (
    tester,
  ) async {
    final initialCount = repository.currentPhotos.length;
    final emptyResult = AmoraMediaPickResult.success(
      AmoraPickedMedia(
        dataUri: 'data:image/png;base64,',
        name: 'empty.png',
        byteLength: 0,
        bytes: base64Decode(''),
        mimeType: 'image/png',
      ),
    );
    await _pump(
      tester,
      PhotoManagerScreen(mediaPicker: _FakePhotoPicker(result: emptyResult)),
    );

    await tester.tap(find.byKey(const ValueKey('add-photo-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from photo library'));
    await tester.pumpAndSettle();

    expect(repository.currentPhotos, hasLength(initialCount));
    expect(find.textContaining('could not be read'), findsOneWidget);
    expect(find.text('Crop Photo'), findsNothing);
  });

  testWidgets('invalid upload URL keeps bytes visible and offers Retry', (
    tester,
  ) async {
    final initialCount = repository.currentPhotos.length;
    await _pump(
      tester,
      PhotoManagerScreen(
        mediaPicker: _FakePhotoPicker(),
        cropPreviewRenderer: (_) async => _localPhoto,
        photoUploader: (_) async => 'not-a-photo-url',
      ),
    );

    await _addGalleryPhoto(tester);

    final failed = repository.currentPhotos.singleWhere(
      (photo) => photo.source == _localPhoto,
    );
    expect(repository.currentPhotos, hasLength(initialCount + 1));
    expect(failed.uploadState, ProfilePhotoUploadState.failed);
    expect(failed.bytes, isNotEmpty);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Retry uploads the same photo identity and local bytes', (
    tester,
  ) async {
    const remotePhoto = 'https://images.example/retried-profile.jpg';
    var uploadCalls = 0;
    await _pump(
      tester,
      PhotoManagerScreen(
        mediaPicker: _FakePhotoPicker(),
        cropPreviewRenderer: (_) async => _localPhoto,
        photoUploader: (_) async {
          uploadCalls++;
          if (uploadCalls == 1) throw StateError('offline');
          return remotePhoto;
        },
      ),
    );

    await _addGalleryPhoto(tester);
    final failed = repository.currentPhotos.singleWhere(
      (photo) => photo.source == _localPhoto,
    );
    final failedIndex = repository.profile.photos.indexOf(_localPhoto);
    repository.setPrimaryPhotoInSession(failedIndex);
    repository.reorderPhotosInSession(failedIndex, 0);
    final originalId = failed.id;
    final originalBytes = failed.bytes;

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    final uploaded = repository.currentPhotos.singleWhere(
      (photo) => photo.source == remotePhoto,
    );
    expect(uploadCalls, 2);
    expect(uploaded.id, originalId);
    expect(uploaded.bytes, same(originalBytes));
    expect(uploaded.order, 0);
    expect(uploaded.isPrimary, isTrue);
    expect(uploaded.uploadState, ProfilePhotoUploadState.uploaded);
  });

  testWidgets('content URI never reaches FileImage without picker bytes', (
    tester,
  ) async {
    await _pump(
      tester,
      const SizedBox(
        width: 120,
        height: 150,
        child: AmoraaProfilePhotoView(
          photo: ProfilePhotoViewData(
            id: 'android-content-photo',
            source: 'content://media/external/images/media/42',
            order: 0,
            isPrimary: false,
            uploadState: ProfilePhotoUploadState.localOnly,
          ),
          semanticLabel: 'Android content photo fallback',
        ),
      ),
    );

    expect(
      tester.widgetList<Image>(find.byType(Image)).map((image) => image.image),
      isNot(contains(isA<FileImage>())),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add photo tile is labelled and absent at the maximum', (
    tester,
  ) async {
    await _pump(tester, const PhotoManagerScreen());
    expect(find.text('Add photo'), findsOneWidget);

    await repository.resetForTesting(
      originalProfile.copyWith(
        photos: const [
          'assets/images/profiles/male/male_01.jpg',
          'assets/images/profiles/male/male_02.jpg',
          'assets/images/profiles/male/male_03.jpg',
          'assets/images/profiles/male/male_04.jpg',
          'assets/images/profiles/male/male_05.jpg',
          'assets/images/profiles/male/male_06.jpg',
        ],
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('add-photo-card')), findsNothing);
    expect(find.text('6 of 6 photos'), findsOneWidget);
  });

  testWidgets('Profile Completion photo section opens the shared photo UI', (
    tester,
  ) async {
    await _pump(tester, const ProfileCompletionScreen());
    final section = find.byKey(const ValueKey('completion-section-photos'));
    await tester.ensureVisible(section);
    await tester.tap(section);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-add-photo-action')),
      findsOneWidget,
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
      final firstThree = repository.currentPhotos.take(3).toList();
      if (firstThree.length == 3) {
        final firstTop = tester.getTopLeft(
          find.byKey(ValueKey(firstThree[0].id)),
        );
        final secondTop = tester.getTopLeft(
          find.byKey(ValueKey(firstThree[1].id)),
        );
        final thirdTop = tester.getTopLeft(
          find.byKey(ValueKey(firstThree[2].id)),
        );
        expect(secondTop.dy, firstTop.dy, reason: '$width px second tile');
        if (width >= 600) {
          expect(thirdTop.dy, firstTop.dy, reason: '$width px third tile');
        } else {
          expect(
            thirdTop.dy,
            greaterThan(firstTop.dy),
            reason: '$width px phone grid',
          );
        }
      }
    }
  });
}

ImageProvider<Object> _unwrapResizedProvider(ImageProvider<Object> provider) {
  return provider is ResizeImage ? provider.imageProvider : provider;
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(390, 844),
  Map<String, WidgetBuilder> routes = const {},
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(theme: AmoraTheme.light(), routes: routes, home: home),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _addGalleryPhoto(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('add-photo-card')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Choose from photo library'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('photo-crop-use-button')));
  await tester.pumpAndSettle();
}

const _localPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

class _FakePhotoPicker implements AmoraMediaPicker {
  _FakePhotoPicker({AmoraMediaPickResult? result})
    : result = result ?? _localSuccess;

  final AmoraMediaPickResult result;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<AmoraMediaPickResult> pickImage({
    required AmoraMediaSource source,
  }) async => result;
}

final _localPhotoBytes = base64Decode(_localPhoto.split(',').last);
final _localSuccess = AmoraMediaPickResult.success(
  AmoraPickedMedia(
    dataUri: _localPhoto,
    name: 'local.png',
    byteLength: _localPhotoBytes.lengthInBytes,
    bytes: _localPhotoBytes,
    mimeType: 'image/png',
  ),
);

class _BlockingPhotoPicker implements AmoraMediaPicker {
  final _result = Completer<AmoraMediaPickResult>();
  int calls = 0;

  void complete(AmoraMediaPickResult result) => _result.complete(result);

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<AmoraMediaPickResult> pickImage({required AmoraMediaSource source}) {
    calls++;
    return _result.future;
  }
}
