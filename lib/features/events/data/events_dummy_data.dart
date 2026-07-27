import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/data/event_asset_catalog.dart';
import 'package:flutter/material.dart';

const eventCities = ['Ahmedabad', 'Gandhinagar', 'Vadodara', 'Surat', 'Rajkot'];

const eventCategories = [
  'Speed Dating',
  'Coffee Meetup',
  'Travel',
  'Rooftop',
  'Garba',
  'Workshop',
  'Premium',
];

const _aadhya = AppImages.profileAadhya;
const _aarav = AppImages.profileAarav;
const _kavya = AppImages.profileKavya;
const _riya = AppImages.profileRiya;
const _yash = AppImages.profileYash;

const eventAttendees = [
  EventAttendee(
    name: 'Aadhya',
    photoAsset: _aadhya,
    intent: 'Long-term',
    verified: true,
  ),
  EventAttendee(
    name: 'Aarav',
    photoAsset: _aarav,
    intent: 'Meaningful dates',
    verified: true,
  ),
  EventAttendee(
    name: 'Kavya',
    photoAsset: _kavya,
    intent: 'Friendship first',
    verified: true,
  ),
  EventAttendee(
    name: 'Riya',
    photoAsset: _riya,
    intent: 'Serious',
    verified: false,
  ),
  EventAttendee(
    name: 'Yash',
    photoAsset: _yash,
    intent: 'Life partner',
    verified: true,
  ),
];

const eventAgenda = [
  ('6:00 PM', 'Welcome'),
  ('6:30 PM', 'Icebreaker'),
  ('7:00 PM', 'Coffee Session'),
  ('8:00 PM', 'Networking'),
  ('9:00 PM', 'Closing'),
];

const eventFacilities = [
  (Icons.local_parking_rounded, 'Parking'),
  (Icons.coffee_rounded, 'Coffee'),
  (Icons.photo_camera_rounded, 'Photography'),
  (Icons.security_rounded, 'Security'),
  (Icons.verified_rounded, 'Verified Venue'),
];

const eventReviews = [
  EventReview(
    name: 'Nisha',
    rating: 4.9,
    comment: 'Beautifully hosted, warm crowd, and no awkward energy.',
  ),
  EventReview(
    name: 'Dev',
    rating: 4.8,
    comment: 'The compatibility curation made every conversation easier.',
  ),
];

const _dates = [
  'Sat, 18 Jul',
  'Sun, 19 Jul',
  'Fri, 24 Jul',
  'Sat, 25 Jul',
  'Sun, 26 Jul',
  'Fri, 31 Jul',
  'Sat, 1 Aug',
  'Sun, 2 Aug',
];
const _times = [
  '6:00 PM',
  '11:00 AM',
  '7:30 PM',
  '5:30 PM',
  '8:00 PM',
  '6:30 AM',
];
const _intents = [
  'Long-term relationship',
  'Meaningful dating',
  'Marriage-minded',
  'Friendship first',
  'Active companionship',
];
const _palettes = [
  [AppColors.primary, AppColors.secondary],
  [AppColors.primary, AppColors.tertiary],
  [AppColors.secondary, AppColors.secondary],
  [AppColors.secondary, AppColors.secondary],
  [AppColors.primary, AppColors.secondary],
];
const _eventInterestSets = [
  ['Coffee', 'Books', 'Slow dating'],
  ['Music', 'Food', 'City views'],
  ['Family values', 'Culture', 'Festivals'],
  ['Travel', 'Photos', 'Conversation'],
  ['Fitness', 'Nature', 'Adventure'],
];

final events = ImageRepository.events
    .asMap()
    .entries
    .map((entry) => _eventFromRepository(entry.key, entry.value))
    .toList(growable: false);

EventModel _eventFromRepository(int index, EventImageData visual) {
  final hostProfile = ImageRepository.profileAt(index + 4);
  final localAsset = EventAssetCatalog.forEvent(
    title: visual.title,
    category: visual.category,
  );
  return EventModel(
    id: visual.id,
    title: visual.title,
    category: visual.category,
    city: visual.city,
    date: _dates[index % _dates.length],
    time: _times[index % _times.length],
    price: 599 + (index * 100),
    seatsLeft: 8 + (index * 3) % 28,
    compatibility: 82 + (index * 3) % 16,
    image: EventVisual(
      icon: visual.icon,
      label: visual.title,
      imageUrl: localAsset,
      assetPath: localAsset,
    ),
    host: EventHost(
      name: visual.organizer,
      photoAsset: hostProfile.fallbackAsset,
      rating: 4.6 + ((index % 4) * .1),
      followers: '${9 + index}.4k',
    ),
    venue: visual.venue,
    distance: index.isEven ? '${(index % 8) + 2}.4 km away' : 'Curated venue',
    dressCode: index.isEven ? 'Smart casual' : 'Premium casual',
    ageRange: '${23 + (index % 4)}-${34 + (index % 7)}',
    language: 'English, Hindi, Gujarati',
    palette: _palettes[index % _palettes.length],
    intent: _intents[index % _intents.length],
    interests: _eventInterestSets[index % _eventInterestSets.length],
  );
}

final heroEvents = events.take(5).toList();
final popularEvents = [events[1], events[2], events[3], events[5]];
final recommendedEvents = [events[0], events[6], events[8]];

final myEventTickets = [
  MyEventTicket(
    event: events[0],
    ticketNumber: 'AMR-CF-1826',
    seat: 'Lounge A12',
    status: TicketStatus.upcoming,
    position: 0,
    estimatedEntry: 'Confirmed',
  ),
  MyEventTicket(
    event: events[3],
    ticketNumber: 'AMR-SR-1011',
    seat: 'Sky B04',
    status: TicketStatus.attended,
    position: 0,
    estimatedEntry: 'Completed',
  ),
  MyEventTicket(
    event: events[1],
    ticketNumber: 'AMR-PS-7720',
    seat: 'Waitlist',
    status: TicketStatus.waitlisted,
    position: 4,
    estimatedEntry: 'High chance by Friday',
  ),
  MyEventTicket(
    event: events[2],
    ticketNumber: 'AMR-CX-4092',
    seat: 'Cancelled',
    status: TicketStatus.cancelled,
    position: 0,
    estimatedEntry: 'Refund placeholder',
  ),
];
