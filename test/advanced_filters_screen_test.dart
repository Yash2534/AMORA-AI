import 'dart:async';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/data/match_location_service.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/discover/presentation/widgets/amoraa_minimum_height_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SuccessfulDiscoverApi extends DiscoverApiService {
  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> getFilters() async =>
      const DiscoverApiResult.success(<String, dynamic>{
        'minAge': 24,
        'maxAge': 34,
        'maxDistanceKm': 80,
        'minScore': 80,
        'city': 'Ahmedabad',
        'datingIntentions': <String>['Long-Term Relationship'],
        'lifestyleTags': <String>['Coffee Dates'],
        'community': 'Open to all',
        'languages': <String>['Gujarati'],
        'verifiedOnly': true,
        'hasPrompts': true,
      }, statusCode: 200);

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> filters,
  ) async => DiscoverApiResult.success(filters, statusCode: 200);
}

class _SinglePreferenceDiscoverApi extends DiscoverApiService {
  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> getFilters() async =>
      const DiscoverApiResult.success(<String, dynamic>{
        'minAge': 18,
        'maxAge': 45,
        'maxDistanceKm': 80,
        'minScore': 0,
        'verifiedOnly': true,
      }, statusCode: 200);

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> filters,
  ) async => DiscoverApiResult.success(filters, statusCode: 200);
}

class _DuplicatePreferenceDiscoverApi extends _SuccessfulDiscoverApi {
  Map<String, dynamic>? submittedFilters;

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> getFilters() async =>
      const DiscoverApiResult.success(<String, dynamic>{
        'minAge': 24,
        'maxAge': 34,
        'maxDistanceKm': 80,
        'minScore': 80,
        'city': 'Ahmedabad',
        'hometown': <String>['Ahmedabad', ' Ahmedabad ', 'ahmedabad'],
        'datingIntentions': <String>[
          'Long-Term Relationship',
          ' long-term relationship ',
        ],
        'lifestyleTags': <String>['Coffee Dates'],
        'community': 'Open to all',
        'languages': <String>['Gujarati', ' GUJARATI '],
        'verifiedOnly': true,
      }, statusCode: 200);

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> filters,
  ) async {
    submittedFilters = Map<String, dynamic>.from(filters);
    return DiscoverApiResult.success(filters, statusCode: 200);
  }
}

class _FakeMatchLocationService extends MatchLocationService {
  _FakeMatchLocationService(this.result);

  final MatchLocationResult result;
  int calls = 0;

  @override
  Future<MatchLocationResult> enableCurrentLocation() async {
    calls += 1;
    return result;
  }
}

class _FilterFlowApi extends _SuccessfulDiscoverApi {
  int updates = 0;
  int feedRequests = 0;

  @override
  Future<DiscoverApiResult<DiscoverFeedPage>> getFeed({
    String? cursor,
    int limit = 10,
    Iterable<String> communicationStyles = const <String>[],
    String? surface,
  }) async {
    feedRequests += 1;
    return const DiscoverApiResult.success(
      DiscoverFeedPage(profiles: <Map<String, dynamic>>[], hasMore: false),
      statusCode: 200,
    );
  }

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> filters,
  ) async {
    updates += 1;
    return DiscoverApiResult.success(filters, statusCode: 200);
  }
}

class _DelayedFilterFlowApi extends _FilterFlowApi {
  final Completer<DiscoverApiResult<Map<String, dynamic>>> saveCompleter =
      Completer<DiscoverApiResult<Map<String, dynamic>>>();

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> filters,
  ) {
    updates += 1;
    return saveCompleter.future;
  }
}

class _NewUserFilterFlowApi extends _FilterFlowApi {
  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> getFilters() async =>
      const DiscoverApiResult.success(<String, dynamic>{
        'minAge': 18,
        'maxAge': 45,
        'maxDistanceKm': 80,
        'minScore': 0,
        'city': '',
        'datingIntentions': <String>[],
        'hometown': <String>[],
        'lifestyleTags': <String>[],
        'languages': <String>[],
        'verifiedOnly': true,
      }, statusCode: 200);
}

