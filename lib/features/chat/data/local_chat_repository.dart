import 'dart:async';
import 'dart:convert';

import 'package:amora_ai/core/data/amora_dummy_data.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    'promptId': promptId,
    'title': title,
    'detail': detail,
  };

  factory ChatMessageContext.fromJson(Map<String, Object?> json) {
    final type = ChatMessageContextType.values
        .where((value) => value.name == json['type'])
        .firstOrNull;
    if (type == ChatMessageContextType.profilePrompt) {
      return ChatMessageContext.profilePrompt(
        promptId: json['promptId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
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
  });

  final String id;
  final String text;
  final bool mine;
  final String time;
  final int createdAtEpochMs;
  final ChatMessageStatus status;
  final ChatMessageContext? context;

  bool get read => status == ChatMessageStatus.read;

  ChatMessage copyWith({ChatMessageStatus? status}) {
    return ChatMessage(
      id: id,
      text: text,
      mine: mine,
      time: time,
      createdAtEpochMs: createdAtEpochMs,
      status: status ?? this.status,
      context: context,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'text': text,
    'mine': mine,
    'time': time,
    'createdAtEpochMs': createdAtEpochMs,
    'status': status.name,
    'context': context?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    final text = json['text'] as String? ?? '';
    final time = json['time'] as String? ?? '';
    final mine = json['mine'] as bool? ?? false;
    final statusName = json['status'] as String?;
    final legacyRead = json['read'] as bool? ?? false;
    final status = ChatMessageStatus.values
        .where((value) => value.name == statusName)
        .firstOrNull;
    final createdAt =
        (json['createdAtEpochMs'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final rawContext = json['context'];
    final context = rawContext is Map
        ? ChatMessageContext.fromJson(
            rawContext.map((key, value) => MapEntry(key.toString(), value)),
          )
        : null;
    return ChatMessage(
      id:
          json['id'] as String? ??
          'legacy-${mine ? 'mine' : 'theirs'}-$createdAt-$time',
      text: text,
      mine: mine,
      time: time,
      createdAtEpochMs: createdAt,
      status:
          status ??
          (legacyRead ? ChatMessageStatus.read : ChatMessageStatus.sent),
      context: context,
    );
  }
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
    this.canMessage = true,
    this.unavailableReason,
  });

  final String id;
  final DummyProfile user;
  final List<ChatMessage> messages;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;
  final bool canMessage;
  final String? unavailableReason;

  ChatConversation copyWith({
    List<ChatMessage>? messages,
    String? lastMessage,
    String? time,
    int? unread,
    bool? online,
    bool? canMessage,
    String? unavailableReason,
  }) {
    return ChatConversation(
      id: id,
      user: user,
      messages: List<ChatMessage>.unmodifiable(messages ?? this.messages),
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      unread: unread ?? this.unread,
      online: online ?? this.online,
      canMessage: canMessage ?? this.canMessage,
      unavailableReason: unavailableReason ?? this.unavailableReason,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'profileId': user.id,
    'messages': messages.map((message) => message.toJson()).toList(),
    'lastMessage': lastMessage,
    'time': time,
    'unread': unread,
    'online': online,
    'canMessage': canMessage,
    'unavailableReason': unavailableReason,
  };
}

/// Existing device-local chat source.
///
/// The broadcast stream gives every open conversation an isolated live update
/// channel. Server delivery cannot be claimed until a backend transport is
/// connected, so new messages become `queued` after device persistence.
class LocalChatRepository extends ChangeNotifier {
  LocalChatRepository._();

  static final instance = LocalChatRepository._();
  static const _storageKey = 'amora.chat_conversations.v1';
  static const _draftStorageKey = 'amora.chat_drafts.v1';

  final StreamController<ChatConversation> _conversationEvents =
      StreamController<ChatConversation>.broadcast(sync: true);
  List<ChatConversation> _conversations = const <ChatConversation>[];
  Map<String, String> _drafts = <String, String>{};
  bool _accountCleared = false;
  bool _failNextPersistenceForTesting = false;
  int _activeConversationSubscriptions = 0;
  int _messageSequence = 0;

  List<ChatConversation> get conversations {
    if (_conversations.isEmpty && !_accountCleared) {
      _conversations = _seedConversations();
    }
    return List<ChatConversation>.unmodifiable(_conversations);
  }

  Future<void> initialize() async {
    _accountCleared = false;
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      final storedDrafts = preferences.getString(_draftStorageKey);
      if (storedDrafts != null && storedDrafts.isNotEmpty) {
        final decodedDrafts = jsonDecode(storedDrafts);
        if (decodedDrafts is Map) {
          _drafts = decodedDrafts.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        }
      }
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          final restored = decoded
              .whereType<Map>()
              .map(
                (item) => _conversationFromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .whereType<ChatConversation>()
              .toList(growable: false);
          if (restored.isNotEmpty) {
            _conversations = restored;
            notifyListeners();
            return;
          }
        }
      }
    } catch (_) {
      // Fall through to the bundled conversation seed if device storage is
      // unavailable or contains an invalid payload.
    }
    _conversations = _seedConversations();
    notifyListeners();
    unawaited(_persistSafely());
  }

  ChatConversation? conversation(String conversationId) {
    for (final conversation in _conversations) {
      if (conversation.id == conversationId) return conversation;
    }
    return null;
  }

  Stream<ChatConversation> watchConversation(String conversationId) {
    late final StreamController<ChatConversation> controller;
    StreamSubscription<ChatConversation>? sourceSubscription;
    controller = StreamController<ChatConversation>(
      onListen: () {
        _activeConversationSubscriptions++;
        final current = conversation(conversationId);
        if (current != null) controller.add(current);
        sourceSubscription = _conversationEvents.stream
            .where((conversation) => conversation.id == conversationId)
            .listen(
              controller.add,
              onError: controller.addError,
              onDone: controller.close,
            );
      },
      onCancel: () {
        if (_activeConversationSubscriptions > 0) {
          _activeConversationSubscriptions--;
        }
        return sourceSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  String? conversationIdForProfile(String profileId) {
    for (final conversation in _conversations) {
      if (conversation.user.id == profileId) return conversation.id;
    }
    return null;
  }

  String ensureConversationForProfile(DummyProfile profile) {
    final existing = conversationIdForProfile(profile.id);
    if (existing != null) return existing;
    final conversation = ChatConversation(
      id: 'chat-${profile.id}',
      user: profile,
      messages: const <ChatMessage>[],
      lastMessage: '',
      time: '',
      unread: 0,
      online: profile.status == 'Online now',
    );
    _conversations = <ChatConversation>[conversation, ..._conversations];
    _emit(conversation);
    unawaited(_persistSafely());
    return conversation.id;
  }

  Future<ChatConversation?> loadConversation(String conversationId) async {
    await Future<void>.delayed(Duration.zero);
    return conversation(conversationId);
  }

  Future<void> markRead(String conversationId) async {
    final index = _indexOf(conversationId);
    if (index < 0 || _conversations[index].unread == 0) return;
    _replaceAt(index, _conversations[index].copyWith(unread: 0));
    await _persistSafely();
  }

  String draftForConversation(String conversationId) =>
      _drafts[conversationId] ?? '';

  Future<void> saveDraft(String conversationId, String value) async {
    final draft = value.length > 2000 ? value.substring(0, 2000) : value;
    if (draft.trim().isEmpty) {
      _drafts.remove(conversationId);
    } else {
      _drafts[conversationId] = draft;
    }
    await _persistDrafts();
  }

  Future<void> clearDraft(String conversationId) async {
    if (_drafts.remove(conversationId) != null) await _persistDrafts();
  }

  Future<ChatConversation?> sendMessage(
    String conversationId,
    String text, {
    ChatMessageContext? context,
  }) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 2000) {
      return conversation(conversationId);
    }
    final index = _indexOf(conversationId);
    if (index < 0 || !_conversations[index].canMessage) return null;

    final now = DateTime.now();
    final messageId =
        'local-${now.microsecondsSinceEpoch}-${_messageSequence++}';
    final pending = ChatMessage(
      id: messageId,
      text: value,
      mine: true,
      time: _displayTime(now),
      createdAtEpochMs: now.millisecondsSinceEpoch,
      status: ChatMessageStatus.sending,
      context: context,
    );
    _appendMessage(index, pending, unread: 0);

    try {
      await _persist();
      final sent = _updateMessageStatus(
        conversationId,
        messageId,
        ChatMessageStatus.queued,
      );
      await _persist();
      await clearDraft(conversationId);
      return sent;
    } catch (error) {
      _updateMessageStatus(conversationId, messageId, ChatMessageStatus.failed);
      rethrow;
    }
  }

  Future<ChatConversation?> retryMessage(
    String conversationId,
    String messageId,
  ) async {
    final current = conversation(conversationId);
    final message = current?.messages
        .where((message) => message.id == messageId)
        .firstOrNull;
    if (message == null || message.status != ChatMessageStatus.failed) {
      return current;
    }
    _updateMessageStatus(conversationId, messageId, ChatMessageStatus.sending);
    try {
      await _persist();
      final sent = _updateMessageStatus(
        conversationId,
        messageId,
        ChatMessageStatus.queued,
      );
      await _persist();
      return sent;
    } catch (_) {
      _updateMessageStatus(conversationId, messageId, ChatMessageStatus.failed);
      rethrow;
    }
  }

  /// Entry point for an eventual server transport and deterministic tests.
  void receiveMessage(String conversationId, ChatMessage message) {
    final index = _indexOf(conversationId);
    if (index < 0) return;
    final current = _conversations[index];
    if (current.messages.any((existing) => existing.id == message.id)) return;
    _appendMessage(index, message, unread: current.unread + 1);
  }

  Future<void> setMessagingAvailability(
    String conversationId, {
    required bool canMessage,
    String? reason,
  }) async {
    final index = _indexOf(conversationId);
    if (index < 0) return;
    _replaceAt(
      index,
      _conversations[index].copyWith(
        canMessage: canMessage,
        unavailableReason: reason,
      ),
    );
    await _persistSafely();
  }

  Future<void> clearForAccountDeletion() async {
    _accountCleared = true;
    _conversations = const <ChatConversation>[];
    _drafts = <String, String>{};
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    await preferences.remove(_draftStorageKey);
  }

  int _indexOf(String conversationId) =>
      _conversations.indexWhere((item) => item.id == conversationId);

  void _appendMessage(int index, ChatMessage message, {required int unread}) {
    final current = _conversations[index];
    final messages = <ChatMessage>[...current.messages, message]
      ..sort((a, b) => a.createdAtEpochMs.compareTo(b.createdAtEpochMs));
    final updated = current.copyWith(
      messages: messages,
      lastMessage: message.text,
      time: message.mine ? 'Now' : message.time,
      unread: unread,
    );
    _replaceAt(index, updated);
  }

  ChatConversation? _updateMessageStatus(
    String conversationId,
    String messageId,
    ChatMessageStatus status,
  ) {
    final index = _indexOf(conversationId);
    if (index < 0) return null;
    final current = _conversations[index];
    final messageIndex = current.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (messageIndex < 0) return current;
    final messages = List<ChatMessage>.of(current.messages);
    messages[messageIndex] = messages[messageIndex].copyWith(status: status);
    final updated = current.copyWith(messages: messages);
    _replaceAt(index, updated);
    return updated;
  }

  void _replaceAt(int index, ChatConversation conversation) {
    final next = List<ChatConversation>.of(_conversations);
    next[index] = conversation;
    _conversations = next;
    _emit(conversation);
  }

  void _emit(ChatConversation conversation) {
    notifyListeners();
    _conversationEvents.add(conversation);
  }

  ChatConversation? _conversationFromJson(Map<String, Object?> json) {
    final profileId = json['profileId'] as String?;
    if (profileId == null) return null;
    final profile = _profileById(profileId);
    if (profile == null) return null;
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
              .whereType<Map>()
              .map(
                (item) => ChatMessage.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .where((message) => message.text.trim().isNotEmpty)
              .toList(growable: false)
        : const <ChatMessage>[];
    return ChatConversation(
      id: json['id'] as String? ?? 'chat-$profileId',
      user: profile,
      messages: messages,
      lastMessage:
          json['lastMessage'] as String? ??
          (messages.isEmpty ? '' : messages.last.text),
      time: json['time'] as String? ?? '',
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      online: json['online'] as bool? ?? false,
      canMessage: json['canMessage'] as bool? ?? true,
      unavailableReason: json['unavailableReason'] as String?,
    );
  }

  List<ChatConversation> _seedConversations() {
    return <ChatConversation>[
      for (var index = 0; index < AmoraDummyData.chats.length; index++)
        _seedConversation(AmoraDummyData.chats[index], index),
    ];
  }

  ChatConversation _seedConversation(DummyConversation source, int index) {
    final firstName = source.user.name.split(' ').first;
    final baseTime = 1700000000000 + (index * 100000);
    final messages = <ChatMessage>[
      ChatMessage(
        id: '${source.id}-seed-1',
        text: 'Hi, I’m $firstName. Your profile made me smile.',
        mine: false,
        time: '09:${(12 + index).toString().padLeft(2, '0')}',
        createdAtEpochMs: baseTime,
      ),
      ChatMessage(
        id: '${source.id}-seed-2',
        text: 'Thank you — I enjoyed reading yours too.',
        mine: true,
        time: '09:${(14 + index).toString().padLeft(2, '0')}',
        createdAtEpochMs: baseTime + 1000,
        status: ChatMessageStatus.read,
      ),
      ChatMessage(
        id: '${source.id}-seed-3',
        text: source.lastMessage,
        mine: false,
        time: source.time,
        createdAtEpochMs: baseTime + 2000,
      ),
    ];
    return ChatConversation(
      id: source.id,
      user: source.user,
      messages: messages,
      lastMessage: source.lastMessage,
      time: source.time,
      unread: source.unread,
      online: source.online,
    );
  }

  DummyProfile? _profileById(String profileId) {
    for (final profile in ImageRepository.profiles) {
      if (profile.id == profileId) return profile;
    }
    return null;
  }

  String _displayTime(DateTime now) =>
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';

  Future<void> _persist() async {
    if (_failNextPersistenceForTesting) {
      _failNextPersistenceForTesting = false;
      throw StateError('Simulated chat persistence failure');
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(
        _conversations.map((conversation) => conversation.toJson()).toList(),
      ),
    );
  }

  Future<void> _persistDrafts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_draftStorageKey, jsonEncode(_drafts));
  }

  Future<void> _persistSafely() async {
    try {
      await _persist();
    } catch (_) {
      // Keep the in-memory conversation usable when persistence is unavailable.
    }
  }

  @visibleForTesting
  bool get hasActiveConversationSubscriptions =>
      _activeConversationSubscriptions > 0;

  @visibleForTesting
  void failNextPersistenceForTesting() {
    _failNextPersistenceForTesting = true;
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    _accountCleared = false;
    _failNextPersistenceForTesting = false;
    _activeConversationSubscriptions = 0;
    _conversations = _seedConversations();
    _drafts = <String, String>{};
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_storageKey);
      await preferences.remove(_draftStorageKey);
    } catch (_) {
      // Tests can continue with deterministic in-memory conversations.
    }
  }
}
