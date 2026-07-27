import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final skipTestFlow = !membershipTestMode;

  setUp(() {
    if (membershipTestMode) {
      MembershipTestFlowController.instance.reset();
    }
  });

  testWidgets('monthly and annual test plans update the selected CTA', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const SubscriptionScreen()),
    );
    await tester.pumpAndSettle();
    expect(MembershipTestFlowController.instance.selectedPlan.title, 'Monthly');

    await tester.tap(find.text('Annual'));
    await tester.pumpAndSettle();
    expect(MembershipTestFlowController.instance.selectedPlan.title, 'Annual');
    await tester.scrollUntilVisible(
      find.text('Continue with Annual'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Continue with Annual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: skipTestFlow);

  testWidgets(
    'simulated success remains isolated and joined event appears in My Events',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpPayment(tester);
      await _completePayment(tester, TestPaymentOutcome.success);

      expect(find.text('Welcome to Amora Membership'), findsOneWidget);
      expect(MembershipTestFlowController.instance.membershipActive, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AmoraTheme.light(),
          home: EventDetailScreen(event: events.first),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(events.first.title), findsOneWidget);
      expect(find.byType(Hero), findsOneWidget);
      expect(find.text('Why this event may suit you'), findsOneWidget);
      expect(find.text('Safety & community'), findsOneWidget);
      await tester.tap(find.text('Join Event').first);
      await tester.pumpAndSettle();
      expect(MembershipTestFlowController.instance.joinedEventIds, isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AmoraTheme.light(),
          home: const MyEventsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Events'), findsOneWidget);
      expect(find.text('Joined'), findsWidgets);
      await tester.tap(find.text('Leave Event').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave Event').last);
      await tester.pumpAndSettle();
      expect(MembershipTestFlowController.instance.joinedEventIds, isEmpty);
      expect(tester.takeException(), isNull);
    },
    skip: skipTestFlow,
  );

  for (final scenario in const [
    (TestPaymentOutcome.failure, 'Payment wasn’t completed'),
    (TestPaymentOutcome.cancelled, 'Payment cancelled'),
    (TestPaymentOutcome.pending, 'Confirmation is pending'),
  ]) {
    testWidgets(
      '${scenario.$1.name} preserves inactive membership state',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _pumpPayment(tester);
        await _completePayment(tester, scenario.$1);

        expect(find.text(scenario.$2), findsOneWidget);
        expect(MembershipTestFlowController.instance.membershipActive, isFalse);
        expect(tester.takeException(), isNull);
      },
      skip: skipTestFlow,
    );
  }
}

Future<void> _pumpPayment(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AmoraTheme.light(),
      initialRoute: PaymentScreen.routeName,
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: RouteSettings(
          name: settings.name,
          arguments: MembershipPaymentArgs(
            plan: MembershipTestFlowController.instance.selectedPlan,
          ),
        ),
        builder: (_) => const PaymentScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _completePayment(
  WidgetTester tester,
  TestPaymentOutcome outcome,
) async {
  MembershipTestFlowController.instance.selectOutcome(outcome);

  await tester.scrollUntilVisible(
    find.text('Test Card'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Test Card'));
  await tester.scrollUntilVisible(
    find.byType(CheckboxListTile),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byType(CheckboxListTile));
  await tester.scrollUntilVisible(
    find.textContaining('Pay '),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.textContaining('Pay '));
  await tester.pump();
  expect(find.text('Confirming your membership'), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}
