import 'dart:io';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

enum _StoredValue { longTermRelationship, friendshipFirst }

void main() {
  Future<void> pumpSelector(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool settle = true,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SafeArea(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('standard selector opens, selects, and renders its label', (
    tester,
  ) async {
    String? selected;
    await pumpSelector(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AmoraaSelectField<String>(
          key: const ValueKey('standard-selector'),
          label: 'Education',
          value: selected,
          hintText: 'Select education',
          options: const [
            AmoraaSelectOption(value: 'graduate', label: 'Graduate'),
            AmoraaSelectOption(value: 'mba', label: 'MBA'),
          ],
          onChanged: (value) => setState(() => selected = value),
        ),
      ),
    );

    expect(find.text('Select education'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('standard-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('amoraa-select-option-MBA')));
    await tester.pumpAndSettle();

    expect(selected, 'mba');
    expect(find.text('MBA'), findsOneWidget);
    expect(find.text('mba'), findsNothing);
  });

  testWidgets('searchable selector filters and explains empty results', (
    tester,
  ) async {
    await pumpSelector(
      tester,
      AmoraaSearchableSelect<String>(
        key: const ValueKey('searchable-selector'),
        label: 'Occupation',
        options: const [
          AmoraaSelectOption(value: 'doctor', label: 'Doctor'),
          AmoraaSelectOption(value: 'engineer', label: 'Engineer'),
          AmoraaSelectOption(value: 'designer', label: 'Designer'),
        ],
        onChanged: (_) {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('searchable-selector')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('amoraa-select-search')),
      'engi',
    );
    await tester.pump();
    expect(find.text('Engineer'), findsOneWidget);
    expect(find.text('Doctor'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('amoraa-select-search')),
      'not present',
    );
    await tester.pump();
    expect(find.text('No results found'), findsOneWidget);
    expect(find.text('Try a different search.'), findsOneWidget);
  });

  testWidgets('display labels hide internal enum values', (tester) async {
    await pumpSelector(
      tester,
      AmoraaSelectField<_StoredValue>(
        label: 'Dating Intention',
        value: _StoredValue.longTermRelationship,
        options: const [
          AmoraaSelectOption(
            value: _StoredValue.longTermRelationship,
            label: 'Long-Term Relationship',
          ),
          AmoraaSelectOption(
            value: _StoredValue.friendshipFirst,
            label: 'Friendship First',
          ),
        ],
        onChanged: (_) {},
      ),
    );

    expect(find.text('Long-Term Relationship'), findsOneWidget);
    expect(find.textContaining('longTermRelationship'), findsNothing);
  });

  testWidgets('disabled, loading, read-only, and error states are explicit', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    String? selected;
    await pumpSelector(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Form(
          key: formKey,
          child: Column(
            children: [
              AmoraaSelectField<String>(
                key: const ValueKey('validated-selector'),
                label: 'Religion',
                value: selected,
                isRequired: true,
                options: const [
                  AmoraaSelectOption(value: 'Hindu', label: 'Hindu'),
                ],
                validator: (value) =>
                    value == null ? 'Religion is required' : null,
                onChanged: (value) => setState(() => selected = value),
              ),
              const SizedBox(height: 8),
              AmoraaSelectField<String>(
                key: const ValueKey('disabled-selector'),
                label: 'Disabled',
                enabled: false,
                value: 'value',
                options: const [
                  AmoraaSelectOption(value: 'value', label: 'Readable value'),
                ],
                onChanged: _ignoreString,
              ),
            ],
          ),
        ),
      ),
      size: const Size(390, 720),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Religion is required'), findsOneWidget);
    expect(find.text('Readable value'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('disabled-selector')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('amoraa-select-sheet')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('validated-selector')));
    await tester.pumpAndSettle();
    final hindu = find.byKey(const ValueKey('amoraa-select-option-Hindu'));
    await tester.ensureVisible(hindu);
    await tester.tap(hindu);
    await tester.pumpAndSettle();
    expect(find.text('Religion is required'), findsNothing);

    await pumpSelector(
      tester,
      Column(
        children: [
          AmoraaSelectField<String>(
            label: 'Loading',
            isLoading: true,
            options: const [],
            onChanged: _ignoreString,
          ),
          const SizedBox(height: 8),
          AmoraaSelectField<String>(
            label: 'Read only',
            readOnly: true,
            value: 'saved',
            options: const [
              AmoraaSelectOption(value: 'saved', label: 'Saved value'),
            ],
            onChanged: _ignoreString,
          ),
        ],
      ),
      size: const Size(390, 720),
      settle: false,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Saved value'), findsOneWidget);
  });

  testWidgets('long labels and selector surfaces fit every target width', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      await pumpSelector(
        tester,
        AmoraaSelectField<String>(
          key: ValueKey('responsive-selector-$width'),
          label: 'A deliberately long selector field label',
          value: 'long',
          options: const [
            AmoraaSelectOption(
              value: 'long',
              label:
                  'A deliberately long selected option that must truncate safely',
            ),
          ],
          onChanged: (_) {},
        ),
        size: Size(width, 760),
        textScale: 1.3,
      );
      final selector = find.byKey(ValueKey('responsive-selector-$width'));
      expect(tester.getSize(selector).width, lessThanOrEqualTo(width - 32));
      await tester.tap(selector);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('amoraa-select-sheet')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Overflow at $width px');
      await tester.tap(find.byKey(const ValueKey('amoraa-select-close')));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('keyboard opens, navigates, selects, and Escape closes', (
    tester,
  ) async {
    String? selected;
    await pumpSelector(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AmoraaSelectField<String>(
          key: const ValueKey('keyboard-selector'),
          label: 'Sort',
          value: selected,
          options: const [
            AmoraaSelectOption(value: 'recommended', label: 'Recommended'),
            AmoraaSelectOption(value: 'newest', label: 'Newest'),
          ],
          onChanged: (value) => setState(() => selected = value),
        ),
      ),
      size: const Size(1024, 760),
    );

    await tester.tap(find.byKey(const ValueKey('keyboard-selector')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('amoraa-select-sheet')), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('amoraa-select-sheet')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 'newest');
  });

  test(
    'active frontend rejects legacy dropdown APIs and extra choice chips',
    () {
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      const legacyApis = <String>[
        'DropdownButton',
        'DropdownButtonFormField',
        'DropdownMenu',
        'PopupMenuButton',
        'MenuAnchor',
      ];
      final legacyMatches = <String>[];
      final choiceChipFiles = <String>[];
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        for (final api in legacyApis) {
          if (source.contains(api)) legacyMatches.add('${file.path}: $api');
        }
        if (source.contains('ChoiceChip(')) choiceChipFiles.add(file.path);
      }

      expect(legacyMatches, isEmpty);
      expect(choiceChipFiles, hasLength(1));
      expect(
        choiceChipFiles.single.replaceAll('\\', '/'),
        endsWith('profile/presentation/widgets/amoraa_profile_fields.dart'),
      );
      final selectorSource = File(
        'lib/core/widgets/amoraa_select_field.dart',
      ).readAsStringSync();
      expect(selectorSource, isNot(contains('routeName')));
      expect(selectorSource, isNot(contains('class AmoraaSelectScreen')));
    },
  );
}

void _ignoreString(String? _) {}
