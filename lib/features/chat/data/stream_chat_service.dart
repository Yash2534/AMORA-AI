import 'dart:developer' as developer;

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class StreamChatSession {
  const StreamChatSession({required this.apiKey, required this.userId, required this.token});
  final String apiKey; final String userId; final String token;
}

class StreamChatService {
  StreamChatService._();
  static final instance = StreamChatService._();
  StreamChatClient? _client;
  String? _apiKey;
  String? _connectedUserId;
  final Map<String, Channel> _channels = {};
  StreamChatClient? get client => _client;
  String? get connectedUserId => _connectedUserId;

  Future<StreamChatSession> connectAuthenticatedUser() async {
    final response = await AuthService.instance.authenticatedRequest('GET', '/api/chat/token');
    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final apiKey = data['apiKey'] as String?; final userId = data['userId'] as String?; final token = data['token'] as String?;
    if (apiKey == null || userId == null || token == null) throw const AuthException('Stream Chat returned an invalid session.');
    if (_client == null || _apiKey != apiKey) { _client = StreamChatClient(apiKey, logLevel: Level.OFF); _apiKey = apiKey; }
    if (_connectedUserId != userId) {
      if (_connectedUserId != null) await _client!.disconnectUser();
      final user = AuthService.instance.currentUser;
      await _client!.connectUser(User(id: userId, name: user?.name ?? ''), token);
      _connectedUserId = userId;
    }
    return StreamChatSession(apiKey: apiKey, userId: userId, token: token);
  }

  Future<Channel> openMatchedChannel(String matchId) async {
    developer.log('[Stream] Opening matched chat', name: 'AmoraStream');
    developer.log('[Stream] Match ID: $matchId', name: 'AmoraStream');
    if (_client == null || _connectedUserId == null) await connectAuthenticatedUser();
    developer.log('[Stream] Requesting Stream channel', name: 'AmoraStream');
    final cached = _channels[matchId];
    if (cached != null) return cached;
    final response = await AuthService.instance.authenticatedRequest('POST', '/api/chat/channels/$matchId');
    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final channelId = data['channelId'] as String?; final channelType = data['channelType'] as String?;
    final client = _client;
    if (client == null || channelId == null || channelType == null) throw const AuthException('Stream Chat channel is unavailable.');
    developer.log('[Stream] Stream channel created: $channelId', name: 'AmoraStream');
    final channel = client.channel(channelType, id: channelId);
    await channel.watch();
    _channels[matchId] = channel;
    developer.log('[Stream] Channel connected', name: 'AmoraStream');
    return channel;
  }

  Future<void> markRead(String matchId) async {
    final channel = await openMatchedChannel(matchId);
    await channel.markRead();
  }

  Future<void> disconnect() async { if (_client != null && _connectedUserId != null) await _client!.disconnectUser(); _channels.clear(); _connectedUserId = null; }
}
