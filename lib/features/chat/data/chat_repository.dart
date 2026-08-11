import 'dart:async';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum ChatMessageStatus { sending, queued, sent, delivered, read, failed }

enum ChatMessageContextType { profilePrompt, rose }

@immutable
class ChatMessageContext {
  const ChatMessageContext.profilePrompt({
    required this.promptId,
    required this.title,
    required this.detail,
  }) : type = ChatMessageContextType.profilePrompt;

  const ChatMessageContext.rose()
    : type = ChatMessageContextType.rose,
      promptId = null,
      title = 'Rose',
      detail = 'Sent from Profile Detail';

  final ChatMessageContextType type;
  final String? promptId;
  final String title;
  final String detail;

  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.name,
    if (promptId != null) 'promptId': promptId,
    'title': title,
    'detail': detail,
  };

  factory ChatMessageContext.fromJson(Map<String, dynamic> json) {
    if (json['type'] == ChatMessageContextType.profilePrompt.name) {
      return ChatMessageContext.profilePrompt(
        promptId: json['promptId']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        detail: json['detail']?.toString() ?? '',
      );
    }
    return const ChatMessageContext.rose();
  }
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.mine,
    required this.time,
    required this.createdAtEpochMs,
    this.status = ChatMessageStatus.sent,
    this.context,
    this.type = 'text',
    this.mediaUrl,
    this.deleted = false,
  });

  final String id;
  final String text;
  final bool mine;
  final String time;
  final int createdAtEpochMs;
  final ChatMessageStatus status;
  final ChatMessageContext? context;
  final String type;
  final String? mediaUrl;
  final bool deleted;

  bool get read => status == ChatMessageStatus.read;

  ChatMessage copyWith({ChatMessageStatus? status, bool? deleted}) =>
      ChatMessage(
        id: id,
        text: text,
        mine: mine,
        time: time,
        createdAtEpochMs: createdAtEpochMs,
        status: status ?? this.status,
        context: context,
        type: type,
        mediaUrl: mediaUrl,
        deleted: deleted ?? this.deleted,
      );
}

@immutable
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.user,
    required this.messages,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
    this.muted = false,
    this.canMessage = true,
    this.unavailableReason,
    this.draft = '',
    this.hasMoreMessages = false,
    this.nextMessageCursor,
  });

  final String id;
  final DummyProfile user;
  final List<ChatMessage> messages;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;
  final bool muted;
  final bool canMessage;
  final String? unavailableReason;
  final String draft;
  final bool hasMoreMessages;
  final String? nextMessageCursor;

  ChatConversation copyWith({
    List<ChatMessage>? messages,
    String? lastMessage,
    String? time,
    int? unread,
    bool? online,
    bool? muted,
    bool? canMessage,
    String? unavailableReason,
    String? draft,
    bool? hasMoreMessages,
    String? nextMessageCursor,
  }) => ChatConversation(
    id: id,
    user: user,
    messages: List<ChatMessage>.unmodifiable(messages ?? this.messages),
    lastMessage: lastMessage ?? this.lastMessage,
    time: time ?? this.time,
    unread: unread ?? this.unread,
    online: online ?? this.online,
    muted: muted ?? this.muted,
    canMessage: canMessage ?? this.canMessage,
    unavailableReason: unavailableReason ?? this.unavailableReason,
    draft: draft ?? this.draft,
    hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
    nextMessageCursor: nextMessageCursor ?? this.nextMessageCursor,
  );
}

abstract class ChatRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
  Future<Map<String, dynamic>> upload(String path, AmoraPickedMedia media);
}

class _AuthenticatedChatDataSource implements ChatRemoteDataSource {
  const _AuthenticatedChatDataSource();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => AuthService.instance.authenticatedRequest(method, path, body: body);

  @override
  Future<Map<String, dynamic>> upload(String path, AmoraPickedMedia media) =>
      AuthService.instance.authenticatedMultipart(
        path,
        field: 'media',
        bytes: media.bytes,
        filename: media.name,
        mimeType: media.mimeType,
      );
}

class ChatRepository extends ChangeNotifier {
  ChatRepository._() : _remote = const _AuthenticatedChatDataSource();

  static final instance = ChatRepository._();

