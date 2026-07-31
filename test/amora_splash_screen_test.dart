import 'dart:async';

import 'package:amora_ai/features/splash/presentation/amora_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('holds completed branding until initialization finishes', (
    tester,
  ) async {
    final destination = Completer<String>();
    var resolverCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AmoraSplashScreen.routeName,
        routes: {
          AmoraSplashScreen.routeName: (_) => AmoraSplashScreen(
            resolveInitialRoute: () {
              resolverCalls += 1;
              return destination.future;
            },
          ),
          '/ready': (_) => const Scaffold(body: Text('Ready')),
        },
      ),
    );
    await tester.pump();

    expect(
      find.bySemanticsLabel('AMORAA. Love, powered by AI'),
      findsOneWidget,
    );
    expect(resolverCalls, 1);

    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('AMORAA. Love, powered by AI'),
      findsOneWidget,
    );
    expect(find.text('Ready'), findsNothing);

    destination.complete('/ready');
    await tester.pump();
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Ready'), findsOneWidget);
    expect(resolverCalls, 1);
  });

  testWidgets('stays overflow-free on compact portrait and landscape layouts', (
    tester,
  ) async {
    final destination = Completer<String>();
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 568), Size(568, 320)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
                accessibleNavigation: true,
              ),
              child: child!,
            );
          },
          home: AmoraSplashScreen(
            resolveInitialRoute: () => destination.future,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(tester.takeException(), isNull);
      expect(
        find.bySemanticsLabel('AMORAA. Love, powered by AI'),
        findsOneWidget,
      );
    }
  });
}
