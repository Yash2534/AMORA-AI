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

class MyEventTicket {
  const MyEventTicket({
    required this.event,
    required this.ticketNumber,
    required this.seat,
    required this.status,
    required this.position,
    required this.estimatedEntry,
  });

  final EventModel event;
  final String ticketNumber;
  final String seat;
  final TicketStatus status;
  final int position;
  final String estimatedEntry;
}

enum TicketStatus { upcoming, attended, waitlisted, cancelled }