void main() {
  Future<void> pumpFilters(
    WidgetTester tester, {
    Size size = const Size(320, 700),
    DiscoverApiService? apiService,
    MatchLocationService? locationService,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: AdvancedFiltersScreen(
          key: UniqueKey(),
          apiService: apiService ?? _SuccessfulDiscoverApi(),
          locationService: locationService,
        ),
        routes: {
          '/browse': (_) =>
              const Scaffold(body: Center(child: Text('Discover route'))),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('distance filter explains and explicitly enables location', (
    tester,
  ) async {
    final location = _FakeMatchLocationService(
      const MatchLocationResult(
        MatchLocationOutcome.enabled,
        'Current location enabled for distance matching.',
      ),
    );
    await pumpFilters(tester, locationService: location);
    final state = find.byKey(const ValueKey('filters-location-matching-state'));
    await tester.ensureVisible(state);
    expect(
      find.textContaining('Enable location to use distance matching'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('filters-use-current-location')),
    );
    await tester.pumpAndSettle();
    expect(location.calls, 1);
    expect(
      find.textContaining('Distance matching is using your saved current'),
      findsOneWidget,
    );
    expect(find.textContaining('23.0225'), findsNothing);
    expect(find.textContaining('72.5714'), findsNothing);
  });

  Future<void> updateMultiSelect(
    WidgetTester tester,
    Finder selector,
    List<String> options,
  ) async {
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    for (final option in options) {
      final optionFinder = find.byKey(ValueKey('amoraa-select-option-$option'));
      final optionList = find.byKey(const ValueKey('amoraa-select-options'));
      final optionScrollable = find.descendant(
        of: optionList,
        matching: find.byType(Scrollable),
      );
      if (optionFinder.hitTestable().evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          optionFinder,
          120,
          scrollable: optionScrollable,
        );
      }
      final viewportTop = tester.getTopLeft(optionList).dy + 8;
      final viewportBottom = tester.getBottomRight(optionList).dy - 8;
      final optionTop = tester.getTopLeft(optionFinder).dy;
      final optionBottom = tester.getBottomRight(optionFinder).dy;
      final position = tester.state<ScrollableState>(optionScrollable).position;
      if (optionBottom > viewportBottom) {
        position.jumpTo(
          (position.pixels + optionBottom - viewportBottom).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      } else if (optionTop < viewportTop) {
        position.jumpTo(
          (position.pixels - (viewportTop - optionTop)).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      }
      await tester.pump();
      await tester.tap(optionFinder);
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('amoraa-select-done')));
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

  testWidgets('preference summary keeps premium alignment at mobile widths', (
    tester,
  ) async {
    for (final width in <double>[320, 390]) {
      await pumpFilters(
        tester,
        size: Size(width, 760),
        apiService: _SinglePreferenceDiscoverApi(),
      );

      final card = tester.getRect(
        find.byKey(const ValueKey('filters-preference-summary')),
      );
      final icon = tester.getRect(
        find.byKey(const ValueKey('filters-preference-summary-icon')),
      );
      final title = tester.getRect(
        find.byKey(const ValueKey('filters-preference-summary-title-1')),
      );
      final description = tester.getRect(
        find.byKey(const ValueKey('filters-preference-summary-description')),
      );
      final chip = tester.getRect(
        find.byKey(const ValueKey('selected-preference-trust-verified only')),
      );

      expect(find.text('1 preference selected'), findsOneWidget);
      expect(icon.size, const Size.square(32));
      expect(title.left - icon.right, closeTo(10, .01));
      expect(title.center.dy, closeTo(icon.center.dy, 1));
      expect(icon.left - card.left, closeTo(17, .01));
      expect(card.right - title.right, greaterThanOrEqualTo(16));
      expect(description.top - icon.bottom, closeTo(8, .01));
      expect(chip.top - description.bottom, closeTo(12, .01));
      expect(card.bottom - chip.bottom, closeTo(17, .01));
      expect(tester.takeException(), isNull);
    }
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

  testWidgets(
    'duplicate API preferences normalize and keep domain keys unique',
    (tester) async {
      final api = _DuplicatePreferenceDiscoverApi();
      await pumpFilters(tester, size: const Size(430, 850), apiService: api);

      final city = find.byKey(
        const ValueKey('selected-preference-city-ahmedabad'),
      );
      final hometown = find.byKey(
        const ValueKey('selected-preference-hometown-ahmedabad'),
      );
      expect(city, findsOneWidget);
      expect(hometown, findsOneWidget);
      expect(find.text('7 preferences selected'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('selected-preferences-more')));
      await tester.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('selected-preferences-sheet'));
      final homeGroup = find.descendant(
        of: sheet,
        matching: find.text('Hometown'),
      );
      expect(homeGroup, findsOneWidget);
      final homeAhmedabad = find.descendant(
        of: sheet,
        matching: find.text('Ahmedabad'),
      );
      expect(homeAhmedabad, findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.byKey(const ValueKey('selected-preferences-close')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
      await tester.pumpAndSettle();
      expect(api.submittedFilters?['hometown'], <String>['Ahmedabad']);
      expect(api.submittedFilters?['datingIntentions'], <String>[
        'Long-Term Relationship',
      ]);
    },
  );

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

  testWidgets('dynamic more chip matches every selected-summary chip', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768]) {
      await pumpFilters(tester, size: Size(width, 700));

      final regular = find.byKey(
        const ValueKey('selected-preference-trust-verified only'),
      );
      final more = find.byKey(const ValueKey('selected-preferences-more'));
      expect(regular, findsOneWidget);
      expect(more, findsOneWidget);
      expect(tester.getSize(more).height, tester.getSize(regular).height);

      final regularText = tester.widget<Text>(
        find.descendant(of: regular, matching: find.text('Verified only')),
      );
      final moreText = tester.widget<Text>(
        find.descendant(of: more, matching: find.text('+3 more')),
      );
      expect(moreText.style, regularText.style);

      final regularDecoration = tester.widget<DecoratedBox>(
        find.descendant(of: regular, matching: find.byType(DecoratedBox)).first,
      );
      final moreDecoration = tester.widget<DecoratedBox>(
        find.descendant(of: more, matching: find.byType(DecoratedBox)).first,
      );
      expect(moreDecoration.decoration, regularDecoration.decoration);
      expect(
        find.bySemanticsLabel(RegExp('Show 3 more selected filters')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('education supports multiple unique selections and removal', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 850));
    final career = find.byKey(const ValueKey('filters-section-toggle-career'));
    await tester.ensureVisible(career);
    await tester.tap(career);
    await tester.pumpAndSettle();

    final selector = find.byKey(const ValueKey('filters-education-selector'));
    await updateMultiSelect(tester, selector, const [
      'Undergraduate',
      'Postgraduate',
    ]);
    expect(find.text('9 preferences selected'), findsOneWidget);
    expect(
      find.descendant(of: selector, matching: find.text('2 selected')),
      findsOneWidget,
    );

    await updateMultiSelect(tester, selector, const ['Undergraduate']);
    expect(find.text('8 preferences selected'), findsOneWidget);
    expect(
      find.descendant(of: selector, matching: find.text('Postgraduate')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all three shared habit groups support multi-select and reset', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 850));
    final habits = find.byKey(const ValueKey('filters-section-toggle-habits'));
    await tester.ensureVisible(habits);
    await tester.tap(habits);
    await tester.pumpAndSettle();

    final selectors = <Finder>[
      find.byKey(const ValueKey('filters-smoking-selector')),
      find.byKey(const ValueKey('filters-drinking-selector')),
      find.byKey(const ValueKey('filters-weed-selector')),
    ];
    for (final selector in selectors) {
      await updateMultiSelect(tester, selector, const ['Yes', 'Sometimes']);
      expect(
        find.descendant(of: selector, matching: find.text('2 selected')),
        findsOneWidget,
      );
    }
    expect(find.text('13 preferences selected'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('filters-bottom-reset')));
    await tester.pumpAndSettle();
    for (final selector in selectors) {
      expect(
        find.descendant(of: selector, matching: find.text('Any')),
        findsOneWidget,
      );
    }
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

    await tester.tap(find.byKey(const ValueKey('amoraa-select-option-Surat')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: citySelector, matching: find.text('Surat')),
      findsOneWidget,
    );
    expect(find.text('7 preferences selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dating intentions retain multiple values and remove one only', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(390, 844));
    final selector = find.byKey(const ValueKey('filters-intention-selector'));

    await updateMultiSelect(tester, selector, const ['Marriage Minded']);
    expect(
      find.descendant(of: selector, matching: find.text('2 selected')),
      findsOneWidget,
    );
    expect(find.text('8 preferences selected'), findsOneWidget);

    await updateMultiSelect(tester, selector, const ['Long-Term Relationship']);
    expect(
      find.descendant(of: selector, matching: find.text('Marriage Minded')),
      findsOneWidget,
    );
    expect(find.text('7 preferences selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing wrap groups retain independent multi-selections', (
    tester,
  ) async {
    await pumpFilters(tester, size: const Size(430, 900));
    final lifestyle = find.byKey(const ValueKey('filters-section-lifestyle'));
    await tester.ensureVisible(lifestyle);

    for (final option in const ['Travel Companion', 'Adventure Seeker']) {
      final chip = find.byKey(
        ValueKey('filter-option-${option.toLowerCase()}'),
      );
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
    }

    expect(find.text('9 preferences selected'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('amoraa-select-done')));
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

  testWidgets('apply and reopen filters repeatedly without route exceptions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _FilterFlowApi();

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: BrowseGridScreen(apiService: api),
        onGenerateRoute: (settings) {
          if (settings.name == AdvancedFiltersScreen.routeName) {
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => AdvancedFiltersScreen(apiService: api),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    for (var cycle = 0; cycle < 10; cycle += 1) {
      await tester.tap(find.byKey(const ValueKey('discover-filters-button')));
      await tester.pumpAndSettle();
      expect(find.byType(AdvancedFiltersScreen), findsOneWidget);

      final ageSlider = find.byKey(const ValueKey('filters-age-range-slider'));
      await tester.ensureVisible(ageSlider);
      await tester.drag(ageSlider, const Offset(32, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
      await tester.pumpAndSettle();

      expect(find.byType(BrowseGridScreen), findsOneWidget);
      expect(api.updates, cycle + 1);
      expect(tester.takeException(), isNull);
    }
    expect(api.feedRequests, 11);
  });

  testWidgets('new-user defaults open, select, apply and refresh Discover', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _NewUserFilterFlowApi();

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: BrowseGridScreen(apiService: api),
        onGenerateRoute: (settings) {
          if (settings.name == AdvancedFiltersScreen.routeName) {
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => AdvancedFiltersScreen(apiService: api),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discover-filters-button')));
    await tester.pumpAndSettle();
    expect(find.byType(AdvancedFiltersScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('selected-preferences-more')),
      findsNothing,
    );

    final citySelector = find.byKey(const ValueKey('filters-city-selector'));
    await tester.ensureVisible(citySelector);
    await tester.tap(citySelector);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('amoraa-select-option-Ahmedabad')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
    await tester.pumpAndSettle();

    expect(find.byType(BrowseGridScreen), findsOneWidget);
    expect(api.updates, 1);
    expect(api.feedRequests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double Apply while saving submits once and pops once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _DelayedFilterFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: BrowseGridScreen(apiService: api),
        onGenerateRoute: (settings) {
          if (settings.name == AdvancedFiltersScreen.routeName) {
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => AdvancedFiltersScreen(apiService: api),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('discover-filters-button')));
    await tester.pumpAndSettle();
    final apply = find.byKey(const ValueKey('filters-apply-button'));
    await tester.tap(apply);
    await tester.pump();
    expect(api.updates, 1);
    await tester.tap(apply, warnIfMissed: false);
    await tester.pump();
    expect(api.updates, 1);

    api.saveCompleter.complete(
      const DiscoverApiResult.success(<String, dynamic>{}, statusCode: 200),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdvancedFiltersScreen), findsNothing);
    expect(api.feedRequests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar and system back discard edits without saving', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _FilterFlowApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: BrowseGridScreen(apiService: api),
        onGenerateRoute: (settings) {
          if (settings.name == AdvancedFiltersScreen.routeName) {
            return MaterialPageRoute<bool>(
              settings: settings,
              builder: (_) => AdvancedFiltersScreen(apiService: api),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    for (var cycle = 0; cycle < 2; cycle += 1) {
      await tester.tap(find.byKey(const ValueKey('discover-filters-button')));
      await tester.pumpAndSettle();
      final verified = find.widgetWithText(
        SwitchListTile,
        'Verified profiles only',
      );
      await tester.ensureVisible(verified);
      await tester.tap(verified);
      await tester.pump();
      if (cycle == 0) {
        await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.byType(AdvancedFiltersScreen), findsNothing);
      expect(api.updates, 0);
      expect(api.feedRequests, 1);
      expect(tester.takeException(), isNull);
    }
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
      const Size(1024, 1100),
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
