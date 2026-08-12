import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatRemote implements ChatRemoteDataSource {
  final Map<String, Object> responses = {};
  final List<String> calls = [];

  String _key(String method, String path) => '$method $path';

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    calls.add(_key(method, path));
    final value = responses[_key(method, path)];
    if (value is Exception) throw value;
    return (value as Map).cast<String, dynamic>();
  }

  @override
  Future<Map<String, dynamic>> upload(
    String path,
    AmoraPickedMedia media,
  ) async {
    calls.add('UPLOAD $path');
    final value = responses['UPLOAD $path'];
    if (value is Exception) throw value;
    return (value as Map).cast<String, dynamic>();
  }
}

Map<String, dynamic> _profile({String id = '2', bool online = false}) => {
  'id': id,
  'name': 'Backend Match',
  'gender': 'Woman',
  'age': 28,
  'city': 'Ahmedabad',
  'profession': 'Engineer',
  'education': 'Graduate',
  'imageUrl': '/uploads/profile.jpg',
  'gallery': ['/uploads/profile.jpg'],
  'verification': 'Verified',
  'online': online,
};

Map<String, dynamic> _summary({String id = '10', int unread = 0}) => {
  'id': id,
  'participant': _profile(),
  'lastMessage': {
    'id': '50',
    'type': 'text',
    'text': 'Stored in MySQL',
    'createdAt': '2026-08-11T10:00:00.000Z',
  },
  'unreadCount': unread,
  'updatedAt': '2026-08-11T10:00:00.000Z',
};

Map<String, dynamic> _message({
  String id = '50',
  String text = 'Stored in MySQL',
  bool mine = false,
  String? senderId,
  String createdAt = '2026-08-11T10:00:00.000Z',
}) => {
  'id': id,
  'conversationId': '10',
  'senderId': senderId ?? (mine ? '1' : '2'),
  'mine': mine,
  'type': 'text',
  'text': text,
  'deleted': false,
  'status': 'sent',
  'createdAt': createdAt,
  'media': <Object>[],
};

Map<String, dynamic> _listResponse(List<Map<String, dynamic>> values) => {
  'success': true,
  'data': {
    'conversations': values,
    'pagination': {'page': 1, 'limit': 20, 'hasMore': false},
  },
};

