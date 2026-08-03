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

    final selector = find.byKey(const ValueKey('filters-education-selector'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('amoraa-select-option-Undergraduate')),
    );
    await tester.pumpAndSettle();
    expect(find.text('8 preferences selected'), findsOneWidget);
    expect(find.text('+4 more'), findsOneWidget);

    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('amoraa-select-option-Postgraduate')),
    );
    await tester.pumpAndSettle();
    expect(find.text('8 preferences selected'), findsOneWidget);
    expect(
      find.descendant(of: selector, matching: find.text('Postgraduate')),
      findsOneWidget,
    );
    expect(find.text('Undergraduate'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared Smoking options include Yes and remain single-select', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 850));
    final habits = find.byKey(const ValueKey('filters-section-toggle-habits'));
    await tester.ensureVisible(habits);
    await tester.tap(habits);
    await tester.pumpAndSettle();

    final selector = find.byKey(const ValueKey('filters-smoking-selector'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();

    final yes = find.byKey(const ValueKey('amoraa-select-option-Yes'));
    await tester.ensureVisible(yes);
    await tester.tap(yes);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: selector, matching: find.text('Yes')),
      findsOneWidget,
    );

    await tester.tap(selector);
    await tester.pumpAndSettle();
    final sometimes = find.byKey(
      const ValueKey('amoraa-select-option-Sometimes'),
    );
    await tester.ensureVisible(sometimes);
    await tester.tap(sometimes);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: selector, matching: find.text('Sometimes')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: selector, matching: find.text('Yes')),
      findsNothing,
    );
  });

  testWidgets('city selector contains exactly four single-select choices', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(390, 844));

    expect(
      approvedFilterCities,
      orderedEquals(<String>['Gandhinagar', 'Ahmedabad', 'Surat', 'Vadodara']),
    );
    expect(find.byKey(const ValueKey('filters-city-search')), findsNothing);
    final cityControl = find.byKey(const ValueKey('filters-city-control'));
    expect(cityControl, findsOneWidget);
    final citySelector = find.byKey(const ValueKey('filters-city-selector'));
    await tester.ensureVisible(citySelector);
    await tester.tap(citySelector);
    await tester.pumpAndSettle();
    for (final city in approvedFilterCities) {
      final cityFinder = find.byKey(ValueKey('amoraa-select-option-$city'));
      expect(cityFinder, findsOneWidget);
    }
    for (final city in <String>['Rajkot', 'Mumbai', 'Pune', 'Other']) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('amoraa-select-sheet')),
          matching: find.text(city),
        ),
        findsNothing,
      );
    }

    final surat = find.byKey(const ValueKey('amoraa-select-option-Surat'));
    await tester.tap(surat);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: citySelector, matching: find.text('Surat')),
      findsOneWidget,
    );
    expect(find.text('7 preferences selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Education Other requires trimmed custom text inline', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 850));
    final career = find.byKey(const ValueKey('filters-section-toggle-career'));
    await tester.ensureVisible(career);
    await tester.tap(career);
    await tester.pumpAndSettle();

    final selector = find.byKey(const ValueKey('filters-education-selector'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    final other = find.byKey(const ValueKey('amoraa-select-option-Other'));
    await tester.scrollUntilVisible(
      other,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(other);
    await tester.pumpAndSettle();

    final custom = find.byKey(const ValueKey('filters-custom-education-field'));
    expect(custom, findsOneWidget);
    await tester.enterText(custom, '   ');
    await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
    await tester.pumpAndSettle();
    expect(find.text('Specify education'), findsNWidgets(2));

    await tester.enterText(custom, '  Montessori training  ');
    await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
    await tester.pumpAndSettle();
    expect(find.text('Discover route'), findsOneWidget);
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
    expect(find.text('Education'), findsWidgets);

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
