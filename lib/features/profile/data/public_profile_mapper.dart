import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';

class PublicRelationshipState {
  const PublicRelationshipState({
    this.liked = false,
    this.superLiked = false,
    this.blocked = false,
    this.matched = false,
    this.saved = false,
    this.matchId,
  });

  final bool liked;
  final bool superLiked;
  final bool blocked;
  final bool matched;
  final bool saved;
  final String? matchId;

  factory PublicRelationshipState.fromJson(Map<String, dynamic>? json) {
    final value = json ?? const <String, dynamic>{};
    return PublicRelationshipState(
      liked: value['liked'] == true,
      superLiked: value['superLiked'] == true,
      blocked: value['blocked'] == true,
      matched: value['matched'] == true,
      saved: value['saved'] == true,
      matchId: value['matchId']?.toString(),
    );
  }
}

class PublicProfileResult {
  const PublicProfileResult({
    required this.profile,
    required this.relationship,
  });

  final DummyProfile profile;
  final PublicRelationshipState relationship;
}

PublicProfileResult publicProfileFromJson(Map<String, dynamic> json) {
  List<String> strings(Object? value) => value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const <String>[];
  Map<String, String> stringMap(Object? value) => value is Map
      ? value.map((key, item) => MapEntry(key.toString(), item.toString()))
      : const <String, String>{};
  final storedGender = json['gender']?.toString().toLowerCase() ?? '';
  final gender = (storedGender == 'man' || storedGender == 'male')
      ? Gender.male
      : Gender.female;
  final lifestyleValue = json['lifestyle'];
  final lifestyle = lifestyleValue is Map
      ? lifestyleValue.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .toList()
      : strings(lifestyleValue);
  final imageUrl = json['imageUrl']?.toString() ?? '';
  final gallery = strings(json['gallery']);
  final compatibility = (json['compatibility'] as Map?)
      ?.cast<String, dynamic>();
  final compatibilityReasons = (compatibility?['reasons'] as List? ?? const [])
      .whereType<Map>()
      .map(
        (value) => CompatibilityReason(
          factor: value['factor']?.toString() ?? '',
          label: value['label']?.toString() ?? '',
          score: ((value['score'] as num?)?.round() ?? 0).clamp(0, 100),
        ),
      )
      .where((reason) => reason.label.trim().isNotEmpty)
      .toList(growable: false);
  final profile = DummyProfile(
    id: json['id']?.toString() ?? '',
    gender: gender,
    name: json['name']?.toString() ?? '',
    age: (json['age'] as num?)?.toInt() ?? 0,
    city: json['city']?.toString() ?? '',
    profession: json['profession']?.toString() ?? '',
    education: json['education']?.toString() ?? '',
    distance: json['distance'] is num
        ? '${(json['distance'] as num).round()} km'
        : json['distance']?.toString() ?? '',
    score: (json['score'] as num?)?.round() ?? 0,
    intent: json['intent']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    bio: json['bio']?.toString() ?? '',
    interests: strings(json['interests']),
    imageUrl: imageUrl,
    gallery: gallery.isEmpty && imageUrl.isNotEmpty
        ? <String>[imageUrl]
        : gallery,
    languages: strings(json['languages']),
    verification: json['verification']?.toString() ?? 'Unverified',
    lifestyle: lifestyle,
    promptAnswers: stringMap(json['promptAnswers']),
    religion: json['religion']?.toString() ?? '',
    community: json['community']?.toString() ?? '',
    height: json['height']?.toString() ?? '',
    smoking: json['smoking']?.toString() ?? '',
    drinking: json['drinking']?.toString() ?? '',
    weed: json['weed']?.toString() ?? '',
    hometown: json['hometown']?.toString() ?? '',
    valuedQualities: strings(json['valuedQualities']),
    pronouns: strings(json['pronouns']),
    sexuality: json['sexuality']?.toString() ?? '',
    preferredTalkingHours: strings(json['preferredTalkingHours']),
    loveLanguages: strings(json['loveLanguages']),
    iceBreaker: json['iceBreaker']?.toString() ?? '',
    communicationStyle: CommunicationStyle.fromStorageValue(
      json['communicationStyle'],
    ),
    compatibilityReasons: compatibilityReasons,
    compatibilityMethod: compatibility?['method']?.toString() ?? '',
    compatibilityDisclaimer: compatibility?['disclaimer']?.toString() ?? '',
  );
  return PublicProfileResult(
    profile: profile,
    relationship: PublicRelationshipState.fromJson(
      (json['relationship'] as Map?)?.cast<String, dynamic>(),
    ),
  );
}
