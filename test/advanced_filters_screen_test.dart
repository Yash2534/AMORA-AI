import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFilters(
    WidgetTester tester, {
    Size size = const Size(320, 700),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const AdvancedFiltersScreen(),
        routes: {
          '/browse': (_) =>
              const Scaffold(body: Center(child: Text('Discover route'))),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('compact layout keeps header and sticky actions readable', (
    tester,
  ) async {
    await pumpFilters(tester);

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Refine who appears in Discover'), findsOneWidget);
    expect(find.text('7 preferences selected'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('filters-category-navigation')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('filters-bottom-reset')), findsOneWidget);
    expect(find.byKey(const ValueKey('filters-apply-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter search reveals and highlights matching section', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 850));

    await tester.enterText(
      find.byKey(const ValueKey('filters-search-field')),
      'language',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('filters-section-identity')),
      findsOneWidget,
    );
    expect(find.text('Languages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expand, reset, and apply retain the existing callbacks', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 850));

    await tester.tap(
      find.byKey(const ValueKey('filters-section-toggle-career')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('Education'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filters-bottom-reset')));
    await tester.pumpAndSettle();
    expect(find.text('2 preferences selected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
    await tester.pumpAndSettle();
    expect(find.text('Discover route'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop layout remains centered and overflow-free', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(1200, 900));

    final search = find.byKey(const ValueKey('filters-search-field'));
    expect(tester.getSize(search).width, lessThanOrEqualTo(820));
    expect(tester.takeException(), isNull);
  });
}
