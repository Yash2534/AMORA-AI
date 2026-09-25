import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AiChatRemote implements ChatRemoteDataSource {
  _AiChatRemote({this.error});
  final AuthException? error;
  String? method;
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    this.method = method;
    this.path = path;
    this.body = body;
    if (error != null) throw error!;
    return {
      'success': true,
      'data': {
        'conversation': {
          'id': this.body?['targetUserId'] == 2 ? '900' : '901',
          'participant': {
            'id': this.body?['targetUserId']?.toString() ?? '',
            'name': 'Candidate ${this.body?['targetUserId']}',
          },
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> upload(
    String path,
    AmoraPickedMedia media,
  ) async => throw UnimplementedError();
}

MatchApiItem recommendation(String id, int score, int aiScore) =>
    MatchApiItem.fromAiRecommendation({
      'id': id,
      'compatibilityScore': score,
      'compatibilityCoverage': 85,
      'aiConfidence': 82,
      'aiMatchScore': aiScore,
      'aiReasons': [
        'You both prefer calls.',
        'You share 1 interest, including music.',
      ],
      'profile': {
        'id': id,
        'name': 'Candidate $id',
        'score': score,
        'intent': 'long term',
      },
    });

class RecommendationApi extends PhaseTwoApiService {
  @override
  Future<List<MatchApiItem>> aiRecommendations() async => [
    recommendation('2', 80, 84),
    recommendation('1', 81, 81),
  ];

  @override
  Future<MatchApiItem> match(String matchId) async => throw StateError(
    'AI candidate user IDs must not be fetched as match IDs',
  );
}

void main() {
  tearDown(() => ChatRepository.instance.resetForTesting());

  test(
    'AI response retains current confidence, coverage, score and reasons',
    () {
      final profile = recommendation('2', 80, 84).profile.profile;
      expect(profile.score, 80);
      expect(profile.aiMatchScore, 84);
      expect(profile.aiConfidence, 82);
      expect(profile.compatibilityCoverage, 85);
      expect(profile.aiReasons.first, 'You both prefer calls.');
      final legacy = publicProfileFromJson({'id': '1'}).profile;
      expect(legacy.aiConfidence, isNull);
      expect(legacy.aiReasons, isEmpty);
      expect(
        publicProfileFromJson({
          'aiConfidence': double.nan,
        }).profile.aiConfidence,
        isNull,
      );
    },
  );

  testWidgets('AI screen preserves server order and shows calculated reasons', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: MatchesScreen(api: RecommendationApi())),
    );
    await tester.pumpAndSettle();
    final featured = tester.widget<FeaturedAiMatchCard>(
      find.byType(FeaturedAiMatchCard),
    );
    expect(
      featured.profile.id,
      '2',
    ); // Server evidence ranking beats raw compatibility order.
    expect(find.text('You both prefer calls.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'View Profile routes the selected AI user without requiring a Match',
    (tester) async {
      RouteSettings? opened;
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            opened = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Profile Details')),
            );
          },
          home: MatchesScreen(api: RecommendationApi()),
        ),
      );
      await tester.pumpAndSettle();
      final card = tester.widget<FeaturedAiMatchCard>(
        find.byType(FeaturedAiMatchCard),
      );
      card.onOpenProfile();
      await tester.pumpAndSettle();

      expect(opened?.name, '/profile-detail');
      expect((opened?.arguments as dynamic).id, '2');
      expect(find.text('Profile Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'matched AI Message uses candidate user ID and opens returned conversation ID',
    (tester) async {
      final remote = _AiChatRemote();
      await ChatRepository.instance.resetForTesting(remote: remote);
      RouteSettings? opened;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            opened = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Chat')),
            );
          },
          home: MatchesScreen(api: RecommendationApi()),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<FeaturedAiMatchCard>(find.byType(FeaturedAiMatchCard))
          .onMessage();
      await tester.pump(const Duration(milliseconds: 300));

      expect(remote.method, 'POST');
      expect(remote.path, '/api/conversations');
      expect(remote.body, {'targetUserId': 2});
      expect(opened?.name, ChatDetailScreen.routeName);
      expect((opened?.arguments as ChatDetailArgs).conversationId, '900');
    },
  );

  testWidgets('unmatched AI Message explains that a Match is required', (
    tester,
  ) async {
    await ChatRepository.instance.resetForTesting(
      remote: _AiChatRemote(
        error: const AuthException(
          'Match required.',
          code: 'MATCH_REQUIRED',
          statusCode: 403,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: MatchesScreen(api: RecommendationApi())),
    );
    await tester.pumpAndSettle();
    tester
        .widget<FeaturedAiMatchCard>(find.byType(FeaturedAiMatchCard))
        .onMessage();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Match first to start a conversation.'), findsOneWidget);
    expect(find.text('Chat is no longer available.'), findsNothing);
  });

  testWidgets('a different AI recommendation messages its own candidate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final remote = _AiChatRemote();
    await ChatRepository.instance.resetForTesting(remote: remote);
    RouteSettings? opened;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          opened = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Chat')),
          );
        },
        home: MatchesScreen(api: RecommendationApi()),
      ),
    );
    await tester.pumpAndSettle();
    final secondCard = find.byType(AiMatchCard).first;
    final second = tester.widget<AiMatchCard>(secondCard);
    expect(second.profile.id, '1');
    second.onMessage();
    await tester.pump(const Duration(milliseconds: 300));

    expect(remote.body, {'targetUserId': 1});
    expect((opened?.arguments as ChatDetailArgs).conversationId, '901');
  });

  testWidgets('explanation separates coverage and evidence confidence', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WhyThisMatchSheet(
            profile: recommendation('2', 80, 84).profile.profile,
          ),
        ),
      ),
    );
    expect(find.text('Information coverage'), findsOneWidget);
    expect(find.text('Recommendation evidence'), findsOneWidget);
    expect(
      find.text('82/100 evidence support; not a probability of success'),
      findsOneWidget,
    );
    expect(find.text('You both prefer calls.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
