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
    required this.host,
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
    this.description = '',
    this.capacity = 0,
    this.registeredCount = 0,
    this.waitlistCount = 0,
    this.waitlistCapacity = 0,
    this.eventStatus = 'published',
    this.registrationOpen = true,
    this.waitlistEnabled = false,
    this.checkedIn = false,
    this.checkInCount = 0,
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
  final EventHost host;
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
  final String description;
  final int capacity;
  final int registeredCount;
  final int waitlistCount;
  final int waitlistCapacity;
  final String eventStatus;
  final bool registrationOpen;
  final bool waitlistEnabled;
  final bool checkedIn;
  final int checkInCount;
  final List<EventAttendee> attendees;
  final TicketStatus? participationStatus;

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

class EventHost {
  const EventHost({
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

class EventReview {
  const EventReview({
    required this.name,
    required this.rating,
    required this.comment,
  });

  final String name;
  final double rating;
  final String comment;
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

class EventGroupMessage {
  const EventGroupMessage({
    required this.id,
    required this.eventId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.verified = false,
  });

  final String id;
  final String eventId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool verified;
}

enum TicketStatus { upcoming, attended, waitlisted, cancelled }
