import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote implements EventRemoteDataSource {
  final calls = <String>[];
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add('$method $path');
    if (path == '/api/events/10/registration') {
      return {
        'success': true,
        'data': {
          'participation': {
            'registered': method == 'POST',
            'registrationStatus': method == 'POST' ? 'registered' : 'cancelled',
          },
        },
      };
    }
    if (path == '/api/events/10/waitlist') {
      return {
        'success': true,
        'data': {
          'participation': {
            'waitlisted': method == 'POST',
            'waitlistStatus': method == 'POST' ? 'waiting' : 'left',
          },
        },
      };
    }
    return {
      'success': true,
      'data': {
        'events': [_eventJson()],
        'pagination': {'hasMore': false},
      },
    };
  }
}

Map<String, dynamic> _eventJson() => {
  'id': '10',
  'title': 'MySQL Event',
  'description': 'Persisted',
  'category': 'Coffee Meetup',
  'city': 'Ahmedabad',
  'venueName': 'Venue',
  'startDateTime': '2026-09-01T18:00:00.000Z',
  'endDateTime': '2026-09-01T21:00:00.000Z',
  'capacity': 20,
  'registeredCount': 2,
  'seatsLeft': 18,
  'waitlistCapacity': 5,
  'waitlistCount': 1,
  'available': true,
  'waitlistAvailable': false,
  'status': 'published',
  'price': 0,
  'agenda': [],
  'facilities': [],
  'interests': [],
  'organizer': {
    'name': 'AMORAA Events',
    'imageUrl': 'http://localhost:5000/uploads/organizer.jpg',
  },
  'participation': {'registered': false, 'registrationStatus': null},
};

void main() {
  test('browse maps organizer and persisted capacity', () async {
    final remote = _Remote();
    final repository = EventRepository(remote: remote);
    final event = (await repository.browse()).events.single;
    expect(remote.calls.single, 'GET /api/events?page=1&limit=20&timing=all');
    expect(event.organizer.name, 'AMORAA Events');
    expect(
      event.organizer.photoAsset,
      'http://localhost:5000/uploads/organizer.jpg',
    );
    expect(event.seatsLeft, 18);
  });

  test('registration and cancellation use the retained endpoint', () async {
    final remote = _Remote();
    final repository = EventRepository(remote: remote);
    expect(await repository.register('10'), TicketStatus.upcoming);
    expect(await repository.cancelRegistration('10'), TicketStatus.cancelled);
    expect(remote.calls, [
      'POST /api/events/10/registration',
      'DELETE /api/events/10/registration',
    ]);
  });

  test(
    'waitlist actions use the restored endpoint and persisted status',
    () async {
      final remote = _Remote();
      final repository = EventRepository(remote: remote);
      expect(await repository.joinWaitlist('10'), TicketStatus.waitlisted);
      expect(await repository.leaveWaitlist('10'), isNull);
      expect(remote.calls, [
        'POST /api/events/10/waitlist',
        'DELETE /api/events/10/waitlist',
      ]);
    },
  );
}
