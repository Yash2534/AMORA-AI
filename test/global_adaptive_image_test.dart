import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_adaptive_image.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpImage(
    WidgetTester tester,
    Widget image, {
    double width = 320,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: width, child: image),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('portrait square and event shells use stable card ratios', (
    tester,
  ) async {
    await pumpImage(
      tester,
      const Column(
        children: [
          AmoraaAdaptiveImage(
            key: ValueKey('portrait'),
            source: AppImages.fallbackProfile,
            aspectMode: AmoraaImageAspectMode.portrait,
            semanticLabel: 'Portrait image',
          ),
          AmoraaAdaptiveImage(
            key: ValueKey('square'),
            source: AppImages.fallbackProfile,
            aspectMode: AmoraaImageAspectMode.square,
            semanticLabel: 'Square image',
          ),
          AmoraaAdaptiveImage(
            key: ValueKey('event'),
            source: AppImages.eventCoffee,
            fallbackAsset: AppImages.eventCoffee,
            aspectMode: AmoraaImageAspectMode.event,
            semanticLabel: 'Event image',
          ),
        ],
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('portrait'))).height, 400);
    expect(tester.getSize(find.byKey(const ValueKey('square'))).height, 320);
    expect(tester.getSize(find.byKey(const ValueKey('event'))).height, 180);
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .every((image) => image.fit == BoxFit.cover),
      isTrue,
    );
  });

  testWidgets('adaptive mode clamps extreme tall and wide ratios', (
    tester,
  ) async {
    await pumpImage(
      tester,
      const Column(
        children: [
          AmoraaAdaptiveImage(
            key: ValueKey('extreme-tall'),
            source: AppImages.fallbackProfile,
            aspectMode: AmoraaImageAspectMode.adaptive,
            originalAspectRatio: .2,
            maxHeight: 560,
          ),
          AmoraaAdaptiveImage(
            key: ValueKey('extreme-wide'),
            source: AppImages.fallbackProfile,
            aspectMode: AmoraaImageAspectMode.adaptive,
            originalAspectRatio: 4,
            maxHeight: 560,
          ),
        ],
      ),
      width: 360,
    );

    final tall = tester.getSize(find.byKey(const ValueKey('extreme-tall')));
    final wide = tester.getSize(find.byKey(const ValueKey('extreme-wide')));
    expect(tall.width / tall.height, closeTo(.72, .01));
    expect(wide.width / wide.height, closeTo(1.78, .01));
    expect(tall.height, lessThanOrEqualTo(560));
  });

  testWidgets('memory bytes have priority over invalid paths', (tester) async {
    await pumpImage(
      tester,
      AmoraaAdaptiveImage(
        source: 'content://media/external/images/42',
        assetPath: 'not-an-asset',
        bytes: _pixel,
        aspectMode: AmoraaImageAspectMode.portrait,
        semanticLabel: 'Local selected image',
      ),
      width: 160,
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('error fallback preserves card dimensions and clipping', (
    tester,
  ) async {
    const radius = BorderRadius.all(Radius.circular(20));
    await pumpImage(
      tester,
      const AmoraaAdaptiveImage(
        key: ValueKey('failed-card'),
        source: 'assets/images/does-not-exist.png',
        fallbackAsset: AppImages.fallbackProfile,
        aspectMode: AmoraaImageAspectMode.event,
        borderRadius: radius,
      ),
    );
    final before = tester.getSize(find.byKey(const ValueKey('failed-card')));
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const ValueKey('failed-card')));

    expect(before, after);
    expect(after, const Size(320, 180));
    expect(
      tester
          .widgetList<ClipRRect>(find.byType(ClipRRect))
          .any((clip) => clip.borderRadius == radius),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar remains square before circular clipping', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          body: Center(
            child: PremiumAvatar(
              imageUrl: AppImages.fallbackProfile,
              fallbackAsset: AppImages.fallbackProfile,
              initials: 'AM',
              radius: 28,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(PremiumAvatar)), const Size(56, 56));
    final adaptive = tester.widget<AmoraaAdaptiveImage>(
      find.byType(AmoraaAdaptiveImage),
    );
    expect(adaptive.fit, BoxFit.cover);
    expect(adaptive.borderRadius, BorderRadius.circular(999));
  });

  test('active card-image code never uses BoxFit.fill or contain', () {
    const cardImageFiles = [
      'lib/core/widgets/amoraa_adaptive_image.dart',
      'lib/core/widgets/amora_profile_image.dart',
      'lib/core/widgets/premium_image.dart',
      'lib/core/widgets/profile_card.dart',
      'lib/features/matches/presentation/matches_screen.dart',
      'lib/features/events/presentation/widgets/events_widgets.dart',
      'lib/features/profile/presentation/widgets/amoraa_profile_story_image.dart',
    ];
    for (final path in cardImageFiles) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('BoxFit.fill')), reason: path);
      expect(source, isNot(contains('BoxFit.contain')), reason: path);
    }
  });

  test('no BoxFit.fill remains under active lib sources', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      expect(
        file.readAsStringSync(),
        isNot(contains('BoxFit.fill')),
        reason: file.path,
      );
    }
  });
}

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
