import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/profile_photo_gallery.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profile = LocalProfileRepository.instance.profile.copyWith(
    photos: const [
      AppImages.profileYash,
      AppImages.profileAarav,
      AppImages.profileKavya,
    ],
    primaryPhotoIndex: 0,
  );

  Widget gallery({required double width, VoidCallback? onManage}) {
    return MaterialApp(
      theme: AmoraTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: ProfilePhotoGallery(
              profile: profile,
              onManage: onManage ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses one horizontal row with equal-sized photo cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(gallery(width: 280));
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.scrollDirection, Axis.horizontal);
    expect(
      find.byKey(const ValueKey('profile-horizontal-photo-gallery')),
      findsOneWidget,
    );

    for (var index = 0; index < profile.photos.length; index++) {
      final size = tester.getSize(
        find.byKey(ValueKey('profile-gallery-photo-$index')),
      );
      expect(size.width, ProfilePhotoGallery.photoWidth);
      expect(size.height, ProfilePhotoGallery.photoHeight);
    }

    expect(find.text('Primary'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(-260, 0));
    await tester.pumpAndSettle();
    expect(find.text('Add Photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves photo order, cover fit, and accessible labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(600, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(gallery(width: 560));
    await tester.pumpAndSettle();

    final images = tester
        .widgetList<AmoraProfileImage>(find.byType(AmoraProfileImage))
        .toList(growable: false);
    expect(images.map((image) => image.assetPath), profile.photos);
    expect(images.every((image) => image.fit == BoxFit.cover), isTrue);
    expect(images.map((image) => image.semanticLabel), const [
      'Profile photo 1',
      'Profile photo 2',
      'Profile photo 3',
    ]);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Primary photo',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Add profile photo',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Add Photo reuses the supplied photo-manager callback', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(gallery(width: 390, onManage: () => opened = true));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(-260, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-add-photo-card')));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
  });

  testWidgets('vertical mouse wheel scrolls the horizontal gallery on web', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(gallery(width: 280));
    await tester.pumpAndSettle();

    final galleryFinder = find.byKey(
      const ValueKey('profile-horizontal-photo-gallery'),
    );
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.offset, 0);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(galleryFinder),
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pumpAndSettle();

    expect(list.controller!.offset, greaterThan(0));
  });

  testWidgets('stays compact and overflow-free at supported widths', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
      await tester.binding.setSurfaceSize(Size(width, 300));
      await tester.pumpWidget(gallery(width: width - 40));
      await tester.pumpAndSettle();

      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('profile-horizontal-photo-gallery')),
            )
            .height,
        lessThanOrEqualTo(138),
      );
      expect(tester.takeException(), isNull, reason: 'Overflow at $width px');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('Profile Manage action preserves the photo-manager route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileScreen(showNavigation: false),
        onGenerateRoute: (settings) {
          openedRoute = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Destination')),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final heading = find.byKey(const ValueKey('profile-photo-gallery-heading'));
    await tester.scrollUntilVisible(
      heading,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: heading, matching: find.text('Manage')),
    );
    await tester.pumpAndSettle();

    expect(openedRoute?.name, PhotoManagerScreen.routeName);
    expect(tester.takeException(), isNull);
  });
}
