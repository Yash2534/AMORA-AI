import 'dart:io';

import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/matches/presentation/widgets/amora_compatibility_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RouteSettings? openedRoute;

  Future<void> pumpMatches(
    WidgetTester tester, {
    Size size = const Size(430, 900),
  }) async {
    openedRoute = null;
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          openedRoute = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _RouteMarker(settings.name ?? 'unknown'),
          );
        },
        home: const MatchesScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Slider> openCompatibilityFilter(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey('ai-compatibility-filter-button')),
    );
    await tester.pumpAndSettle();
    return tester.widget<Slider>(
      find.byKey(const ValueKey('minimum-compatibility-slider')),
    );
  }

  testWidgets('renders the premium AI hierarchy without overflow at 320px', (
    tester,
  ) async {
    await pumpMatches(tester, size: const Size(320, 760));

    expect(find.byType(AiMatchesAppBar), findsOneWidget);
    expect(find.text('Curated for you'), findsOneWidget);
    expect(find.byType(AmoraCompatibilitySlider), findsNothing);
    expect(
      find.byKey(const ValueKey('ai-compatibility-filter-button')),
      findsOneWidget,
    );
    await openCompatibilityFilter(tester);
    expect(find.byType(AmoraCompatibilitySlider), findsOneWidget);
    expect(
      find.byKey(const ValueKey('minimum-compatibility-slider')),
      findsOneWidget,
    );
    expect(find.text('70% and above'), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-match-filter-bar')), findsOneWidget);
    expect(find.text('Featured recommendation'), findsOneWidget);
    expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
    expect(find.text('View Profile'), findsWidgets);
    expect(find.text('Message'), findsWidgets);
    final featured = tester.widget<FeaturedAiMatchCard>(
      find.byType(FeaturedAiMatchCard),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                '${featured.profile.score} percent compatibility, '
                    '${compatibilityLabel(featured.profile.score)}',
      ),
      findsOneWidget,
    );
    expect(find.text('High confidence'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('compatibility labels use one centralized mapping', () {
    expect(compatibilityLabel(100), 'Excellent Match');
    expect(compatibilityLabel(90), 'Excellent Match');
    expect(compatibilityLabel(89), 'Highly Compatible');
    expect(compatibilityLabel(80), 'Highly Compatible');
    expect(compatibilityLabel(79), 'Great Match');
    expect(compatibilityLabel(70), 'Great Match');
    expect(compatibilityLabel(69), 'Good Match');
    expect(compatibilityLabel(60), 'Good Match');
    expect(compatibilityLabel(59), 'Potential Match');
    expect(compatibilityLabel(-10), 'Potential Match');
  });

  test('AI Matches source contains no fixed 98 percent presentation', () {
    final screenSource = File(
      'lib/features/matches/presentation/matches_screen.dart',
    ).readAsStringSync();
    final sliderSource = File(
      'lib/features/matches/presentation/widgets/'
      'amora_compatibility_slider.dart',
    ).readAsStringSync();

    expect(screenSource, isNot(contains("'98%'")));
    expect(screenSource, isNot(contains('"98%"')));
    expect(sliderSource, isNot(contains("'98%'")));
    expect(sliderSource, isNot(contains('"98%"')));
    expect(screenSource, isNot(contains('_CompatibilityRingPainter')));
  });

  testWidgets('slider filters locally and keeps scores descending', (
    tester,
  ) async {
    await pumpMatches(tester);

    final slider = await openCompatibilityFilter(tester);
    expect(slider.value, defaultCompatibilityThreshold);
    slider.onChanged!(90);
    await tester.pumpAndSettle();

    expect(find.text('90% and above'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('compatibility-filter-apply')));
    await tester.pumpAndSettle();
    final scores = tester
        .widgetList<AiMatchImage>(find.byType(AiMatchImage))
        .map((image) => image.profile.score)
        .toList();
    expect(scores, isNotEmpty);
    expect(scores.every((score) => score >= 90), isTrue);
    expect(scores, orderedEquals([...scores]..sort((a, b) => b.compareTo(a))));
    for (final score in scores) {
      expect(find.text('$score%'), findsWidgets);
      expect(find.text(compatibilityLabel(score)), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty threshold state can lower the filter', (tester) async {
    await pumpMatches(tester);
    final slider = await openCompatibilityFilter(tester);
    slider.onChanged!(100);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('compatibility-filter-apply')));
    await tester.pumpAndSettle();

    expect(find.text('No matches above 100% yet'), findsOneWidget);
    expect(
      find.text(
        'Try lowering the compatibility filter to discover more people.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Lower filter'));
    await tester.pumpAndSettle();

    expect(find.text('70%+'), findsOneWidget);
    expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard arrows adjust the compatibility threshold', (
    tester,
  ) async {
    await pumpMatches(tester, size: const Size(1024, 768));

    await openCompatibilityFilter(tester);
    final sliderFinder = find.byKey(
      const ValueKey('minimum-compatibility-slider'),
    );
    await tester.tap(sliderFinder);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(find.text('80% and above'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector and cards remain responsive at supported widths', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
      await pumpMatches(tester, size: Size(width, width >= 600 ? 900 : 760));

      expect(find.byType(AmoraCompatibilitySlider), findsNothing);
      expect(find.text('70%+'), findsOneWidget);
      expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
      await openCompatibilityFilter(tester);
      expect(
        tester.getSize(find.byType(AmoraCompatibilitySlider)).width,
        lessThanOrEqualTo(width),
      );
      await tester.tap(
        find.byKey(const ValueKey('compatibility-filter-close')),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow at $width px');
    }
  });

  testWidgets(
    'featured profile is the highest supplied score and not repeated',
    (tester) async {
      await pumpMatches(tester);
      final recommendations = _testRecommendations();
      final best = recommendations.reduce(
        (current, candidate) =>
            candidate.score > current.score ? candidate : current,
      );
      final featured = tester.widget<FeaturedAiMatchCard>(
        find.byType(FeaturedAiMatchCard),
      );

      expect(featured.profile.id, best.id);
      expect(find.byKey(ValueKey('ai-match-${best.id}')), findsNothing);

      final builtProfiles = tester
          .widgetList<AiMatchImage>(find.byType(AiMatchImage))
          .map((image) => image.profile.id)
          .toList();
      expect(builtProfiles.toSet().length, builtProfiles.length);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('supported filters use existing profile fields', (tester) async {
    await pumpMatches(tester);

    await tester.tap(find.byKey(const ValueKey('ai-match-filter-best-match')));
    await tester.pumpAndSettle();
    expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
    expect(find.text('More recommendations'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ai-match-filter-active-now')));
    await tester.pumpAndSettle();
    final visible = tester.widget<FeaturedAiMatchCard>(
      find.byType(FeaturedAiMatchCard),
    );
    expect(visible.profile.status.toLowerCase(), 'online now');
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile and message actions preserve existing routes', (
    tester,
  ) async {
    await pumpMatches(tester);
    final featuredFinder = find.byType(FeaturedAiMatchCard);
    final featured = tester.widget<FeaturedAiMatchCard>(featuredFinder);
    final viewProfile = find.descendant(
      of: featuredFinder,
      matching: find.widgetWithText(OutlinedButton, 'View Profile'),
    );

    await tester.ensureVisible(viewProfile);
    await tester.pumpAndSettle();
    await tester.tap(viewProfile);
    await tester.pumpAndSettle();
    expect(openedRoute?.name, '/profile-detail');
    expect(openedRoute?.arguments, same(featured.profile));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    final message = find.descendant(
      of: find.byType(FeaturedAiMatchCard),
      matching: find.widgetWithText(FilledButton, 'Message'),
    );
    await tester.ensureVisible(message);
    await tester.pumpAndSettle();
    await tester.tap(message);
    await tester.pumpAndSettle();
    expect(openedRoute?.name, '/chat-detail');
    expect(tester.takeException(), isNull);
  });

  testWidgets('why recommendation sheet shows only available factors', (
    tester,
  ) async {
    await pumpMatches(tester);
    final featured = tester.widget<FeaturedAiMatchCard>(
      find.byType(FeaturedAiMatchCard),
    );

    final whyMatch = find.byKey(ValueKey('why-match-${featured.profile.id}'));
    await tester.ensureVisible(whyMatch);
    await tester.pumpAndSettle();
    await tester.tap(whyMatch);
    await tester.pumpAndSettle();

    expect(find.text('Why this recommendation'), findsOneWidget);
    expect(find.text('Compatibility score'), findsOneWidget);
    expect(find.text('Relationship intention'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.textContaining('guarantee compatibility'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop uses a centred featured card and two-column feed', (
    tester,
  ) async {
    await pumpMatches(tester, size: const Size(1200, 900));

    final appBarRect = tester.getRect(find.byType(AiMatchesAppBar));
    expect(appBarRect.width, lessThanOrEqualTo(1032));
    expect(appBarRect.center.dx, closeTo(600, 1));
    expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
    final featured = tester.widget<FeaturedAiMatchCard>(
      find.byType(FeaturedAiMatchCard),
    );
    expect(featured.horizontal, isTrue);
    expect(tester.takeException(), isNull);
  });
}

List<DummyProfile> _testRecommendations() {
  final ids = <String>{};
  final images = <String>{};
  return ImageRepository.profiles
      .skip(18)
      .take(12)
      .where((profile) => ids.add(profile.id) && images.add(profile.imageUrl))
      .toList(growable: false);
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