  ChatRemoteDataSource _remote;
  final StreamController<ChatConversation> _conversationEvents =
      StreamController<ChatConversation>.broadcast(sync: true);
  List<ChatConversation> _conversations = const [];
  io.Socket? _socket;
  bool _loading = false;
  bool _loadingMore = false;
  bool _realtimeConnected = false;
  bool _connectingRealtime = false;
  Object? _error;
  int _nextPage = 1;
  bool _hasMore = false;
  int _activeConversationSubscriptions = 0;
  bool _testingMode = false;
  bool _failNextForTesting = false;
  final Map<String, Future<Uint8List>> _mediaCache = {};

  List<ChatConversation> get conversations =>
      List<ChatConversation>.unmodifiable(_conversations);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  bool get realtimeConnected => _realtimeConnected;
  Object? get error => _error;

  Future<void> initialize() async {
    _testingMode = false;
    _conversations = const [];
    if (AuthService.instance.currentUser == null) {
      notifyListeners();
      return;
    }
    try {
      await refreshConversations();
    } catch (_) {
      // The Chats screen renders the repository error and offers retry.
    }
  }

  Future<void> refreshConversations() async {
    if (_testingMode) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _remote.request(
        'GET',
        '/api/conversations?page=1&limit=20',
      );
      final data = _data(response);
      _conversations = _conversationList(data['conversations']);
      final pagination = (data['pagination'] as Map?)?.cast<String, dynamic>();
      _hasMore = pagination?['hasMore'] == true;
      _nextPage = (pagination?['nextPage'] as num?)?.toInt() ?? 2;
      if (_socket == null) unawaited(_connectRealtime());
    } catch (error) {
      _error = error;
      _conversations = const [];
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreConversations() async {
    if (_testingMode || !_hasMore || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final response = await _remote.request(
        'GET',
        '/api/conversations?page=$_nextPage&limit=20',
      );
      final data = _data(response);
      final additions = _conversationList(data['conversations']);
      final ids = _conversations.map((item) => item.id).toSet();
      _conversations = [
        ..._conversations,
        ...additions.where((item) => ids.add(item.id)),
      ];
      final pagination = (data['pagination'] as Map?)?.cast<String, dynamic>();
      _hasMore = pagination?['hasMore'] == true;
      _nextPage = (pagination?['nextPage'] as num?)?.toInt() ?? _nextPage + 1;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  ChatConversation? conversation(String conversationId) =>
      _conversations.where((item) => item.id == conversationId).firstOrNull;

  String? conversationIdForProfile(String profileId) =>
      _conversations.where((item) => item.user.id == profileId).firstOrNull?.id;

  Future<String> createConversationForProfile(DummyProfile profile) async {
    final existing = conversationIdForProfile(profile.id);
    if (existing != null) return existing;
    if (_testingMode) {
      final value = _testingConversation(
        profile,
        int.tryParse(profile.id) == null ? 'test-${profile.id}' : profile.id,
      );
      _conversations = [value, ..._conversations];
      _emit(value);
      return value.id;
    }
    return createConversationForUserId(profile.id);
  }

  Future<String> createConversationForUserId(String profileId) async {
    final targetUserId = int.tryParse(profileId);
    if (targetUserId == null || targetUserId < 1) {
      throw const AuthException('The selected profile is unavailable.');
    }
    final existing = conversationIdForProfile(profileId);
    if (existing != null) return existing;
    final response = await _remote.request(
      'POST',
      '/api/conversations',
      body: {'targetUserId': targetUserId},
    );
    final json = (_data(response)['conversation'] as Map)
        .cast<String, dynamic>();
    final value = _conversationFromJson(json);
    _upsertConversation(value, moveToFront: true);
    return value.id;
  }

  Stream<ChatConversation> watchConversation(String conversationId) {
    late StreamController<ChatConversation> controller;
    StreamSubscription<ChatConversation>? subscription;
    controller = StreamController<ChatConversation>(
      onListen: () {
        _activeConversationSubscriptions++;
        final current = conversation(conversationId);
        if (current != null) controller.add(current);
        subscription = _conversationEvents.stream
            .where((item) => item.id == conversationId)
            .listen(controller.add, onError: controller.addError);
      },
      onCancel: () {
        _activeConversationSubscriptions--;
        return subscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<ChatConversation?> loadConversation(
    String conversationId, {
    bool older = false,
  }) async {
    if (_testingMode) return conversation(conversationId);
    final current = conversation(conversationId);
    final cursor = older ? current?.nextMessageCursor : null;
    final response = await _remote.request(
      'GET',
      '/api/conversations/$conversationId/messages?limit=30${cursor == null ? '' : '&beforeId=$cursor'}',
    );
    final data = _data(response);
    final conversationJson = (data['conversation'] as Map)
        .cast<String, dynamic>();
    final participant = publicProfileFromJson(
      (conversationJson['participant'] as Map).cast<String, dynamic>(),
    ).profile;
    final messages = _messageList(data['messages']);
    final pagination = (data['pagination'] as Map).cast<String, dynamic>();
    final next = ChatConversation(
      id: conversationId,
      user: participant,
      messages: older
          ? _mergeMessages(messages, current?.messages ?? const [])
          : messages,
      lastMessage: messages.isEmpty
          ? current?.lastMessage ?? ''
          : _preview(messages.last),
      time: messages.isEmpty ? current?.time ?? '' : messages.last.time,
      unread: current?.unread ?? 0,
      online:
          conversationJson['participant'] is Map &&
          (conversationJson['participant'] as Map)['online'] == true,
      muted: conversationJson['muted'] == true,
      canMessage: conversationJson['canMessage'] != false,
      draft: conversationJson['draft']?.toString() ?? '',
      hasMoreMessages: pagination['hasMore'] == true,
      nextMessageCursor: pagination['nextCursor']?.toString(),
    );
    _upsertConversation(next);
    _socket?.emit('conversation.subscribe', {'conversationId': conversationId});
    return next;
  }

  Future<void> markRead(String conversationId) async {
    final current = conversation(conversationId);
    if (current == null) return;
    final latest = current.messages.isEmpty ? null : current.messages.last.id;
    if (!_testingMode) {
      await _remote.request(
        'PUT',
        '/api/conversations/$conversationId/read',
        body: {if (latest != null) 'messageId': int.parse(latest)},
      );
    }
    _replace(current.copyWith(unread: 0));
  }

  String draftForConversation(String conversationId) =>
      conversation(conversationId)?.draft ?? '';

  Future<void> saveDraft(String conversationId, String value) async {
    final current = conversation(conversationId);
    if (current == null) return;
    final draft = value.length > 4000 ? value.substring(0, 4000) : value;
    if (!_testingMode) {
      if (draft.trim().isEmpty) {
        await clearDraft(conversationId);
        return;
      }
      await _remote.request(
        'PUT',
        '/api/conversations/$conversationId/draft',
        body: {'text': draft},
      );
    }
    _replace(current.copyWith(draft: draft));
  }

  Future<void> clearDraft(String conversationId) async {
    final current = conversation(conversationId);
    if (current == null) return;
    if (!_testingMode) {
      await _remote.request(
        'DELETE',
        '/api/conversations/$conversationId/draft',
      );
    }
    _replace(current.copyWith(draft: ''));
  }

  Future<void> setMuted(String conversationId, bool muted) async {
    final current = conversation(conversationId);
    if (current == null) return;
    if (!_testingMode) {
      await _remote.request(
        muted ? 'PUT' : 'DELETE',
        '/api/conversations/$conversationId/mute',
      );
    }
    _replace(current.copyWith(muted: muted));
  }

  Future<ChatConversation?> sendMessage(
    String conversationId,
    String text, {
    ChatMessageContext? context,
  }) async {
    final value = text.trim();
    final current = conversation(conversationId);
    if (current == null || !current.canMessage || value.isEmpty) return current;
    if (_failNextForTesting) {
      _failNextForTesting = false;
      throw StateError('Simulated API failure');
    }
    if (_testingMode) {
      final now = DateTime.now();
      _append(
        current,
        ChatMessage(
          id: 'test-${now.microsecondsSinceEpoch}',
          text: value,
          mine: true,
          time: _displayTime(now),
          createdAtEpochMs: now.millisecondsSinceEpoch,
          status: ChatMessageStatus.sent,
          context: context,
        ),
        unread: 0,
      );
      await clearDraft(conversationId);
      return conversation(conversationId);
    }
    final response = await _remote.request(
      'POST',
      '/api/conversations/$conversationId/messages',
      body: {'text': value, if (context != null) 'context': context.toJson()},
    );
    final message = _messageFromJson(
      (_data(response)['message'] as Map).cast<String, dynamic>(),
    );
    _append(current, message, unread: 0);
    await clearDraft(conversationId);
    return conversation(conversationId);
  }

  Future<ChatConversation?> retryMessage(
    String conversationId,
    String messageId,
  ) async {
    final message = conversation(
      conversationId,
    )?.messages.where((item) => item.id == messageId).firstOrNull;
    if (message == null) return conversation(conversationId);
    return sendMessage(conversationId, message.text, context: message.context);
  }

  Future<void> sendMedia(String conversationId, AmoraPickedMedia media) async {
    final response = await _remote.upload(
      '/api/conversations/$conversationId/media',
      media,
    );
    final message = _messageFromJson(
      (_data(response)['message'] as Map).cast<String, dynamic>(),
    );
    final current = conversation(conversationId);
    if (current != null) _append(current, message, unread: 0);
  }

  Future<Uint8List> mediaBytes(String path) => _mediaCache.putIfAbsent(
    path,
    () => AuthService.instance.authenticatedBytes(path),
  );

  Future<void> deleteMessage(String messageId) async {
    if (!_testingMode) {
      await _remote.request('DELETE', '/api/messages/$messageId');
    }
    _markMessageDeletedLocally(messageId);
  }

  void receiveMessage(String conversationId, ChatMessage message) {
    final current = conversation(conversationId);
    if (current == null ||
        current.messages.any((item) => item.id == message.id)) {
      return;
    }
    _append(
      current,
      message,
      unread: message.mine ? current.unread : current.unread + 1,
    );
  }

  Future<void> setMessagingAvailability(
    String conversationId, {
    required bool canMessage,
    String? reason,
  }) async {
    final current = conversation(conversationId);
    if (current != null) {
      _replace(
        current.copyWith(canMessage: canMessage, unavailableReason: reason),
      );
    }
  }

  Future<void> clearForAccountDeletion() async {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _conversations = const [];
    _mediaCache.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> _connectRealtime({bool force = false}) async {
    if (_testingMode ||
        AuthService.instance.currentUser == null ||
        _connectingRealtime) {
      return;
    }
    if (_socket != null && !force) return;
    _connectingRealtime = true;
    try {
      final response = await _remote.request('POST', '/api/realtime/token');
      final token = _data(response)['token']?.toString();
      if (token == null || token.isEmpty) return;
      _socket?.dispose();
      final socket = io.io(
        AmoraApiConfig.baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .enableReconnection()
            .build(),
      );
      _socket = socket;
      socket.onConnect((_) {
        _realtimeConnected = true;
        notifyListeners();
      });
      socket.onDisconnect((_) {
        _realtimeConnected = false;
        notifyListeners();
      });
      socket.onConnectError((_) {
        _realtimeConnected = false;
        notifyListeners();
        Future<void>.delayed(
          const Duration(seconds: 2),
          () => _connectRealtime(force: true),
        );
      });
      socket.on('message.created', _handleMessageCreated);
      socket.on('message.deleted', _handleMessageDeleted);
      socket.on('message.read', _handleRead);
      socket.on('message.delivered', _handleDelivered);
      socket.on('conversation.updated', (_) => unawaited(_refreshQuietly()));
      socket.on('presence.updated', _handlePresence);
      socket.connect();
    } catch (_) {
      _realtimeConnected = false;
      notifyListeners();
    } finally {
      _connectingRealtime = false;
    }
  }

  void _handleMessageCreated(dynamic value) {
    if (value is! Map || value['message'] is! Map) return;
    final message = _messageFromJson(
      (value['message'] as Map).cast<String, dynamic>(),
    );
    receiveMessage(value['conversationId'].toString(), message);
  }

  void _handleMessageDeleted(dynamic value) {
    if (value is! Map) return;
    final id = value['messageId']?.toString();
    if (id != null) _markMessageDeletedLocally(id);
  }

  void _markMessageDeletedLocally(String messageId) {
    for (final conversation in _conversations) {
      final index = conversation.messages.indexWhere(
        (item) => item.id == messageId,
      );
      if (index < 0) continue;
      final messages = List<ChatMessage>.of(conversation.messages);
      messages[index] = messages[index].copyWith(deleted: true);
      _replace(
        conversation.copyWith(
          messages: messages,
          lastMessage: 'Message deleted',
        ),
      );
      return;
    }
  }

  void _handleRead(dynamic value) {
    if (value is! Map) return;
    final conversationId = value['conversationId']?.toString();
    final readerId = value['userId']?.toString();
    final currentUserId = AuthService.instance.currentUser?.id.toString();
    final readId =
        int.tryParse(value['lastReadMessageId']?.toString() ?? '') ?? 0;
    final current = conversationId == null
        ? null
        : conversation(conversationId);
    if (current == null) return;
    final messages = current.messages.map((message) {
      if (readerId != currentUserId &&
          message.mine &&
          int.tryParse(message.id) != null &&
          int.parse(message.id) <= readId) {
        return message.copyWith(status: ChatMessageStatus.read);
      }
      return message;
    }).toList();
    _replace(current.copyWith(messages: messages));
  }

  void _handleDelivered(dynamic value) {
    if (value is! Map) return;
    final conversationId = value['conversationId']?.toString();
    final recipientId = value['userId']?.toString();
    final currentUserId = AuthService.instance.currentUser?.id.toString();
    final deliveredId =
        int.tryParse(value['lastDeliveredMessageId']?.toString() ?? '') ?? 0;
    final current = conversationId == null
        ? null
        : conversation(conversationId);
    if (current == null || recipientId == currentUserId) return;
    final messages = current.messages.map((message) {
      final messageId = int.tryParse(message.id);
      if (message.mine &&
          message.status == ChatMessageStatus.sent &&
          messageId != null &&
          messageId <= deliveredId) {
        return message.copyWith(status: ChatMessageStatus.delivered);
      }
      return message;
    }).toList();
    _replace(current.copyWith(messages: messages));
  }

  void _handlePresence(dynamic value) {
    if (value is! Map) return;
    final userId = value['userId']?.toString();
    final index = _conversations.indexWhere((item) => item.user.id == userId);
    if (index >= 0) {
      _replace(_conversations[index].copyWith(online: value['online'] == true));
    }
  }

  Future<void> _refreshQuietly() async {
    if (_testingMode) return;
    try {
      final response = await _remote.request(
        'GET',
        '/api/conversations?page=1&limit=20',
      );
      final fresh = _conversationList(_data(response)['conversations']);
      final messagesById = {
        for (final item in _conversations) item.id: item.messages,
      };
      _conversations = fresh
          .map(
            (item) =>
                item.copyWith(messages: messagesById[item.id] ?? const []),
          )
          .toList();
      notifyListeners();
    } catch (_) {
      // A realtime refresh failure never replaces known server data with mocks.
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};

  List<ChatConversation> _conversationList(dynamic values) =>
      (values as List? ?? const [])
          .map(
            (value) =>
                _conversationFromJson((value as Map).cast<String, dynamic>()),
          )
          .toList();

  ChatConversation _conversationFromJson(Map<String, dynamic> json) {
    final participantJson = (json['participant'] as Map)
        .cast<String, dynamic>();
    final profile = publicProfileFromJson(participantJson).profile;
    final last = (json['lastMessage'] as Map?)?.cast<String, dynamic>();
    final lastAt = DateTime.tryParse(
      last?['createdAt']?.toString() ?? json['updatedAt']?.toString() ?? '',
    );
    return ChatConversation(
      id: json['id'].toString(),
      user: profile,
      messages: const [],
      lastMessage: last == null
          ? ''
          : last['deleted'] == true
          ? 'Message deleted'
          : last['type'] == 'image' &&
                (last['text']?.toString().isEmpty ?? true)
          ? 'Photo'
          : last['text']?.toString() ?? '',
      time: _displayConversationTime(lastAt),
      unread: (json['unreadCount'] as num?)?.toInt() ?? 0,
      online: participantJson['online'] == true,
      muted: json['muted'] == true,
    );
  }

  List<ChatMessage> _messageList(dynamic values) =>
      (values as List? ?? const [])
          .map(
            (value) => _messageFromJson((value as Map).cast<String, dynamic>()),
          )
          .toList();

  ChatMessage _messageFromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final context = json['context'] is Map
        ? ChatMessageContext.fromJson(
            (json['context'] as Map).cast<String, dynamic>(),
          )
        : null;
    final media = json['media'] as List? ?? const [];
    final currentUserId = AuthService.instance.currentUser?.id.toString();
    return ChatMessage(
      id: json['id'].toString(),
      text: json['deleted'] == true
          ? 'Message deleted'
          : json['text']?.toString() ?? '',
      mine: currentUserId == null
          ? json['mine'] == true
          : json['senderId']?.toString() == currentUserId,
      time: _displayTime(created.toLocal()),
      createdAtEpochMs: created.millisecondsSinceEpoch,
      status: switch (json['status']) {
        'read' => ChatMessageStatus.read,
        'delivered' => ChatMessageStatus.delivered,
        _ => ChatMessageStatus.sent,
      },
      context: context,
      type: json['type']?.toString() ?? 'text',
      mediaUrl: media.isEmpty ? null : (media.first as Map)['url']?.toString(),
      deleted: json['deleted'] == true,
    );
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> first,
    List<ChatMessage> second,
  ) {
    final values = {
      for (final item in [...first, ...second]) item.id: item,
    }.values.toList();
    values.sort((a, b) => a.createdAtEpochMs.compareTo(b.createdAtEpochMs));
    return values;
  }

  void _append(
    ChatConversation current,
    ChatMessage message, {
    required int unread,
  }) {
    final messages = _mergeMessages(current.messages, [message]);
    _replace(
      current.copyWith(
        messages: messages,
        lastMessage: _preview(message),
        time: message.time,
        unread: unread,
      ),
    );
  }

  String _preview(ChatMessage message) => message.deleted
      ? 'Message deleted'
      : message.type == 'image' && message.text.isEmpty
      ? 'Photo'
      : message.text;

  void _replace(ChatConversation value) {
    final index = _conversations.indexWhere((item) => item.id == value.id);
    if (index < 0) return;
    final next = List<ChatConversation>.of(_conversations);
    next[index] = value;
    _conversations = next;
    _emit(value);
  }

  void _upsertConversation(ChatConversation value, {bool moveToFront = false}) {
    final current = conversation(value.id);
    final merged = current == null
        ? value
        : value.copyWith(messages: current.messages);
    _conversations = [
      if (moveToFront) merged,
      for (final item in _conversations)
        if (item.id != value.id) item,
      if (!moveToFront) merged,
    ];
    _emit(merged);
  }

  void _emit(ChatConversation value) {
    notifyListeners();
    _conversationEvents.add(value);
  }

  String _displayTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String _displayConversationTime(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return _displayTime(local);
    }
    return '${local.day}/${local.month}';
  }

  ChatConversation _testingConversation(
    DummyProfile profile,
    String id, {
    int unread = 0,
    bool seeded = false,
    bool online = false,
  }) {
    final seededMessage = ChatMessage(
      id: '$id-fixture-message',
      text: 'Test fixture message',
      mine: false,
      time: '09:30',
      createdAtEpochMs: DateTime(2026, 1, 1, 9, 30).millisecondsSinceEpoch,
    );
    return ChatConversation(
      id: id,
      user: profile,
      messages: seeded ? [seededMessage] : const [],
      lastMessage: seeded ? seededMessage.text : '',
      time: seeded ? seededMessage.time : '',
      unread: unread,
      online: online,
    );
  }

  @visibleForTesting
  Future<void> resetForTesting({ChatRemoteDataSource? remote}) async {
    _testingMode = remote == null;
    if (remote != null) _remote = remote;
    _socket?.dispose();
    _socket = null;
    _error = null;
    _loading = false;
    _failNextForTesting = false;
    final profiles = ImageRepository.profiles.take(4).toList();
    _conversations = _testingMode
        ? [
            for (var index = 0; index < profiles.length; index++)
              _testingConversation(
                profiles[index],
                'test-${profiles[index].id}',
                unread: index == 0 ? 2 : 0,
                seeded: true,
                online: index == 0,
              ),
          ]
        : const [];
    notifyListeners();
  }

  @visibleForTesting
  bool get hasActiveConversationSubscriptions =>
      _activeConversationSubscriptions > 0;

  @visibleForTesting
  void failNextPersistenceForTesting() => _failNextForTesting = true;
}
