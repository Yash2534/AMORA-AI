import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/my_event_category.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('My Events starts empty with truthful category states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = EventParticipationController();

    await _pumpMyEvents(tester, controller);

    expect(
      find.text('Your plans, bookings, and event history.'),
      findsOneWidget,
    );
    expect(find.text('Upcoming (0)'), findsOneWidget);
    expect(find.text('Past (0)'), findsOneWidget);
    expect(find.text('Waitlist (0)'), findsOneWidget);
    expect(find.text('Cancelled (0)'), findsOneWidget);
    expect(find.text('No upcoming events'), findsOneWidget);
    expect(find.text('Events you book will appear here.'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real user actions populate one matching category with counts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = EventParticipationController();
    final upcoming = events[0];
    final waitlisted = events[1];
    final cancelled = events[2];
    final past = events[3];
    controller.registerEvent(upcoming);
    controller.joinWaitlist(waitlisted);
    controller.registerEvent(cancelled);
    controller.cancelEvent(cancelled);
    controller.markAttended(past);

    await _pumpMyEvents(tester, controller);

    expect(find.text('Upcoming (1)'), findsOneWidget);
    expect(find.text('Past (1)'), findsOneWidget);
    expect(find.text('Waitlist (1)'), findsOneWidget);
    expect(find.text('Cancelled (1)'), findsOneWidget);
    expect(find.text(upcoming.title), findsOneWidget);

    tester.widget<TabBar>(find.byType(TabBar)).controller!.animateTo(2);
    await tester.pumpAndSettle();
    expect(find.text(waitlisted.title), findsOneWidget);
    expect(find.text('You’re on the waitlist'), findsOneWidget);
    expect(find.textContaining('Position'), findsNothing);

    tester.widget<TabBar>(find.byType(TabBar)).controller!.animateTo(3);
    await tester.pumpAndSettle();
    expect(find.text(cancelled.title), findsOneWidget);
    expect(find.text('Booking cancelled'), findsOneWidget);

    tester.widget<TabBar>(find.byType(TabBar)).controller!.animateTo(1);
    await tester.pumpAndSettle();
    expect(find.text(past.title), findsOneWidget);
    expect(find.text('Event completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling a real booking moves it to Cancelled immediately', (
    tester,
  ) async {
    final controller = EventParticipationController();
    final event = events[4];
    controller.registerEvent(event);
    await _pumpMyEvents(tester, controller);

    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel booking').last);
    await tester.pumpAndSettle();

    expect(controller.countFor(MyEventCategory.upcoming), 0);
    expect(controller.countFor(MyEventCategory.cancelled), 1);
    expect(find.text('Upcoming (0)'), findsOneWidget);
    expect(find.text('Cancelled (1)'), findsOneWidget);
  });

  testWidgets('load failure shows retry without seeded event content', (
    tester,
  ) async {
    final controller = EventParticipationController()..reportLoadFailure();
    await _pumpMyEvents(tester, controller);

    expect(find.text('We couldn’t load your events'), findsOneWidget);
    expect(find.text(events.first.title), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No upcoming events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real event card keeps existing detail navigation', (
    tester,
  ) async {
    final controller = EventParticipationController();
    final event = events[5];
    controller.registerEvent(event);
    await _pumpMyEvents(tester, controller);

    await tester.tap(find.text('Open details'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text(event.title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Events stays overflow-free at every supported width', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in const [
      320.0,
      360.0,
      390.0,
      412.0,
      430.0,
      600.0,
      768.0,
      1024.0,
    ]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      final controller = EventParticipationController()
        ..registerEvent(events[7]);
      await _pumpMyEvents(tester, controller);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });
}

Future<void> _pumpMyEvents(
  WidgetTester tester,
  EventParticipationController controller,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AmoraTheme.light(),
      onGenerateRoute: (settings) {
        if (settings.name == EventDetailScreen.routeName) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => EventDetailScreen(controller: controller),
          );
        }
        return null;
      },
      home: MyEventsScreen(controller: controller),
    ),
  );
}
