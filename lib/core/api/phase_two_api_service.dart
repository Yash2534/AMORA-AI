import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';

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
      },
    );
    return ((_data(response)['report'] as Map)['id']).toString();
  }

  Future<void> deactivate() async =>
      _auth.authenticatedRequest('POST', '/api/account/deactivate');
  Future<void> deleteAccount({required String reason, String? details}) async {
    await _auth.authenticatedRequest(
      'DELETE',
      '/api/account',
      body: {
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
    await _auth.clearSession();
  }
}
