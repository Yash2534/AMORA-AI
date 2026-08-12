import 'dart:math';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/rose/domain/rose_models.dart';

abstract interface class RoseRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}

class AuthRoseRemoteDataSource implements RoseRemoteDataSource {
  const AuthRoseRemoteDataSource();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => AuthService.instance.authenticatedRequest(method, path, body: body);
}

class RoseRepository {
  RoseRepository({RoseRemoteDataSource? remote})
    : _remote = remote ?? const AuthRoseRemoteDataSource();

  static final _singleton = RoseRepository();
  static RoseRepository? debugOverride;
  static RoseRepository get instance => debugOverride ?? _singleton;

  final RoseRemoteDataSource _remote;

  String newIdempotencyKey() =>
      'flutter:rose:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 32)}';

  Future<RoseSendResult> send({
    required String recipientId,
    required String idempotencyKey,
    String? conversationId,
    String? note,
  }) async {
    final response = await _remote.request(
      'POST',
      '/api/roses/send',
      body: {
        'recipientId': int.parse(recipientId),
        'idempotencyKey': idempotencyKey,
        if (conversationId != null) 'conversationId': int.parse(conversationId),
        if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
      },
    );
    final data = ((response['data'] as Map?) ?? const <String, dynamic>{})
        .cast<String, dynamic>();
    return RoseSendResult.fromJson(data);
  }
}
