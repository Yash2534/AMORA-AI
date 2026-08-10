import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiscoverApiService extends DiscoverApiService {
  _FakeDiscoverApiService(this.filters);

  final Map<String, dynamic> filters;
  final List<Map<String, dynamic>> updates = <Map<String, dynamic>>[];

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> getFilters() async =>
      DiscoverApiResult<Map<String, dynamic>>.success(
        Map<String, dynamic>.of(filters),
        statusCode: 200,
      );

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateFilters(
    Map<String, dynamic> filters,
  ) async {
    updates.add(Map<String, dynamic>.of(filters));
    this.filters.addAll(filters);
    return DiscoverApiResult<Map<String, dynamic>>.success(
      Map<String, dynamic>.of(this.filters),
      statusCode: 200,
    );
  }
}

void main() {
  setUp(() {
    appliedProfilePreferenceFilters.value =
        const ProfilePreferenceFilterState();
  });

  tearDown(() {
    appliedProfilePreferenceFilters.value =
        const ProfilePreferenceFilterState();
  });

  Future<void> pumpFilters(
    WidgetTester tester,
    _FakeDiscoverApiService api, {
    Size size = const Size(320, 700),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: AdvancedFiltersScreen(apiService: api),
        routes: {
          '/browse': (_) => const Scaffold(body: Text('Discover result')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSelector(WidgetTester tester) async {
    final compatibility = find.byKey(
      const ValueKey('filters-section-toggle-compatibility'),
    );
    await tester.ensureVisible(compatibility);
    await tester.tap(compatibility.hitTestable());
    await tester.pumpAndSettle();
    final selector = find.byKey(
      const ValueKey('filters-communication-style-selector'),
    );
    await tester.ensureVisible(selector);
    await tester.tap(selector.hitTestable());
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label) async {
    final option = find.byKey(ValueKey('amoraa-select-option-$label'));
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('amoraa-select-options')),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    for (
      var offset = 0.0;
      option.evaluate().isEmpty && offset <= position.maxScrollExtent;
      offset += 80
    ) {
      position.jumpTo(offset.clamp(0, position.maxScrollExtent));
      await tester.pump();
    }
    expect(option, findsOneWidget);
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();
  }

  test('approved values and feed query use stable API strings', () {
    expect(CommunicationStyle.values.map((style) => style.label), <String>[
      'Frequent texting',
      'Occasional texting',
      'Calls',
      'Voice notes',
      'Deep conversations',
      'Light/fun conversations',
    ]);
    expect(
      CommunicationStyle.values.map((style) => style.storageValue),
      <String>[
        'frequent_texting',
        'occasional_texting',
        'calls',
        'voice_notes',
        'deep_conversations',
        'light_fun_conversations',
      ],
    );
    expect(
      buildDiscoverFeedQuery(
        page: 2,
        limit: 10,
        communicationStyles: const <String>['calls', 'voice_notes', 'calls'],
      ),
      <String, String>{
        'page': '2',
        'limit': '10',
        'communicationStyles': 'calls,voice_notes',
      },
    );
  });

  testWidgets(
    'preloads exactly six options and preserves multi-select through Apply',
    (tester) async {
      final api = _FakeDiscoverApiService(<String, dynamic>{
        'communicationStyles': <String>['calls', 'deep_conversations'],
      });
      await pumpFilters(tester, api);

      final selector = find.byKey(
        const ValueKey('filters-communication-style-selector'),
      );
      expect(selector, findsOneWidget);
      expect(
        find.descendant(of: selector, matching: find.text('2 selected')),
        findsOneWidget,
      );
      expect(find.text('2 preferences selected'), findsOneWidget);

      await openSelector(tester);
      final sheet = tester.widget<AmoraaSelectBottomSheet<CommunicationStyle>>(
        find.byWidgetPredicate(
          (widget) => widget is AmoraaSelectBottomSheet<CommunicationStyle>,
        ),
      );
      expect(sheet.options.map((option) => option.label), [
        'Frequent texting',
        'Occasional texting',
        'Calls',
        'Voice notes',
        'Deep conversations',
        'Light/fun conversations',
      ]);
      await choose(tester, 'Voice notes');
      await choose(tester, 'Calls');
      await tester.tap(find.byKey(const ValueKey('amoraa-select-done')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: selector, matching: find.text('2 selected')),
        findsOneWidget,
      );
      expect(find.text('2 preferences selected'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
      await tester.pumpAndSettle();

      expect(api.updates, isNotEmpty);
      expect(api.updates.last['communicationStyles'], <String>[
        'voice_notes',
        'deep_conversations',
      ]);
      expect(
        appliedProfilePreferenceFilters.value.communicationStyles,
        <CommunicationStyle>{
          CommunicationStyle.voiceNotes,
          CommunicationStyle.deepConversations,
        },
      );
      expect(find.text('Discover result'), findsOneWidget);
    },
  );

  testWidgets('Reset clears local, applied, and persisted selections', (
    tester,
  ) async {
    final api = _FakeDiscoverApiService(<String, dynamic>{
      'communicationStyles': <String>['calls', 'voice_notes'],
    });
    await pumpFilters(tester, api, size: const Size(430, 800));

    await tester.tap(find.byKey(const ValueKey('filters-bottom-reset')));
    await tester.pumpAndSettle();

    final selector = find.byKey(
      const ValueKey('filters-communication-style-selector'),
    );
    await tester.ensureVisible(selector);
    expect(
      find.descendant(
        of: selector,
        matching: find.text('Any communication style'),
      ),
      findsOneWidget,
    );
    expect(appliedProfilePreferenceFilters.value.communicationStyles, isEmpty);
    expect(api.updates.last['communicationStyles'], isEmpty);
    expect(tester.takeException(), isNull);
  });
}
