import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/notifications/data/notification_inbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote implements NotificationInboxRemoteDataSource {
  final List<String> requests = <String>[];
  Object? failure;
  int page = 0;

  Map<String, dynamic> row(String id, {bool read = false}) => <String, dynamic>{
    'id': id,
    'type': 'match',
    'category': 'Matches',
    'title': 'Match $id',
    'message': 'Canonical message',
    'isRead': read,
    'readAt': read ? '2026-08-11T10:00:00.000Z' : null,
    'createdAt': '2026-08-11T09:00:00.000Z',
    'data': <String, dynamic>{},
  };

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    requests.add('$method $path');
    if (failure case final error?) throw error;
    if (method == 'GET') {
      page++;
      return response({
        'notifications': [row(page == 1 ? '1' : '2')],
        'unreadCount': 2,
        'pagination': {'hasMore': page == 1, 'nextPage': page == 1 ? 2 : null},
      });
    }
    if (path.endsWith('/read-all')) {
      return response({'updatedCount': 2, 'unreadCount': 0});
    }
    if (method == 'PUT') {
      return response({'notification': row('1', read: true), 'unreadCount': 1});
    }
    if (method == 'DELETE') {
      return response({'deleted': true, 'id': '1', 'unreadCount': 1});
    }
    throw StateError('Unexpected request');
  }

  Map<String, dynamic> response(Map<String, dynamic> data) => {
    'success': true,
    'data': data,
  };
}

void main() {
  test('loads and paginates canonical backend notifications', () async {
    final remote = _Remote();
    final repository = NotificationInboxRepository(remote: remote);
    addTearDown(repository.dispose);

    await repository.refresh();
    expect(repository.notifications.map((item) => item.id), ['1']);
    expect(repository.unreadCount, 2);
    expect(repository.hasMore, isTrue);

    await repository.loadMore();
    expect(repository.notifications.map((item) => item.id), ['1', '2']);
    expect(remote.requests, contains('GET /api/notifications?page=2&limit=20'));
  });

  test('read, read-all and delete mutate state only after success', () async {
    final remote = _Remote();
    final repository = NotificationInboxRepository(remote: remote);
    addTearDown(repository.dispose);
    await repository.refresh();

    await repository.markRead('1');
    expect(repository.notifications.single.isRead, isTrue);
    expect(repository.unreadCount, 1);

    await repository.markAllRead();
    expect(repository.unreadCount, 0);
    expect(repository.notifications.single.isRead, isTrue);

    await repository.delete('1');
    expect(repository.notifications, isEmpty);
  });

  test('failed mutation preserves the last canonical state', () async {
    final remote = _Remote();
    final repository = NotificationInboxRepository(remote: remote);
    addTearDown(repository.dispose);
    await repository.refresh();
    remote.failure = const AuthException('Session expired.');

    await expectLater(repository.markRead('1'), throwsA(isA<AuthException>()));
    expect(repository.notifications.single.isRead, isFalse);
    await expectLater(repository.delete('1'), throwsA(isA<AuthException>()));
    expect(repository.notifications.single.id, '1');
  });

  test('reload replaces stale memory with server state', () async {
    final remote = _Remote();
    final repository = NotificationInboxRepository(remote: remote);
    addTearDown(repository.dispose);
    await repository.refresh();
    await repository.markRead('1');
    expect(repository.notifications.single.isRead, isTrue);

    remote.page = 0;
    await repository.refresh();
    expect(repository.notifications.single.isRead, isFalse);
  });

  test(
    'authentication failure renders an error without seeded fallback',
    () async {
      final remote = _Remote()
        ..failure = const AuthException('Session expired.');
      final repository = NotificationInboxRepository(remote: remote);
      addTearDown(repository.dispose);

      await repository.refresh();

      expect(repository.notifications, isEmpty);
      expect(repository.error, 'Session expired.');
      expect(repository.unreadCount, 0);
    },
  );
}
