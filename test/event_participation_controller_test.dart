import 'dart:async';

import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/domain/my_event_category.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 4, 12);
  test(
    'registration, cancellation, and chronological categories are stable',
    () {
      final controller = EventParticipationController();
      final later = _event('later', now.add(const Duration(days: 5)));
      final soon = _event('soon', now.add(const Duration(days: 1)));
      controller.registerEvent(later, registeredAt: now);
      controller.registerEvent(soon, registeredAt: now);
      expect(
        controller
            .registrationsFor(MyEventCategory.upcoming, now: now)
            .map((entry) => entry.event.id),
        ['soon', 'later'],
      );
      controller.cancelEvent(soon, cancelledAt: now);
      expect(
        controller
            .registrationsFor(MyEventCategory.cancelled, now: now)
            .single
            .event
            .id,
        'soon',
      );
    },
  );

  test('account change clears every cached event registration', () {
    final controller = EventParticipationController();
    controller.registerEvent(_event('private-user-a-event', now));

    controller.clearSessionState();

    expect(controller.registrations, isEmpty);
    expect(controller.statusFor('private-user-a-event'), isNull);
    expect(controller.isLoading, isFalse);
    expect(controller.hasLoadError, isFalse);
  });

  test(
    'waitlist state changes only after the backend confirms success',
    () async {
      final remote = _WaitlistRemote();
      final controller = EventParticipationController(
        repository: EventRepository(remote: remote),
      );
      final event = _event('server-waitlist', now);

      final request = controller.joinWaitlistRemote(event);
      expect(controller.statusFor(event.id), isNull);

      remote.completeJoin();
      await request;
      expect(controller.statusFor(event.id), TicketStatus.waitlisted);
      expect(
        controller
            .registrationsFor(MyEventCategory.waitlist, now: now)
            .single
            .event
            .id,
        event.id,
      );
    },
  );

  test('failed waitlist response does not create frontend state', () async {
    final remote = _WaitlistRemote();
    final controller = EventParticipationController(
      repository: EventRepository(remote: remote),
    );
    final event = _event('server-waitlist', now);

    final expectation = expectLater(
      controller.joinWaitlistRemote(event),
      throwsA(isA<StateError>()),
    );
    remote.failJoin();
    await expectation;

    expect(controller.statusFor(event.id), isNull);
  });
}

class _WaitlistRemote implements EventRemoteDataSource {
  final _join = Completer<Map<String, dynamic>>();

  void completeJoin() {
    _join.complete({
      'success': true,
      'data': {
        'participation': {'waitlisted': true, 'waitlistStatus': 'waiting'},
      },
    });
  }

  void failJoin() {
    _join.completeError(StateError('Waitlist rejected'));
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    expect(method, 'POST');
    expect(path, '/api/events/server-waitlist/waitlist');
    return _join.future;
  }
}

EventModel _event(String id, DateTime startAt) {
  final base = events.first;
  return EventModel(
    id: id,
    title: id,
    category: base.category,
    city: base.city,
    date: base.date,
    time: base.time,
    price: base.price,
    seatsLeft: base.seatsLeft,
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
    startAt: startAt,
    endAt: startAt.add(const Duration(hours: 3)),
  );
}
