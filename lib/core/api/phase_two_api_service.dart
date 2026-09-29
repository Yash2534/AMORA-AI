import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';

const accountDeletionReasonTextMaxLength = 500;

enum AccountDeletionReason {
  foundSomeone('FOUND_SOMEONE', 'I found someone'),
  takingABreak('TAKING_A_BREAK', 'I am taking a break'),
  notEnoughMatches('NOT_ENOUGH_MATCHES', 'I am not getting enough matches'),
  privacyConcerns('PRIVACY_CONCERNS', 'I have privacy concerns'),
  technicalIssues('TECHNICAL_ISSUES', 'I am facing technical issues'),
  noLongerUseApp('NO_LONGER_USE_APP', 'I do not use the app anymore'),
  other('OTHER', 'Other');

  const AccountDeletionReason(this.code, this.label);

  final String code;
  final String label;
}

class AccountDeletionMethod {
  const AccountDeletionMethod({
    required this.channel,
    required this.maskedDestination,
  });

  final String channel;
  final String maskedDestination;

  factory AccountDeletionMethod.fromJson(Map<String, dynamic> json) =>
      AccountDeletionMethod(
        channel: json['channel']?.toString() ?? '',
        maskedDestination: json['maskedDestination']?.toString() ?? '',
      );
}

class MatchApiItem {
  const MatchApiItem({required this.id, required this.profile, this.matchedAt});
  final String id;
  final PublicProfileResult profile;
  final DateTime? matchedAt;

  factory MatchApiItem.fromAiRecommendation(Map<String, dynamic> item) {
    return MatchApiItem(
      id: item['id'].toString(),
      profile: publicProfileFromJson({
        ...(item['profile'] as Map).cast<String, dynamic>(),
        'compatibilityCoverage': item['compatibilityCoverage'],
        'aiConfidence': item['aiConfidence'],
        'aiMatchScore': item['aiMatchScore'],
        'aiReasons': item['aiReasons'],
      }),
    );
  }
}

class AiRecommendationsPage {
  const AiRecommendationsPage({
    required this.items,
    required this.hasMore,
    required this.limit,
    this.nextCursor,
    this.rankingVersion = '',
  });

  final List<MatchApiItem> items;
  final bool hasMore;
  final int limit;
  final String? nextCursor;
  final String rankingVersion;
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

  Future<AiRecommendationsPage> aiRecommendations({
    String? cursor,
    int limit = 10,
  }) async {
    final path = Uri(
      path: '/api/discover/ai-matches',
      queryParameters: <String, String>{
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    ).toString();
    final response = await _auth.authenticatedRequest('GET', path);
    final data = _data(response);
    final values = data['recommendations'] as List? ?? const [];
    final pagination = data['pagination'] as Map?;
    return AiRecommendationsPage(
      items: values
          .map((value) {
            final item = (value as Map).cast<String, dynamic>();
            return MatchApiItem.fromAiRecommendation(item);
          })
          .toList(growable: false),
      hasMore: pagination?['hasMore'] == true,
      limit: (pagination?['limit'] as num?)?.toInt() ?? limit,
      nextCursor: pagination?['nextCursor']?.toString(),
      rankingVersion: pagination?['rankingVersion']?.toString() ?? '',
    );
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

  Future<void> deactivate(String password) async => _auth.authenticatedRequest(
    'POST',
    '/api/account/deactivate',
    body: {'password': password},
  );
  Future<List<AccountDeletionMethod>> accountDeletionMethods() async {
    final response = await _auth.authenticatedRequest(
      'GET',
      '/api/account/delete/methods',
    );
    final methods = _data(response)['methods'] as List? ?? const [];
    return methods
        .map(
          (method) => AccountDeletionMethod.fromJson(
            (method as Map).cast<String, dynamic>(),
          ),
        )
        .where(
          (method) =>
              method.channel.isNotEmpty && method.maskedDestination.isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<void> sendAccountDeletionOtp(String channel) async =>
      _auth.authenticatedRequest(
        'POST',
        '/api/account/delete/send-otp',
        body: {'channel': channel},
      );

  Future<void> confirmAccountDeletion({
    required String channel,
    required String otp,
    String? reasonCode,
    String? reasonText,
  }) async => _auth.authenticatedRequest(
    'POST',
    '/api/account/delete/confirm',
    body: {
      'channel': channel,
      'otp': otp,
      'reasonCode': reasonCode,
      'reasonText': reasonText,
    },
  );
}
