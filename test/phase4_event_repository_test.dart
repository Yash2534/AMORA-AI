import 'dart:typed_data';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventRemote implements EventRemoteDataSource {
  final Map<String, Object> responses = {};
  final List<String> calls = [];
  Map<String, dynamic>? lastBody;
  Map<String, String>? lastFields;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add('$method $path');
    lastBody = body;
    final value = responses['$method $path'] ?? responses['$method *'];
    if (value is Exception) throw value;
    return (value as Map).cast<String, dynamic>();
  }

  @override
  Future<Map<String, dynamic>> uploadFeedback(
    String path,
    AmoraPickedMedia media,
    Map<String, String> fields,
  ) async {
    calls.add('UPLOAD $path');
    lastFields = fields;
    final value = responses['UPLOAD $path'];
    if (value is Exception) throw value;
    return (value as Map).cast<String, dynamic>();
  }
}

Map<String, dynamic> _event({
  String id = '10',
  String title = 'MySQL Event',
  bool registered = false,
  bool waitlisted = false,
  bool checkedIn = false,
  String? registrationStatus,
}) => {
  'id': id,
  'title': title,
  'description': 'Canonical backend description',
  'category': 'Coffee Meetup',
  'city': 'Ahmedabad',
  'venueName': 'Backend Venue',
  'address': 'Backend address',
  'latitude': null,
  'longitude': null,
  'startDateTime': '2026-09-01T12:00:00.000Z',
  'endDateTime': '2026-09-01T15:00:00.000Z',
  'capacity': 20,
  'registeredCount': 4,
  'seatsLeft': 16,
  'waitlistCapacity': 5,
  'waitlistCount': 1,
  'available': true,
  'waitlistAvailable': true,
  'status': 'published',
  'heroImageUrl': '/uploads/events/10.jpg',
  'price': 599,
  'dressCode': 'Smart casual',
  'ageRange': '21-45',
  'language': 'English',
  'agenda': [
    {'time': '18:00', 'title': 'Welcome'},
  ],
  'facilities': ['Parking'],
  'interests': ['Coffee'],
  'host': {'id': '1', 'name': 'Backend Host', 'verified': true},
  'participation': {
    'registered': registered,
    'waitlisted': waitlisted,
    'checkedIn': checkedIn,
    'registrationStatus': registrationStatus,
    'waitlistStatus': waitlisted ? 'waiting' : null,
  },
};

Map<String, dynamic> _list(List<Map<String, dynamic>> events) => {
  'success': true,
  'data': {
    'events': events,
    'pagination': {
      'page': 1,
      'limit': 20,
      'total': events.length,
      'hasMore': false,
      'nextPage': null,
    },
  },
};

void main() {
  test(
    'browse sends filters to API and maps canonical backend fields',
    () async {
      final remote = _FakeEventRemote();
      remote.responses['GET *'] = _list([_event()]);
      final repository = EventRepository(remote: remote);

      final page = await repository.browse(
        search: 'coffee',
        category: 'Coffee Meetup',
        city: 'Ahmedabad',
        limit: 20,
      );

      expect(page.events, hasLength(1));
      expect(page.events.single.title, 'MySQL Event');
      expect(page.events.single.description, 'Canonical backend description');
      expect(page.events.single.venue, 'Backend Venue');
      expect(page.events.single.compatibility, 0);
      expect(remote.calls.single, contains('/api/events?'));
      expect(remote.calls.single, contains('search=coffee'));
      expect(remote.calls.single, contains('category=Coffee+Meetup'));
      expect(remote.calls.single, contains('city=Ahmedabad'));
    },
  );

  test('detail and My Events preserve server participation state', () async {
    final remote = _FakeEventRemote();
    remote.responses['GET /api/events/10'] = {
      'success': true,
      'data': {'event': _event(registered: true)},
    };
    remote.responses['GET *'] = _list([
      _event(registered: true),
      _event(id: '11', title: 'Waitlisted', waitlisted: true),
    ]);
    final repository = EventRepository(remote: remote);

    expect(
      (await repository.detail('10')).participationStatus,
      TicketStatus.upcoming,
    );
    final controller = EventParticipationController(repository: repository);
    await controller.loadMyEvents();
    expect(controller.statusFor('10'), TicketStatus.upcoming);
    expect(controller.statusFor('11'), TicketStatus.waitlisted);
    expect(controller.hasLoadError, false);
  });

  test('participation operations use authenticated event endpoints', () async {
    final remote = _FakeEventRemote();
    remote.responses['POST /api/events/10/registration'] = {
      'success': true,
      'data': {
        'participation': {'registered': true},
      },
    };
    remote.responses['DELETE /api/events/10/registration'] = {
      'success': true,
      'data': {
        'participation': {
          'registered': false,
          'registrationStatus': 'cancelled',
        },
      },
    };
    final repository = EventRepository(remote: remote);

    expect(await repository.register('10'), TicketStatus.upcoming);
    expect(await repository.cancelRegistration('10'), TicketStatus.cancelled);
    expect(remote.calls, [
      'POST /api/events/10/registration',
      'DELETE /api/events/10/registration',
    ]);
  });

  test(
    'API failures are surfaced and never replaced by dummy events',
    () async {
      final remote = _FakeEventRemote();
      remote.responses['GET *'] = const AuthException('Database unavailable');
      final repository = EventRepository(remote: remote);

      await expectLater(repository.browse(), throwsA(isA<AuthException>()));
    },
  );

  test(
    'feedback photo and fields use the authenticated multipart path',
    () async {
      final remote = _FakeEventRemote();
      remote.responses['UPLOAD /api/events/10/feedback'] = {
        'success': true,
        'data': {
          'feedback': {'id': '1'},
        },
      };
      final repository = EventRepository(remote: remote);
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff]);

      await repository.submitFeedback(
        eventId: '10',
        rating: 5,
        venueRating: 4,
        feedbackText: 'Persist this',
        recommend: true,
        media: AmoraPickedMedia(
          dataUri: '',
          name: 'event.jpg',
          byteLength: bytes.length,
          bytes: bytes,
          mimeType: 'image/jpeg',
        ),
      );

      expect(remote.calls, ['UPLOAD /api/events/10/feedback']);
      expect(remote.lastFields?['rating'], '5');
      expect(remote.lastFields?['feedbackText'], 'Persist this');
    },
  );

  test('group messages map persisted sender and timestamp fields', () async {
    final remote = _FakeEventRemote();
    remote.responses['GET *'] = {
      'success': true,
      'data': {
        'messages': [
          {
            'id': '7',
            'eventId': '10',
            'type': 'text',
            'text': 'Stored in MySQL',
            'createdAt': '2026-08-11T10:00:00.000Z',
            'sender': {'id': '2', 'name': 'Member', 'verified': true},
          },
        ],
      },
    };
    final repository = EventRepository(remote: remote);

    final messages = await repository.groupMessages('10');
    expect(messages.single.text, 'Stored in MySQL');
    expect(messages.single.senderName, 'Member');
    expect(messages.single.verified, true);
  });

  test(
    'host dashboard is loaded from its authenticated API response',
    () async {
      final remote = _FakeEventRemote();
      remote.responses['GET /api/host/dashboard'] = {
        'success': true,
        'data': {
          'events': [_event()],
        },
      };
      final repository = EventRepository(remote: remote);

      final events = await repository.hostDashboard();
      expect(events.single.title, 'MySQL Event');
      expect(remote.calls, ['GET /api/host/dashboard']);
    },
  );
}
