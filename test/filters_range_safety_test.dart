import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/domain/discover_filter_ranges.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/preferences/presentation/dealbreakers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    appliedProfilePreferenceFilters.value =
        const ProfilePreferenceFilterState();
  });

  tearDown(() {
    appliedProfilePreferenceFilters.value =
        const ProfilePreferenceFilterState();
  });

  Future<void> pumpFilters(WidgetTester tester, _RangeFixtureApi api) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AmoraTheme.light(),
        home: AdvancedFiltersScreen(apiService: api),
        routes: {
          '/browse': (_) => const Scaffold(body: Text('Discover route')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Slider slider(WidgetTester tester, String key) =>
      tester.widget<Slider>(find.byKey(ValueKey(key)));

  RangeSlider ageSlider(WidgetTester tester) => tester.widget<RangeSlider>(
    find.byKey(const ValueKey('filters-age-range-slider')),
  );

  void expectEveryBoundedControlValid(WidgetTester tester) {
    for (final control in tester.widgetList<Slider>(find.byType(Slider))) {
      expect(control.value.isFinite, isTrue);
      expect(control.value, inInclusiveRange(control.min, control.max));
    }
    for (final control in tester.widgetList<RangeSlider>(
      find.byType(RangeSlider),
    )) {
      expect(control.values.start.isFinite, isTrue);
      expect(control.values.end.isFinite, isTrue);
      expect(control.values.start, inInclusiveRange(control.min, control.max));
      expect(control.values.end, inInclusiveRange(control.min, control.max));
      expect(control.values.start, lessThanOrEqualTo(control.values.end));
    }
  }

  test(
    'normalizers handle null, strings, non-finite values, and reversals',
    () {
      expect(
        normalizeFilterNumber(null, minimum: 1, maximum: 300, fallback: 80),
        80,
      );
      expect(
        normalizeFilterNumber('500', minimum: 1, maximum: 300, fallback: 80),
        300,
      );
      expect(
        normalizeFilterNumber(
          double.nan,
          minimum: 1,
          maximum: 300,
          fallback: 80,
        ),
        80,
      );
      expect(
        normalizeFilterNumber(
          double.infinity,
          minimum: 1,
          maximum: 300,
          fallback: 80,
        ),
        80,
      );
      final reversed = normalizeFilterRange(
        rawStart: 70,
        rawEnd: 10,
        minimum: 18,
        maximum: 45,
        fallbackStart: 18,
        fallbackEnd: 45,
      );
      expect(reversed.start, 18);
      expect(reversed.end, 45);
      expect(normalizeMinimumHeight(-20), 137);
      expect(normalizeMinimumHeight(999), 213);
      expect(normalizeMinimumHeight('invalid'), isNull);
    },
  );

  testWidgets('normal/default filters open with every bounded control valid', (
    tester,
  ) async {
    final api = _RangeFixtureApi(_defaults());
    await pumpFilters(tester, api);

    expect(find.text('Filters'), findsOneWidget);
    expectEveryBoundedControlValid(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale 500 distance and malformed ranges cannot crash Filters', (
    tester,
  ) async {
    final api = _RangeFixtureApi({
      ..._defaults(),
      'minAge': 99,
      'maxAge': -5,
      'maxDistanceKm': 500,
      'minScore': double.infinity,
      'minHeight': 999,
    });
    await pumpFilters(tester, api);

    final distance = slider(tester, 'filters-distance-slider');
    final compatibility = slider(tester, 'filters-compatibility-slider');
    final age = ageSlider(tester);
    expect(distance.value, 300);
    expect(distance.min, 1);
    expect(distance.max, 300);
    expect(compatibility.value, 80);
    expect(age.values, const RangeValues(18, 45));
    expectEveryBoundedControlValid(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('null and malformed persisted numerics use canonical defaults', (
    tester,
  ) async {
    final api = _RangeFixtureApi({
      ..._defaults(),
      'minAge': null,
      'maxAge': 'not-an-age',
      'maxDistanceKm': 'not-a-distance',
      'minScore': double.nan,
      'minHeight': 'not-a-height',
    });
    await pumpFilters(tester, api);

    expect(ageSlider(tester).values, const RangeValues(18, 45));
    expect(slider(tester, 'filters-distance-slider').value, 80);
    expect(slider(tester, 'filters-compatibility-slider').value, 80);
    expectEveryBoundedControlValid(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('change, reset, apply, and reopen keep normalized values', (
    tester,
  ) async {
    final api = _RangeFixtureApi({..._defaults(), 'maxDistanceKm': 500});
    await pumpFilters(tester, api);

    slider(tester, 'filters-distance-slider').onChanged?.call(126);
    ageSlider(tester).onChanged?.call(const RangeValues(21, 33));
    slider(tester, 'filters-compatibility-slider').onChanged?.call(72);
    final verifiedSwitch = tester.widgetList<Switch>(find.byType(Switch)).first;
    verifiedSwitch.onChanged?.call(false);
    await tester.pump();
    expect(slider(tester, 'filters-distance-slider').value, 126);
    expect(ageSlider(tester).values, const RangeValues(21, 33));

    await tester.tap(find.byKey(const ValueKey('filters-bottom-reset')));
    await tester.pumpAndSettle();
    expect(slider(tester, 'filters-distance-slider').value, 300);
    expect(ageSlider(tester).values, const RangeValues(18, 45));
    expectEveryBoundedControlValid(tester);

    await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
    await tester.pumpAndSettle();
    expect(api.updates.last['maxDistanceKm'], 300);
    expect(api.updates.last['minAge'], 18);
    expect(api.updates.last['maxAge'], 45);
    expect(api.updates.last['minScore'], 80);
    expect(find.text('Discover route'), findsOneWidget);

    await pumpFilters(tester, api);
    expect(slider(tester, 'filters-distance-slider').value, 300);
    expectEveryBoundedControlValid(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('load failure stays an API error and keeps safe defaults', (
    tester,
  ) async {
    final api = _RangeFixtureApi.failure('Filters service unavailable.');
    await pumpFilters(tester, api);

    expect(find.text('Filters service unavailable.'), findsOneWidget);
    expect(slider(tester, 'filters-distance-slider').value, 80);
    expectEveryBoundedControlValid(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dealbreakers also normalizes the shared stale filter fields', (
    tester,
  ) async {
    final api = _RangeFixtureApi({
      ..._defaults(),
      'minAge': 99,
      'maxAge': -10,
      'maxDistanceKm': 500,
    });
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: DealbreakersScreen(apiService: api),
      ),
    );
    await tester.pumpAndSettle();

    final range = tester.widget<RangeSlider>(find.byType(RangeSlider));
    final distance = tester.widget<Slider>(find.byType(Slider));
    expect(range.values, const RangeValues(18, 60));
    expect(distance.value, 100);
    expect(distance.value, inInclusiveRange(distance.min, distance.max));
    expect(tester.takeException(), isNull);
  });
}

class _RangeFixtureApi extends DiscoverApiService {
  _RangeFixtureApi(this.filters) : error = null;

  _RangeFixtureApi.failure(this.error) : filters = <String, dynamic>{};

  final Map<String, dynamic> filters;
  final String? error;
  final List<Map<String, dynamic>> updates = [];

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> getFilters() async {
    if (error case final message?) {
      return DiscoverApiResult.failure(message, statusCode: 503);
    }
    return DiscoverApiResult.success(
      Map<String, dynamic>.of(filters),
      statusCode: 200,
    );
  }

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> values,
  ) async {
    updates.add(Map<String, dynamic>.of(values));
    filters.addAll(values);
    return DiscoverApiResult.success(
      Map<String, dynamic>.of(filters),
      statusCode: 200,
    );
  }
}

Map<String, dynamic> _defaults() => <String, dynamic>{
  'minAge': 18,
  'maxAge': 45,
  'maxDistanceKm': 80,
  'minScore': 80,
  'city': '',
  'minHeight': null,
  'hometown': <String>[],
  'datingIntentions': <String>[],
  'lifestyleTags': <String>[],
  'languages': <String>[],
  'pronouns': <String>[],
  'qualities': <String>[],
  'preferredTalkingHours': <String>[],
  'loveLanguages': <String>[],
  'communicationStyles': <String>[],
  'verifiedOnly': true,
  'onlineNow': false,
  'hasPrompts': false,
  'hasEventInterest': false,
};
