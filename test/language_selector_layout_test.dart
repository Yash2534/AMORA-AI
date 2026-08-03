import 'package:amora_ai/features/profile/presentation/widgets/amoraa_language_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Add language stays below left-aligned chips and count updates at 320px',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var changeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _LanguageHarness(onChanged: () => changeCount++),
            ),
          ),
        ),
      );

      final add = find.byKey(const ValueKey('add-languages-button'));
      final lastChip = find.byKey(const ValueKey('selected-language-Marathi'));
      expect(add, findsOneWidget);
      expect(find.text('Add language'), findsOneWidget);
      expect(find.text('2 selected'), findsOneWidget);
      expect(
        tester.getTopLeft(add).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(lastChip).dy),
      );
      expect(tester.getTopLeft(add).dx, lessThan(48));

      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('language-option-English')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('language-option-Gujarati')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-picker-done')));
      await tester.pumpAndSettle();

      expect(find.text('3 selected'), findsOneWidget);
      expect(changeCount, 1);

      await tester.tap(find.byTooltip('Remove Marathi'));
      await tester.pumpAndSettle();
      expect(find.text('2 selected'), findsOneWidget);
      expect(changeCount, 2);
      expect(tester.takeException(), isNull);
    },
  );
}

class _LanguageHarness extends StatefulWidget {
  const _LanguageHarness({required this.onChanged});

  final VoidCallback onChanged;

  @override
  State<_LanguageHarness> createState() => _LanguageHarnessState();
}

class _LanguageHarnessState extends State<_LanguageHarness> {
  Set<String> _languages = <String>{'English', 'Marathi'};

  @override
  Widget build(BuildContext context) {
    return AmoraaLanguageSelector(
      selectedLanguages: _languages,
      onChanged: (languages) {
        widget.onChanged();
        setState(() => _languages = languages);
      },
    );
  }
}
