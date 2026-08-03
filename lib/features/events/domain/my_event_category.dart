import 'package:amora_ai/features/events/domain/event_models.dart';

enum MyEventCategory { upcoming, past, waitlist, cancelled }

MyEventCategory classifyEventForUser(
  UserEventRegistration registration, {
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  return switch (registration.status) {
    TicketStatus.cancelled => MyEventCategory.cancelled,
    TicketStatus.waitlisted => MyEventCategory.waitlist,
    TicketStatus.attended => MyEventCategory.past,
    TicketStatus.upcoming =>
      eventEndDateTime(
            registration.event,
            relativeTo: effectiveNow,
          ).isAfter(effectiveNow)
          ? MyEventCategory.upcoming
          : MyEventCategory.past,
  };
}

List<UserEventRegistration> sortMyEvents(
  Iterable<UserEventRegistration> registrations,
  MyEventCategory category, {
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final result = registrations
      .where(
        (registration) =>
            classifyEventForUser(registration, now: effectiveNow) == category,
      )
      .toList(growable: true);
  result.sort((a, b) {
    final aStart = eventStartDateTime(a.event, relativeTo: effectiveNow);
    final bStart = eventStartDateTime(b.event, relativeTo: effectiveNow);
    return switch (category) {
      MyEventCategory.upcoming ||
      MyEventCategory.waitlist => aStart.compareTo(bStart),
      MyEventCategory.past => bStart.compareTo(aStart),
      MyEventCategory.cancelled => (b.cancelledAt ?? bStart).compareTo(
        a.cancelledAt ?? aStart,
      ),
    };
  });
  return List<UserEventRegistration>.unmodifiable(result);
}

DateTime eventStartDateTime(EventModel event, {DateTime? relativeTo}) {
  if (event.startAt case final startAt?) return startAt;
  final reference = relativeTo ?? DateTime.now();
  final parts = event.date.replaceAll(',', '').split(RegExp(r'\s+'));
  const months = <String, int>{
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };
  final day = parts.length >= 3 ? int.tryParse(parts[1]) : null;
  final month = parts.length >= 3 ? months[parts[2]] : null;
  final time = _parseTime(event.time);
  if (day == null || month == null) {
    return DateTime(
      reference.year,
      reference.month,
      reference.day,
      time.$1,
      time.$2,
    ).add(const Duration(days: 1));
  }
  var occurrence = DateTime(reference.year, month, day, time.$1, time.$2);
  if (!occurrence.add(const Duration(hours: 3)).isAfter(reference)) {
    occurrence = DateTime(reference.year + 1, month, day, time.$1, time.$2);
  }
  return occurrence;
}

DateTime eventEndDateTime(EventModel event, {DateTime? relativeTo}) =>
    event.endAt ??
    eventStartDateTime(
      event,
      relativeTo: relativeTo,
    ).add(const Duration(hours: 3));

(int, int) _parseTime(String value) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return (12, 0);
  var hour = int.tryParse(match.group(1) ?? '') ?? 12;
  final minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final period = (match.group(3) ?? '').toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return (hour, minute);
}
