import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:flutter/material.dart';
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

  testWidgets('renders the premium AI hierarchy without overflow at 320px', (
    tester,
  ) async {
    await pumpMatches(tester, size: const Size(320, 760));

    expect(find.byType(AiMatchesAppBar), findsOneWidget);
    expect(find.text('Curated for you'), findsOneWidget);
    expect(find.byType(AiMatchSummary), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-match-filter-bar')), findsOneWidget);
    expect(find.text('Featured recommendation'), findsOneWidget);
    expect(find.byType(FeaturedAiMatchCard), findsOneWidget);
    expect(find.text('View Profile'), findsWidgets);
    expect(find.text('Message'), findsWidgets);
    expect(tester.takeException(), isNull);
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
