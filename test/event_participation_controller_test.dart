import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/domain/my_event_category.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 4, 12);

  test('participation starts empty and one event has one category', () {
    final controller = EventParticipationController();
    final event = _scheduledEvent(
      id: 'real-action-event',
      startAt: now.add(const Duration(days: 2)),
    );

    expect(controller.registrations, isEmpty);
    controller.registerEvent(event, registeredAt: now);
    controller.registerEvent(event, registeredAt: now);
    expect(controller.registrations, hasLength(1));
    expect(controller.registrationsFor(MyEventCategory.upcoming, now: now), [
      isA<UserEventRegistration>().having(
        (entry) => entry.event.id,
        'event id',
        event.id,
      ),
    ]);

    controller.joinWaitlist(event, registeredAt: now);
    expect(
      controller.registrationsFor(MyEventCategory.upcoming, now: now),
      isEmpty,
    );
    expect(
      controller.registrationsFor(MyEventCategory.waitlist, now: now),
      hasLength(1),
    );

    controller.cancelEvent(event, cancelledAt: now);
    expect(
      controller.registrationsFor(MyEventCategory.waitlist, now: now),
      isEmpty,
    );
    expect(
      controller.registrationsFor(MyEventCategory.cancelled, now: now),
      hasLength(1),
    );
    expect(controller.registrations, hasLength(1));
  });

  test('ended confirmed event classifies as Past', () {
    final controller = EventParticipationController();
    final event = _scheduledEvent(
      id: 'completed-event',
      startAt: now.subtract(const Duration(days: 2)),
      endAt: now.subtract(const Duration(days: 2, hours: -3)),
    );

    controller.registerEvent(
      event,
      registeredAt: now.subtract(const Duration(days: 7)),
    );

    expect(
      controller.registrationsFor(MyEventCategory.past, now: now).single.event,
      same(event),
    );
    expect(
      controller.registrationsFor(MyEventCategory.upcoming, now: now),
      isEmpty,
    );
  });

  test('categories use deterministic chronological sorting', () {
    final controller = EventParticipationController();
    final soon = _scheduledEvent(
      id: 'soon',
      startAt: now.add(const Duration(days: 1)),
    );
    final later = _scheduledEvent(
      id: 'later',
      startAt: now.add(const Duration(days: 5)),
    );
    final oldPast = _scheduledEvent(
      id: 'old-past',
      startAt: now.subtract(const Duration(days: 8)),
      endAt: now.subtract(const Duration(days: 8, hours: -2)),
    );
    final recentPast = _scheduledEvent(
      id: 'recent-past',
      startAt: now.subtract(const Duration(days: 1)),
      endAt: now.subtract(const Duration(hours: 20)),
    );

    controller.registerEvent(later, registeredAt: now);
    controller.registerEvent(soon, registeredAt: now);
    controller.registerEvent(oldPast, registeredAt: now);
    controller.registerEvent(recentPast, registeredAt: now);

    expect(
      controller
          .registrationsFor(MyEventCategory.upcoming, now: now)
          .map((entry) => entry.event.id),
      ['soon', 'later'],
    );
    expect(
      controller
          .registrationsFor(MyEventCategory.past, now: now)
          .map((entry) => entry.event.id),
      ['recent-past', 'old-past'],
    );
  });

  test('leaving waitlist removes only the selected real registration', () {
    final controller = EventParticipationController();
    final first = _scheduledEvent(
      id: 'waitlist-first',
      startAt: now.add(const Duration(days: 2)),
    );
    final second = _scheduledEvent(
      id: 'waitlist-second',
      startAt: now.add(const Duration(days: 3)),
    );
    controller.joinWaitlist(first, registeredAt: now);
    controller.joinWaitlist(second, registeredAt: now);

    controller.leaveWaitlist(first.id);

    expect(controller.statusFor(first.id), isNull);
    expect(controller.statusFor(second.id), TicketStatus.waitlisted);
  });
}

EventModel _scheduledEvent({
  required String id,
  required DateTime startAt,
  DateTime? endAt,
}) {
  final base = events.first;
  return EventModel(
    id: id,
    title: 'Action-driven $id',
    category: base.category,
    city: base.city,
    date: base.date,
    time: base.time,
    price: base.price,
    seatsLeft: base.seatsLeft,
    compatibility: base.compatibility,
    image: base.image,
    host: base.host,
    venue: base.venue,
    distance: base.distance,
    dressCode: base.dressCode,
    ageRange: base.ageRange,
    language: base.language,
    palette: base.palette,
    intent: base.intent,
    interests: base.interests,
    startAt: startAt,
    endAt: endAt ?? startAt.add(const Duration(hours: 3)),
  );
}
