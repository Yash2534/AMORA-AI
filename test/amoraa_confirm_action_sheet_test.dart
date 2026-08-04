import 'dart:async';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_confirm_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLauncher(
    WidgetTester tester, {
    required AmoraaProfileAction action,
    required String profileName,
    required FutureOr<void> Function() onConfirm,
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showAmoraaProfileActionConfirmation(
                  context: context,
                  action: action,
                  profileName: profileName,
                  onConfirm: onConfirm,
                ),
                child: const Text('Open confirmation'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
  }

  testWidgets('failure keeps the item and dialog available for Retry', (
    tester,
  ) async {
    var attempts = 0;
    var removed = false;
    await pumpLauncher(
      tester,
      action: AmoraaProfileAction.unsave,
      profileName: 'Aarohi Sharma',
      onConfirm: () {
        attempts++;
        if (attempts == 1) throw StateError('private persistence detail');
        removed = true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('confirm-action-confirm')));
    await tester.pumpAndSettle();
    expect(removed, isFalse);
    expect(find.byKey(const ValueKey('amoraa-confirm-action')), findsOneWidget);
    expect(
      find.text('Couldn\u2019t remove this saved profile.\nPlease try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private persistence detail'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('confirm-action-confirm')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(removed, isTrue);
    expect(find.byKey(const ValueKey('amoraa-confirm-action')), findsNothing);
  });

  testWidgets('loading blocks duplicate confirmation submissions', (
    tester,
  ) async {
    final completion = Completer<void>();
    var calls = 0;
    await pumpLauncher(
      tester,
      action: AmoraaProfileAction.unblock,
      profileName: 'Ishita Rao',
      onConfirm: () {
        calls++;
        return completion.future;
      },
    );

    final confirm = find.byKey(const ValueKey('confirm-action-confirm'));
    await tester.tap(confirm);
    await tester.pump();
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pump();

    expect(calls, 1);
    expect(
      find.byKey(const ValueKey('confirm-action-progress')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('confirm-action-cancel')),
          )
          .onPressed,
      isNull,
    );

    completion.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('amoraa-confirm-action')), findsNothing);
  });

  testWidgets('long real names fit every width with accessible actions', (
    tester,
  ) async {
    const name = 'Ananya Krishnamurthy Subramanian';
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      await pumpLauncher(
        tester,
        action: AmoraaProfileAction.removeSuperLike,
        profileName: name,
        onConfirm: () {},
        size: Size(width, 640),
      );

      expect(find.text('Remove Super Like from $name?'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Remove Super Like from $name'),
        findsOneWidget,
      );
      expect(find.text('Keep Super Like'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Confirmation overflowed at ${width.toInt()} px.',
      );
      await tester.tap(find.text('Keep Super Like'));
      await tester.pumpAndSettle();
    }
  });
}
