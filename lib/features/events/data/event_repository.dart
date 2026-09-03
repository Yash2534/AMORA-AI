import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:flutter/material.dart';

class EventPage {
  const EventPage({required this.events, required this.hasMore, this.nextPage});
  final List<EventModel> events;
  final bool hasMore;
  final int? nextPage;
}

abstract interface class EventRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}

class AuthEventRemoteDataSource implements EventRemoteDataSource {
  AuthEventRemoteDataSource(this.auth);
  final AuthService auth;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => auth.authenticatedRequest(method, path, body: body);
}

class EventRepository {
  EventRepository({AuthService? auth, EventRemoteDataSource? remote})
    : _remote =
          remote ?? AuthEventRemoteDataSource(auth ?? AuthService.instance);

  static final EventRepository _instance = EventRepository();
  static EventRepository? debugOverride;
  static EventRepository get instance => debugOverride ?? _instance;
  final EventRemoteDataSource _remote;

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      (response['data'] as Map?)?.cast<String, dynamic>() ??
      <String, dynamic>{};

  Future<EventPage> browse({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? city,
    DateTime? dateFrom,
    DateTime? dateTo,
    String timing = 'all',
    bool? available,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'timing': timing,
      if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
      if (category?.trim().isNotEmpty == true) 'category': category!.trim(),
      if (city?.trim().isNotEmpty == true) 'city': city!.trim(),
      if (dateFrom != null) 'dateFrom': dateFrom.toUtc().toIso8601String(),
      if (dateTo != null) 'dateTo': dateTo.toUtc().toIso8601String(),
      if (available != null) 'available': '$available',
    };
    final response = await _remote.request(
      'GET',
      Uri(path: '/api/events', queryParameters: query).toString(),
    );
    return _page(_data(response));
  }

  Future<EventModel> detail(String eventId) async {
    final response = await _remote.request('GET', '/api/events/$eventId');
    return _event((_data(response)['event'] as Map).cast<String, dynamic>());
  }

  Future<EventPage> myEvents(
    String category, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _remote.request(
      'GET',
      Uri(
        path: '/api/events/me',
        queryParameters: {
          'category': category,
          'page': '$page',
          'limit': '$limit',
        },
      ).toString(),
    );
    return _page(_data(response));
  }

  Future<TicketStatus?> register(String eventId) =>
      _participation('POST', '/api/events/$eventId/registration');

  Future<TicketStatus?> cancelRegistration(String eventId) =>
      _participation('DELETE', '/api/events/$eventId/registration');

  Future<TicketStatus?> joinWaitlist(String eventId) =>
      _participation('POST', '/api/events/$eventId/waitlist');

  Future<TicketStatus?> leaveWaitlist(String eventId) =>
      _participation('DELETE', '/api/events/$eventId/waitlist');

  Future<TicketStatus?> _participation(String method, String path) async {
    final response = await _remote.request(method, path);
    return _status(
      ((_data(response)['participation'] as Map?) ?? const {})
          .cast<String, dynamic>(),
    );
  }

  EventPage _page(Map<String, dynamic> data) {
    final pagination =
        (data['pagination'] as Map?)?.cast<String, dynamic>() ?? const {};
    return EventPage(
      events: ((data['events'] as List?) ?? const [])
          .map((value) => _event((value as Map).cast<String, dynamic>()))
          .toList(growable: false),
      hasMore: pagination['hasMore'] == true,
      nextPage: (pagination['nextPage'] as num?)?.toInt(),
    );
  }

  EventModel _event(Map<String, dynamic> json) {
    final start = DateTime.parse(json['startDateTime'] as String).toLocal();
    final end = DateTime.parse(json['endDateTime'] as String).toLocal();
    final participation =
        (json['participation'] as Map?)?.cast<String, dynamic>() ?? const {};
    final organizer =
        (json['organizer'] as Map?)?.cast<String, dynamic>() ?? const {};
    final hero = json['heroImageUrl'] as String?;
    return EventModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      category: json['category'] as String,
      city: json['city'] as String,
      date: _date(start),
      time: _time(start),
      price: (json['price'] as num?)?.round() ?? 0,
      seatsLeft: (json['seatsLeft'] as num?)?.toInt() ?? 0,
      compatibility: 0,
      image: EventVisual(
        icon: Icons.event_rounded,
        label: json['title'] as String,
        imageUrl: hero ?? AppImages.fallbackEvent,
        assetPath: AppImages.fallbackEvent,
      ),
      organizer: EventOrganizer(
        name: organizer['name']?.toString() ?? 'AMORAA Events',
        photoAsset: organizer['imageUrl']?.toString().trim().isNotEmpty == true
            ? organizer['imageUrl'].toString()
            : AppImages.defaultAvatar,
        rating: 0,
        followers: '',
      ),
      venue: json['venueName'] as String,
      distance: '',
      dressCode: json['dressCode']?.toString() ?? 'See event details',
      ageRange: json['ageRange']?.toString() ?? 'Adults 18+',
      language: json['language']?.toString() ?? 'Not specified',
      palette: const [AppColors.primary, AppColors.secondary],
      intent: json['category'] as String,
      interests: ((json['interests'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      agenda: ((json['agenda'] as List?) ?? const [])
          .map((value) {
            if (value is Map) {
              return (
                value['time']?.toString() ?? '',
                value['title']?.toString() ?? value['label']?.toString() ?? '',
              );
            }
            return ('', value.toString());
          })
          .toList(growable: false),
      startAt: start,
      endAt: end,
      registrationDeadline: DateTime.tryParse(
        json['registrationDeadline']?.toString() ?? '',
      )?.toLocal(),
      serverRegistrationClosed: json['registrationClosed'] as bool?,
      description: json['description']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      registeredCount: (json['registeredCount'] as num?)?.toInt() ?? 0,
      waitlistCount: (json['waitlistCount'] as num?)?.toInt() ?? 0,
      waitlistCapacity: (json['waitlistCapacity'] as num?)?.toInt() ?? 0,
      eventStatus: json['status']?.toString() ?? 'published',
      registrationOpen: json['available'] == true,
      waitlistEnabled: json['waitlistAvailable'] == true,
      participationStatus: _status(participation),
    );
  }

  TicketStatus? _status(Map<String, dynamic> value) {
    if (value['waitlisted'] == true) return TicketStatus.waitlisted;
    if (value['registered'] == true) return TicketStatus.upcoming;
    if (value['registrationStatus'] == 'cancelled') {
      return TicketStatus.cancelled;
    }
    return null;
  }

  String _date(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]}';
  }

  String _time(DateTime value) {
    final period = value.hour >= 12 ? 'PM' : 'AM';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$hour:${value.minute.toString().padLeft(2, '0')} $period';
  }
}
