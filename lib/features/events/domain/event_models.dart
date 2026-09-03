import 'package:flutter/material.dart';

class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.city,
    required this.date,
    required this.time,
    required this.price,
    required this.seatsLeft,
    required this.compatibility,
    required this.image,
    required this.organizer,
    required this.venue,
    required this.distance,
    required this.dressCode,
    required this.ageRange,
    required this.language,
    required this.palette,
    required this.intent,
    required this.interests,
    this.agenda = const <(String, String)>[],
    this.startAt,
    this.endAt,
    this.registrationDeadline,
    this.serverRegistrationClosed,
    this.description = '',
    this.capacity = 0,
    this.registeredCount = 0,
    this.waitlistCount = 0,
    this.waitlistCapacity = 0,
    this.eventStatus = 'published',
    this.registrationOpen = true,
    this.waitlistEnabled = false,
    this.attendees = const <EventAttendee>[],
    this.participationStatus,
  });

  final String id;
  final String title;
  final String category;
  final String city;
  final String date;
  final String time;
  final int price;
  final int seatsLeft;
  final int compatibility;
  final EventVisual image;
  final EventOrganizer organizer;
  final String venue;
  final String distance;
  final String dressCode;
  final String ageRange;
  final String language;
  final List<Color> palette;
  final String intent;
  final List<String> interests;
  final List<(String, String)> agenda;
  final DateTime? startAt;
  final DateTime? endAt;

  /// Server-provided registration cutoff, shown in the viewer's local time.
  final DateTime? registrationDeadline;

  /// Authoritative availability computed by the API; local fallback supports
  /// fixture/offline data only and never authorizes a registration.
  final bool? serverRegistrationClosed;
  final String description;
  final int capacity;
  final int registeredCount;
  final int waitlistCount;
  final int waitlistCapacity;
  final String eventStatus;
  final bool registrationOpen;
  final bool waitlistEnabled;
  final List<EventAttendee> attendees;
  final TicketStatus? participationStatus;

  /// Capacity is server-owned and refreshed by the event detail request.
  bool get isFull => capacity > 0 && registeredCount >= capacity;

  bool get registrationClosed =>
      serverRegistrationClosed ??
      (registrationDeadline != null &&
          !registrationDeadline!.isAfter(DateTime.now()));

  bool get canJoinWaitlist => !registrationClosed && isFull && waitlistEnabled;

  /// Local content can contain a venue descriptor in this legacy field. Only
  /// render it as distance when it is actually a numeric kilometre value.
  bool get hasNumericDistance => RegExp(
    r'\b\d+(?:\.\d+)?\s*km\b',
    caseSensitive: false,
  ).hasMatch(distance.trim());
}

class EventVisual {
  const EventVisual({
    required this.icon,
    required this.label,
    required this.imageUrl,
    required this.assetPath,
  });

  final IconData icon;
  final String label;
  final String imageUrl;
  final String assetPath;
}

class EventOrganizer {
  const EventOrganizer({
    required this.name,
    required this.photoAsset,
    required this.rating,
    required this.followers,
  });

  final String name;
  final String photoAsset;
  final double rating;
  final String followers;
}

class EventAttendee {
  const EventAttendee({
    required this.name,
    required this.photoAsset,
    required this.intent,
    required this.verified,
  });

  final String name;
  final String photoAsset;
  final String intent;
  final bool verified;
}

class UserEventRegistration {
  const UserEventRegistration({
    required this.event,
    required this.status,
    required this.registeredAt,
    this.cancelledAt,
  });

  final EventModel event;
  final TicketStatus status;
  final DateTime registeredAt;
  final DateTime? cancelledAt;
}

enum TicketStatus { upcoming, waitlisted, cancelled }
