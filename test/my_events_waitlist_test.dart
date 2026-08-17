import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AmoraSession.isLoggedIn.value = false);

  testWidgets(
    'My Events restores the Waitlist tab and existing status action',
    (tester) async {
      final controller = EventParticipationController();
      controller.joinWaitlist(events.first);

      await tester.pumpWidget(
        MaterialApp(home: MyEventsScreen(controller: controller)),
      );

      final waitlistTab = find.byKey(const ValueKey('my-events-tab-waitlist'));
      expect(waitlistTab, findsOneWidget);
      expect(find.text('Waitlist (1)'), findsOneWidget);

      await tester.tap(waitlistTab);
      await tester.pumpAndSettle();

      expect(find.text('You’re on the waitlist'), findsOneWidget);
      expect(find.text('Leave waitlist'), findsOneWidget);
      expect(find.text('Join Waitlist'), findsNothing);

      await tester.tap(find.text('Leave waitlist'));
      await tester.pumpAndSettle();

      expect(find.text('Waitlist (0)'), findsOneWidget);
      expect(find.text('No waitlisted events'), findsOneWidget);
    },
  );

  testWidgets('Waitlist action is API-driven and only shown when available', (
    tester,
  ) async {
    final remote = _WaitlistRemote();
    final controller = EventParticipationController(
      repository: EventRepository(remote: remote),
    );
    final event = _fullEvent(waitlistAvailable: true);
    AmoraSession.isLoggedIn.value = true;

    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(event: event, controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Join Waitlist'), findsOneWidget);
    expect(find.text('Join Event'), findsNothing);
    await tester.tap(find.text('Join Waitlist'));
    await tester.pump();
    expect(remote.calls, ['POST /api/events/${event.id}/waitlist']);
    expect(controller.statusFor(event.id), isNull);

    remote.completeJoin();
    await tester.pump(const Duration(milliseconds: 700));
    expect(controller.statusFor(event.id), TicketStatus.waitlisted);
    expect(find.text('Waitlisted'), findsWidgets);

    final unavailable = _fullEvent(waitlistAvailable: false);
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(
          key: const ValueKey('unavailable-waitlist-detail'),
          event: unavailable,
          controller: EventParticipationController(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Join Waitlist'), findsNothing);
    expect(find.text('Event Full'), findsOneWidget);
  });

  testWidgets('detail refresh replaces stale capacity before showing the CTA', (
    tester,
  ) async {
    final staleEvent = _availableEvent();
    final fullEvent = _fullEvent(waitlistAvailable: true);
    final repository = _DetailRepository(fullEvent);

    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailScreen(event: staleEvent, repository: repository),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.detailCalls, [staleEvent.id]);
    expect(find.text('Join Waitlist'), findsOneWidget);
    expect(find.text('Join Event'), findsNothing);
  });
}

EventModel _availableEvent() {
  final base = events.first;
  return EventModel(
    id: 'waitlist-open',
    title: base.title,
    category: base.category,
    city: base.city,
    date: base.date,
    time: base.time,
    price: base.price,
    seatsLeft: 1,
    compatibility: base.compatibility,
    image: base.image,
    organizer: base.organizer,
    venue: base.venue,
    distance: base.distance,
    dressCode: base.dressCode,
    ageRange: base.ageRange,
    language: base.language,
    palette: base.palette,
    intent: base.intent,
    interests: base.interests,
    agenda: base.agenda,
    startAt: DateTime.now().add(const Duration(days: 1)),
    endAt: DateTime.now().add(const Duration(days: 1, hours: 3)),
    description: base.description,
    capacity: 1,
    registeredCount: 0,
    waitlistCapacity: 2,
    waitlistEnabled: false,
    registrationOpen: true,
  );
}

EventModel _fullEvent({required bool waitlistAvailable}) {
  final base = events.first;
  return EventModel(
    id: waitlistAvailable ? 'waitlist-open' : 'waitlist-closed',
    title: base.title,
    category: base.category,
    city: base.city,
    date: base.date,
    time: base.time,
    price: base.price,
    seatsLeft: 0,
    compatibility: base.compatibility,
    image: base.image,
    organizer: base.organizer,
    venue: base.venue,
    distance: base.distance,
    dressCode: base.dressCode,
    ageRange: base.ageRange,
    language: base.language,
    palette: base.palette,
    intent: base.intent,
    interests: base.interests,
    agenda: base.agenda,
    startAt: DateTime.now().add(const Duration(days: 1)),
    endAt: DateTime.now().add(const Duration(days: 1, hours: 3)),
    description: base.description,
    capacity: 1,
    registeredCount: 1,
    waitlistCapacity: waitlistAvailable ? 2 : 0,
    waitlistEnabled: waitlistAvailable,
    registrationOpen: false,
  );
}

class _WaitlistRemote implements EventRemoteDataSource {
  final calls = <String>[];
  final _response = Completer<Map<String, dynamic>>();

  void completeJoin() {
    _response.complete({
      'success': true,
      'data': {
        'participation': {'waitlisted': true, 'waitlistStatus': 'waiting'},
      },
    });
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    calls.add('$method $path');
    return _response.future;
  }
}

class _DetailRepository extends EventRepository {
  _DetailRepository(this.refreshedEvent) : super(remote: _UnusedRemote());

  final EventModel refreshedEvent;
  final detailCalls = <String>[];

  @override
  Future<EventModel> detail(String eventId) async {
    detailCalls.add(eventId);
    return refreshedEvent;
  }
}

class _UnusedRemote implements EventRemoteDataSource {
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => throw UnimplementedError();
}
