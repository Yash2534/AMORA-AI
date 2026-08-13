import 'dart:io';

import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/matches/presentation/widgets/amoraa_inline_compatibility_filter.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RouteSettings? openedRoute;

  setUp(ChatRepository.instance.resetForTesting);

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
        home: MatchesScreen(
          initialProfiles: ImageRepository.profiles.skip(18).take(12).toList(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the inline filter without a modal at 320px', (
    tester,
  ) async {
    await pumpMatches(tester, size: const Size(320, 760));

    expect(find.byType(AiMatchesAppBar), findsOneWidget);
    expect(find.text('Curated for you'), findsNothing);
    expect(find.text('Best Matches'), findsWidgets);
    expect(find.byType(AmoraaInlineCompatibilityFilter), findsOneWidget);
    expect(
      tester.getRect(find.byType(AmoraaInlineCompatibilityFilter)).left,
      AmoraaMainPageHeader.contentHorizontalInset,
    );
    expect(
      find.byKey(const ValueKey('ai-compatibility-filter-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('minimum-compatibility-slider')),
      findsOneWidget,
    );
    expect(find.text('70%+'), findsOneWidget);
    expect(find.text('Recommended Matches'), findsOneWidget);
    expect(
      find.text(
        'Showing recommended matches with 70% compatibility or higher.',
      ),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Apply'), findsNothing);
    expect(find.text('0%'), findsNothing);
    expect(find.text('100%'), findsNothing);
    expect(find.byKey(const ValueKey('ai-match-filter-bar')), findsOneWidget);
    expect(find.byType(AmoraaCompactSelect<AiMatchFilter>), findsNothing);
    expect(
      tester
          .widget<ListView>(
            find.byKey(const ValueKey('ai-match-filter-scroll')),
          )
          .scrollDirection,
      Axis.horizontal,
    );
    expect(find.text('Featured recommendation'), findsOneWidget);
    expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
    expect(find.text('View Profile'), findsWidgets);
    expect(find.text('Message'), findsWidgets);
    final featured = tester.widget<FeaturedAiMatchCard>(
      find.byType(FeaturedAiMatchCard),
    );
    expect(find.text('${featured.profile.score}%'), findsNothing);
    expect(find.text('High confidence'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('compatibility labels and limits use one centralized mapping', () {
    expect(minimumCompatibilityThreshold, 50);
    expect(maximumCompatibilityThreshold, 95);
    expect(compatibilityThresholdStep, 5);
    expect(defaultCompatibilityThreshold, 70);

    expect(compatibilityFilterLabel(50), 'Open Matches');
    expect(compatibilityFilterLabel(59), 'Open Matches');
    expect(compatibilityFilterLabel(60), 'Good Matches');
    expect(compatibilityFilterLabel(69), 'Good Matches');
    expect(compatibilityFilterLabel(70), 'Recommended Matches');
    expect(compatibilityFilterLabel(79), 'Recommended Matches');
    expect(compatibilityFilterLabel(80), 'Highly Compatible');
    expect(compatibilityFilterLabel(89), 'Highly Compatible');
    expect(compatibilityFilterLabel(90), 'Best Matches');
    expect(compatibilityFilterLabel(95), 'Best Matches');

    expect(compatibilityCardLabel(92), 'Best Match');
    expect(compatibilityCardLabel(84), 'Highly Compatible');
    expect(compatibilityCardLabel(76), 'Recommended Match');
    expect(compatibilityCardLabel(68), 'Good Match');
    expect(compatibilityCardLabel(55), 'Open Match');
  });

  test('AI Matches source contains no fixed 98 percent presentation', () {
    final screenSource = File(
      'lib/features/matches/presentation/matches_screen.dart',
    ).readAsStringSync();
    final inlineFilterSource = File(
      'lib/features/matches/presentation/widgets/'
      'amoraa_inline_compatibility_filter.dart',
    ).readAsStringSync();
    final oldSlider = File(
      'lib/features/matches/presentation/widgets/'
      'amora_compatibility_slider.dart',
    );

    expect(screenSource, isNot(contains("'98%'")));
    expect(screenSource, isNot(contains('"98%"')));
    expect(inlineFilterSource, isNot(contains("'98%'")));
    expect(inlineFilterSource, isNot(contains('"98%"')));
    expect(screenSource, isNot(contains('_CompatibilityRingPainter')));
    expect(screenSource, isNot(contains('class AiCompatibilityBadge')));
    expect(screenSource, isNot(contains('_CompatibilityFilterSheet')));
    expect(screenSource, isNot(contains('_showCompatibilityFilter')));
    expect(oldSlider.existsSync(), isFalse);
  });

  testWidgets('slider uses 50 to 95 in five-point steps', (tester) async {
    await pumpMatches(tester);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('minimum-compatibility-slider')),
    );
    expect(slider.value, defaultCompatibilityThreshold);
    expect(slider.min, minimumCompatibilityThreshold);
    expect(slider.max, maximumCompatibilityThreshold);
    expect(slider.divisions, 9);
    expect(slider.semanticFormatterCallback!(70), contains('70 percent'));
  });

  testWidgets('slider filters immediately and keeps scores descending', (
    tester,
  ) async {
    await pumpMatches(tester);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('minimum-compatibility-slider')),
    );
    expect(slider.value, defaultCompatibilityThreshold);
    slider.onChanged!(90);
    await tester.pumpAndSettle();

    expect(find.text('90%+'), findsOneWidget);
    expect(find.text('Best Matches'), findsWidgets);
    expect(
      find.text('Showing best matches with 90% compatibility or higher.'),
      findsOneWidget,
    );
    expect(find.text('Apply'), findsNothing);
    final scores = tester
        .widgetList<AiMatchImage>(find.byType(AiMatchImage))
        .map((image) => image.profile.score)
        .toList();
    expect(scores, isNotEmpty);
    expect(scores.every((score) => score >= 90), isTrue);
    expect(scores, orderedEquals([...scores]..sort((a, b) => b.compareTo(a))));
    for (final score in scores) {
      expect(find.text('$score%'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact reset returns to 70 percent and hides at default', (
    tester,
  ) async {
    await pumpMatches(tester);
    expect(
      find.byKey(const ValueKey('compatibility-filter-reset')),
      findsNothing,
    );
    tester
        .widget<Slider>(
          find.byKey(const ValueKey('minimum-compatibility-slider')),
        )
        .onChanged!(85);
    await tester.pumpAndSettle();

    expect(find.text('85%+'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compatibility-filter-reset')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('compatibility-filter-reset')));
    await tester.pumpAndSettle();

    expect(find.text('70%+'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('compatibility-filter-reset')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty threshold state offers the required 70 percent CTA', (
    tester,
  ) async {
    var lowered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiMatchesThresholdEmptyState(
            onLowerFilter: () => lowered = true,
          ),
        ),
      ),
    );

    expect(find.text('No matches at this level yet'), findsOneWidget);
    expect(
      find.text('Try lowering the compatibility filter to see more people.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Lower to 70%'));
    expect(lowered, isTrue);
  });

  testWidgets(
    'successful zero-result response shows profile completion empty state',
    (tester) async {
      openedRoute = null;
      await tester.binding.setSurfaceSize(const Size(320, 760));
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
          home: MatchesScreen(showNavigation: false, api: _EmptyMatchesApi()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete your profile first'), findsOneWidget);
      expect(find.text('Complete Profile'), findsOneWidget);
      expect(find.byType(AiMatchFilterBar), findsNothing);
      expect(find.byType(FeaturedAiMatchCard), findsNothing);
      expect(find.text('Best Matches'), findsNothing);
      expect(find.text('Try again'), findsNothing);

      await tester.tap(find.text('Complete Profile'));
      await tester.pumpAndSettle();
      expect(openedRoute?.name, ProfileCompletionScreen.routeName);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('API errors do not render the zero-result empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MatchesScreen(showNavigation: false, api: _FailingMatchesApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load matches."), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Complete your profile first'), findsNothing);
    expect(find.text('Complete Profile'), findsNothing);
  });

  testWidgets('keyboard arrows adjust the compatibility threshold', (
    tester,
  ) async {
    await pumpMatches(tester, size: const Size(1024, 768));

    final sliderFinder = find.byKey(
      const ValueKey('minimum-compatibility-slider'),
    );
    await tester.tap(sliderFinder);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(find.text('75%+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector and cards remain responsive at supported widths', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      await pumpMatches(tester, size: Size(width, width >= 600 ? 900 : 760));

      expect(find.byType(AmoraaInlineCompatibilityFilter), findsOneWidget);
      expect(find.text('70%+'), findsOneWidget);
      expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
      expect(
        tester
            .widget<ListView>(
              find.byKey(const ValueKey('ai-match-filter-scroll')),
            )
            .scrollDirection,
        Axis.horizontal,
      );
      expect(
        tester.getSize(find.byType(AmoraaInlineCompatibilityFilter)).width,
        lessThanOrEqualTo(width),
      );
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

    await tester.tap(find.byKey(const ValueKey('ai-match-filter-Best Match')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AmoraFilterChip>(
            find.byKey(const ValueKey('ai-match-filter-Best Match')),
          )
          .selected,
      isTrue,
    );
    expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
    expect(find.text('More recommendations'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('ai-match-filter-Active Now')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AmoraFilterChip>(
            find.byKey(const ValueKey('ai-match-filter-Best Match')),
          )
          .selected,
      isFalse,
    );
    expect(
      tester
          .widget<AmoraFilterChip>(
            find.byKey(const ValueKey('ai-match-filter-Active Now')),
          )
          .selected,
      isTrue,
    );
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
    expect(
      find.text('${featured.profile.score}% supplied by AMORAA'),
      findsOneWidget,
    );
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
    expect(appBarRect.width, lessThanOrEqualTo(1080));
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

class _EmptyMatchesApi extends PhaseTwoApiService {
  @override
  Future<List<MatchApiItem>> matches() async => const [];
}

class _FailingMatchesApi extends PhaseTwoApiService {
  @override
  Future<List<MatchApiItem>> matches() async => throw Exception('offline');
}
