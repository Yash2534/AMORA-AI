import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';

class PublicRelationshipState {
  const PublicRelationshipState({
    this.liked = false,
    this.superLiked = false,
    this.blocked = false,
    this.matched = false,
    this.matchId,
  });

  final bool liked;
  final bool superLiked;
  final bool blocked;
  final bool matched;
  final String? matchId;

  factory PublicRelationshipState.fromJson(Map<String, dynamic>? json) {
    final value = json ?? const <String, dynamic>{};
    return PublicRelationshipState(
      liked: value['liked'] == true,
      superLiked: value['superLiked'] == true,
      blocked: value['blocked'] == true,
      matched: value['matched'] == true,
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
  final gender = (json['gender']?.toString().toLowerCase() ?? '') == 'man'
      ? Gender.male
      : Gender.female;
  final lifestyleValue = json['lifestyle'];
  final lifestyle = lifestyleValue is Map
      ? lifestyleValue.values.map((item) => item.toString()).toList()
      : strings(lifestyleValue);
  final imageUrl = json['imageUrl']?.toString() ?? '';
  final gallery = strings(json['gallery']);
  final profile = DummyProfile(
    id: json['id']?.toString() ?? '',
    gender: gender,
    name: json['name']?.toString() ?? '',
    age: (json['age'] as num?)?.toInt() ?? 0,
    city: json['city']?.toString() ?? '',
    profession: json['profession']?.toString() ?? '',
    education: json['education']?.toString() ?? '',
    distance: json['distance']?.toString() ?? '',
    score: (json['score'] as num?)?.round() ?? 0,
    intent: json['intent']?.toString() ?? '',
    personality: json['personality']?.toString() ?? '',
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
    travelPreference: json['travelPreference']?.toString() ?? '',
    musicTaste: json['musicTaste']?.toString() ?? '',
    foodPreference: json['foodPreference']?.toString() ?? '',
    weekendPlan: json['weekendPlan']?.toString() ?? '',
    petPreference: json['petPreference']?.toString() ?? '',
    coffeePreference: json['coffeePreference']?.toString() ?? '',
    religion: json['religion']?.toString() ?? '',
    community: json['community']?.toString() ?? '',
    height: json['height']?.toString() ?? '',
    fitnessLevel: json['fitnessLevel']?.toString() ?? '',
    smoking: json['smoking']?.toString() ?? '',
    drinking: json['drinking']?.toString() ?? '',
    weed: json['weed']?.toString() ?? '',
    children: json['children']?.toString() ?? '',
    loveLanguage: json['loveLanguage']?.toString() ?? '',
    greenFlags: strings(json['greenFlags']),
    redFlags: strings(json['redFlags']),
    familyValues: json['familyValues']?.toString() ?? '',
    dateIdeas: strings(json['dateIdeas']),
    hometown: json['hometown']?.toString() ?? '',
    valuedQualities: strings(json['valuedQualities']),
    pronouns: strings(json['pronouns']),
    sexuality: json['sexuality']?.toString() ?? '',
    preferredTalkingHours: strings(json['preferredTalkingHours']),
    loveLanguages: strings(json['loveLanguages']),
    communicationStyle: CommunicationStyle.fromStorageValue(
      json['communicationStyle'],
    ),
  );
  return PublicProfileResult(
    profile: profile,
    relationship: PublicRelationshipState.fromJson(
      (json['relationship'] as Map?)?.cast<String, dynamic>(),
    ),
  );
}