void main() {
  final repository = ChatRepository.instance;

  setUp(() {
    AuthService.instance.currentUser = const AmoraUser(
      id: 1,
      name: 'Current User',
      email: 'current@chat.test',
      phoneNumber: '',
      isVerified: true,
    );
  });

  tearDown(() {
    AuthService.instance.currentUser = null;
  });

  test(
    'conversation list loads real response and supports empty state',
    () async {
      final remote = _FakeChatRemote();
      remote.responses['GET /api/conversations?page=1&limit=20'] =
          _listResponse([_summary(unread: 2)]);
      await repository.resetForTesting(remote: remote);
      await repository.refreshConversations();
      expect(repository.conversations, hasLength(1));
      expect(repository.conversations.single.lastMessage, 'Stored in MySQL');
      expect(repository.conversations.single.unread, 2);

      remote.responses['GET /api/conversations?page=1&limit=20'] =
          _listResponse([]);
      await repository.refreshConversations();
      expect(repository.conversations, isEmpty);
    },
  );

  test('API errors are exposed without dummy fallback data', () async {
    final remote = _FakeChatRemote();
    remote.responses['GET /api/conversations?page=1&limit=20'] =
        const AuthException('offline');
    await repository.resetForTesting(remote: remote);
    await expectLater(
      repository.refreshConversations(),
      throwsA(isA<AuthException>()),
    );
    expect(repository.error, isA<AuthException>());
    expect(repository.conversations, isEmpty);
  });

  test('recipient ID creates and caches the canonical conversation', () async {
    final remote = _FakeChatRemote();
    remote.responses['POST /api/conversations'] = {
      'success': true,
      'data': {'conversation': _summary(id: '12')},
    };
    await repository.resetForTesting(remote: remote);

    final conversationId = await repository.createConversationForUserId('2');

    expect(conversationId, '12');
    expect(repository.conversation('12')?.user.id, '2');
    expect(remote.calls, contains('POST /api/conversations'));
  });

  test(
    'history, send, read, and incoming realtime state use persisted IDs',
    () async {
      final remote = _FakeChatRemote();
      remote.responses['GET /api/conversations?page=1&limit=20'] =
          _listResponse([_summary(unread: 1)]);
      remote.responses['GET /api/conversations/10/messages?limit=30'] = {
        'success': true,
        'data': {
          'conversation': {
            'id': '10',
            'participant': _profile(online: true),
            'canMessage': true,
            'draft': 'server draft',
          },
          'messages': [
            _message(
              id: '49',
              text: 'Outgoing stored message',
              mine: true,
              createdAt: '2026-08-11T09:59:00.000Z',
            ),
            _message(),
          ],
          'pagination': {'limit': 30, 'hasMore': false, 'nextCursor': null},
        },
      };
      remote.responses['PUT /api/conversations/10/read'] = {
        'success': true,
        'data': {'unreadCount': 0},
      };
      remote.responses['POST /api/conversations/10/messages'] = {
        'success': true,
        'data': {
          'message': _message(id: '51', text: 'Persisted send', mine: true),
        },
      };
      remote.responses['DELETE /api/conversations/10/draft'] = {
        'success': true,
        'data': {'draft': ''},
      };
      await repository.resetForTesting(remote: remote);
      await repository.refreshConversations();
      final loaded = await repository.loadConversation('10');
      expect(loaded!.messages.map((message) => message.id), ['49', '50']);
      expect(loaded.messages.first.senderId, '1');
      expect(loaded.messages.first.conversationId, '10');
      expect(loaded.messages.first.mine, isTrue);
      expect(loaded.messages.last.senderId, '2');
      expect(loaded.messages.last.mine, isFalse);
      expect(
        repository.conversation('10')!.messages.map((message) => message.id),
        ['49', '50'],
        reason: 'Fetched history must be stored in canonical repository state.',
      );
      expect(loaded.draft, 'server draft');
      await repository.markRead('10');
      expect(repository.conversation('10')!.unread, 0);
      final sent = await repository.sendMessage('10', 'Persisted send');
      expect(sent!.messages.last.id, '51');

      repository.receiveMessage(
        '10',
        ChatMessage(
          id: '52',
          text: 'Realtime receive',
          mine: false,
          conversationId: '10',
          senderId: '2',
          time: '10:01',
          createdAtEpochMs: DateTime.parse(
            '2026-08-11T10:01:00.000Z',
          ).millisecondsSinceEpoch,
        ),
      );
      repository.receiveMessage(
        '10',
        ChatMessage(
          id: '52',
          text: 'Realtime receive',
          mine: false,
          conversationId: '10',
          senderId: '2',
          time: '10:01',
          createdAtEpochMs: DateTime.parse(
            '2026-08-11T10:01:00.000Z',
          ).millisecondsSinceEpoch,
        ),
      );
      expect(
        repository
            .conversation('10')!
            .messages
            .where((item) => item.id == '52'),
        hasLength(1),
      );
      expect(repository.conversation('10')!.unread, 1);

      await repository.loadConversation('10');
      expect(
        repository.conversation('10')!.messages.map((message) => message.id),
        ['49', '50', '51', '52'],
        reason:
            'A history refresh must merge persisted rows without dropping newer realtime/API messages.',
      );
    },
  );

  test(
    'send access failure is surfaced and no fake message is inserted',
    () async {
      final remote = _FakeChatRemote();
      remote.responses['GET /api/conversations?page=1&limit=20'] =
          _listResponse([_summary()]);
      remote.responses['GET /api/conversations/10/messages?limit=30'] = {
        'success': true,
        'data': {
          'conversation': {
            'id': '10',
            'participant': _profile(),
            'canMessage': true,
            'draft': '',
          },
          'messages': <Object>[],
          'pagination': {'limit': 30, 'hasMore': false},
        },
      };
      remote.responses['POST /api/conversations/10/messages'] =
          const AuthException(
            'Conversation is not available.',
            code: 'CONVERSATION_NOT_AVAILABLE',
            statusCode: 404,
          );
      await repository.resetForTesting(remote: remote);
      await repository.refreshConversations();
      await repository.loadConversation('10');
      await expectLater(
        repository.sendMessage('10', 'blocked'),
        throwsA(isA<AuthException>()),
      );
      expect(repository.conversation('10')!.messages, isEmpty);
    },
  );
}
