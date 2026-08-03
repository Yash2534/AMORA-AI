import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/discover/presentation/widgets/amoraa_minimum_height_picker.dart';
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
        home: AdvancedFiltersScreen(key: UniqueKey()),
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

  testWidgets('dynamic more chip reveals every active preference and closes', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(320, 640));

    expect(find.text('+3 more'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('selected-preferences-more')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const ValueKey('selected-preferences-sheet'));
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text('Selected Preferences')),
      findsOneWidget,
    );
    for (final label in <String>[
      'Long-Term Relationship',
      'Ahmedabad',
      'Gujarati',
      'Verified only',
      'Coffee Dates',
      'Open to all',
      'Has profile prompts',
    ]) {
      final labelFinder = find.descendant(
        of: sheet,
        matching: find.text(label),
      );
      if (labelFinder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          labelFinder,
          120,
          scrollable: find.descendant(
            of: sheet,
            matching: find.byType(Scrollable),
          ),
        );
      }
      expect(
        labelFinder,
        findsOneWidget,
        reason: '$label must be revealed in the summary sheet.',
      );
    }

    await tester.tap(find.byKey(const ValueKey('selected-preferences-close')));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('education is single-select and replaces the prior value', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 850));
    final career = find.byKey(const ValueKey('filters-section-toggle-career'));
    await tester.ensureVisible(career);
    await tester.tap(career);
    await tester.pumpAndSettle();

    final graduate = find.byKey(const ValueKey('filter-option-Graduate'));
    final mba = find.byKey(const ValueKey('filter-option-MBA'));
    await tester.ensureVisible(graduate);
    await tester.tap(graduate);
    await tester.pumpAndSettle();
    expect(find.text('8 preferences selected'), findsOneWidget);
    expect(find.text('+4 more'), findsOneWidget);

    await tester.tap(mba);
    await tester.pumpAndSettle();
    expect(find.text('8 preferences selected'), findsOneWidget);
    final selectedEducation = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
          (widget) =>
              widget.properties.label == 'MBA, selected' &&
              widget.properties.selected == true,
        );
    final previousEducation = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
          (widget) =>
              widget.properties.label == 'Graduate, not selected' &&
              widget.properties.selected == false,
        );
    expect(selectedEducation, isNotEmpty);
    expect(previousEducation, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('city selector contains exactly four single-select choices', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(390, 844));

    expect(
      approvedFilterCities,
      orderedEquals(<String>['Ahmedabad', 'Gandhinagar', 'Surat', 'Vadodara']),
    );
    expect(find.byKey(const ValueKey('filters-city-search')), findsNothing);
    final cityControl = find.byKey(const ValueKey('filters-city-control'));
    expect(cityControl, findsOneWidget);
    for (final city in approvedFilterCities) {
      final cityFinder = find.byKey(ValueKey('filter-option-$city'));
      await tester.ensureVisible(cityFinder);
      expect(cityFinder, findsOneWidget);
    }
    for (final city in <String>['Rajkot', 'Mumbai', 'Pune', 'Other']) {
      expect(
        find.descendant(of: cityControl, matching: find.text(city)),
        findsNothing,
      );
    }

    final surat = find.byKey(const ValueKey('filter-option-Surat'));
    await tester.ensureVisible(surat);
    await tester.tap(surat);
    await tester.pumpAndSettle();
    final selectedCity = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
          (widget) =>
              widget.properties.label == 'Surat, selected' &&
              widget.properties.selected == true,
        );
    final previousCity = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
          (widget) =>
              widget.properties.label == 'Ahmedabad, not selected' &&
              widget.properties.selected == false,
        );
    expect(selectedCity, isNotEmpty);
    expect(previousCity, isNotEmpty);
    expect(find.text('7 preferences selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('height wheel converts units, applies locally, and resets', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(320, 640));
    final heightEntry = find.byKey(const ValueKey('filters-height-picker'));
    await tester.ensureVisible(heightEntry);
    await tester.tap(heightEntry);
    await tester.pumpAndSettle();

    expect(find.byType(AmoraaMinimumHeightPicker), findsOneWidget);
    expect(find.text('Always visible on profile'), findsNothing);
    expect(find.text('5\'5"'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('height-unit-centimeters')));
    await tester.pumpAndSettle();
    expect(find.text('165 cm'), findsOneWidget);

    final wheel = find.byKey(const ValueKey('height-wheel-centimeters'));
    await tester.drag(wheel, const Offset(0, -80));
    await tester.pumpAndSettle();
    final selectedLabel = tester
        .widget<Text>(find.byKey(const ValueKey('selected-height-value')))
        .data!;
    final selectedCentimeters = int.parse(selectedLabel.split(' ').first);
    expect(selectedCentimeters, isNot(165));

    await tester.tap(find.byKey(const ValueKey('height-picker-apply')));
    await tester.pumpAndSettle();
    expect(
      find.text(minimumHeightSummary(selectedCentimeters)),
      findsOneWidget,
    );
    expect(find.text('8 preferences selected'), findsOneWidget);

    await tester.ensureVisible(heightEntry);
    await tester.tap(heightEntry);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('height-picker-reset')));
    await tester.tap(find.byKey(const ValueKey('height-picker-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Any height'), findsOneWidget);
    expect(find.text('7 preferences selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('height conversion helpers preserve practical equivalents', () {
    expect(heightInchesToCentimeters(65), 165);
    expect(heightCentimetersToNearestInches(165), 65);
    expect(formatHeightFeet(165), '5\'5"');
    expect(minimumHeightSummary(null), 'Any height');
    expect(minimumSupportedHeightCm, 137);
    expect(maximumSupportedHeightCm, 213);
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

  testWidgets('target sections and sheets stay responsive at every width', (
    tester,
  ) async {
    for (final size in <Size>[
      const Size(320, 640),
      const Size(360, 800),
      const Size(390, 844),
      const Size(412, 915),
      const Size(430, 932),
      const Size(600, 960),
      const Size(768, 1024),
    ]) {
      await pumpFilters(tester, size: size);
      await tester.tap(find.byKey(const ValueKey('selected-preferences-more')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-preferences-sheet')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('selected-preferences-close')),
      );
      await tester.pumpAndSettle();

      final heightEntry = find.byKey(const ValueKey('filters-height-picker'));
      await tester.ensureVisible(heightEntry);
      await tester.tap(heightEntry);
      await tester.pumpAndSettle();
      expect(find.byType(AmoraaMinimumHeightPicker), findsOneWidget);
      expect(
        find.byKey(const ValueKey('height-picker-apply')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('height-picker-close')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overflow at $size');
    }
  });
}
