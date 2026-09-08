import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';

enum AccountDeletionStatus {
  verified,
  processing,
  completed,
  pendingReview,
  failed,
  unknown,
}

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.status,
    required this.canRetry,
    this.requestId,
  });

  final AccountDeletionStatus status;
  final bool canRetry;
  final String? requestId;

  factory AccountDeletionResult.fromResponse(Map<String, dynamic> data) {
    final rawStatus = data['deletionStatus']?.toString();
    final status = switch (rawStatus) {
      'VERIFIED' => AccountDeletionStatus.verified,
      'PROCESSING' => AccountDeletionStatus.processing,
      'COMPLETED' => AccountDeletionStatus.completed,
      'BLOCKED_BY_RETENTION_DECISION' => AccountDeletionStatus.pendingReview,
      'FAILED' => AccountDeletionStatus.failed,
      _ => AccountDeletionStatus.unknown,
    };
    return AccountDeletionResult(
      status: status,
      canRetry: data['canRetry'] == true,
      requestId: data['deletionRequestId']?.toString(),
    );
  }
}

class MatchApiItem {
  const MatchApiItem({required this.id, required this.profile, this.matchedAt});
  final String id;
  final PublicProfileResult profile;
  final DateTime? matchedAt;
}

class PhaseTwoApiService {
  PhaseTwoApiService({AuthService? auth})
    : _auth = auth ?? AuthService.instance;
  static final instance = PhaseTwoApiService();
  final AuthService _auth;

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      (response['data'] as Map?)?.cast<String, dynamic>() ??
      <String, dynamic>{};

  Future<PublicProfileResult> profile(String userId) async {
    final response = await _auth.authenticatedRequest(
      'GET',
      '/api/profiles/$userId',
    );
    return publicProfileFromJson(
      (_data(response)['profile'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> superLikeProfile(String userId) async {
    final targetUserId = int.tryParse(userId);
    if (targetUserId == null || targetUserId < 1) {
      throw const AuthException('The selected profile is unavailable.');
    }
    await _auth.authenticatedRequest(
      'POST',
      '/api/discover/swipe',
      body: {'targetUserId': targetUserId, 'action': 'superLike'},
    );
  }

  Future<List<MatchApiItem>> matches() async {
    final response = await _auth.authenticatedRequest('GET', '/api/matches');
    final values = _data(response)['matches'] as List? ?? const [];
    return values
        .map((value) => _match((value as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<MatchApiItem> match(String matchId) async {
    final response = await _auth.authenticatedRequest(
      'GET',
      '/api/matches/$matchId',
    );
    return _match((_data(response)['match'] as Map).cast<String, dynamic>());
  }

  MatchApiItem _match(Map<String, dynamic> json) => MatchApiItem(
    id: json['id'].toString(),
    profile: publicProfileFromJson(
      (json['profile'] as Map).cast<String, dynamic>(),
    ),
    matchedAt: DateTime.tryParse(json['matchedAt']?.toString() ?? ''),
  );

  Future<List<PublicProfileResult>> blockedProfiles() async {
    final response = await _auth.authenticatedRequest('GET', '/api/blocks');
    final values = _data(response)['blocks'] as List? ?? const [];
    return values
        .map(
          (value) => publicProfileFromJson(
            (((value as Map)['profile']) as Map).cast<String, dynamic>(),
          ),
        )
        .toList();
  }

  Future<void> block(String userId) async =>
      _auth.authenticatedRequest('POST', '/api/blocks/$userId');
  Future<void> unblock(String userId) async =>
      _auth.authenticatedRequest('DELETE', '/api/blocks/$userId');
  Future<void> unmatch(String matchId) async =>
      _auth.authenticatedRequest('DELETE', '/api/matches/$matchId');

  Future<String> report({
    required String targetType,
    String? targetUserId,
    String? targetId,
    required String reason,
    String? notes,
    String? conversationId,
  }) async {
    final response = await _auth.authenticatedRequest(
      'POST',
      '/api/reports',
      body: {
        'targetType': targetType,
        if (targetUserId != null) 'targetUserId': int.parse(targetUserId),
        ...targetId == null
            ? const <String, dynamic>{}
            : {'targetId': targetId},
        'reason': reason,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (conversationId != null) 'conversationId': int.parse(conversationId),
      },
    );
    return ((_data(response)['report'] as Map)['id']).toString();
  }

  Future<void> deactivate() async =>
      _auth.authenticatedRequest('POST', '/api/account/deactivate');
  Future<AccountDeletionResult> deleteAccount({
    required String reason,
    required String deletionConfirmation,
    String? details,
  }) async {
    try {
      final response = await _auth.authenticatedRequest(
        'DELETE',
        '/api/account',
        body: {
          'reason': reason,
          'deletionConfirmation': deletionConfirmation,
          if (details != null && details.trim().isNotEmpty)
            'details': details.trim(),
        },
      );
      return AccountDeletionResult.fromResponse(_data(response));
    } on AuthException catch (error) {
      // A server response with a controlled processing-failure code is a
      // known lifecycle outcome. Transport failures remain exceptions so the
      // UI does not incorrectly claim that the request failed.
      if (error.statusCode == 500 && error.code != null) {
        return const AccountDeletionResult(
          status: AccountDeletionStatus.failed,
          canRetry: false,
        );
      }
      rethrow;
    }
  }
}
