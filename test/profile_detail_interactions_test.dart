import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_rose_gift_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _GiftRemote implements MonetizationRemoteDataSource {
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async => {'success': true, 'data': <String, dynamic>{}};
}

DummyProfile _withNumericId(DummyProfile source) => DummyProfile(
  id: '2',
  gender: source.gender,
  name: source.name,
  age: source.age,
  city: source.city,
  profession: source.profession,
  education: source.education,
  distance: source.distance,
  score: source.score,
  intent: source.intent,
  personality: source.personality,
  status: source.status,
  bio: source.bio,
  interests: source.interests,
  imageUrl: source.imageUrl,
  gallery: source.gallery,
  languages: source.languages,
  verification: source.verification,
  lifestyle: source.lifestyle,
  promptAnswers: source.promptAnswers,
  travelPreference: source.travelPreference,
  musicTaste: source.musicTaste,
  foodPreference: source.foodPreference,
  weekendPlan: source.weekendPlan,
  petPreference: source.petPreference,
  coffeePreference: source.coffeePreference,
  religion: source.religion,
  community: source.community,
  height: source.height,
  fitnessLevel: source.fitnessLevel,
  smoking: source.smoking,
  drinking: source.drinking,
  weed: source.weed,
  children: source.children,
  loveLanguage: source.loveLanguage,
  greenFlags: source.greenFlags,
  redFlags: source.redFlags,
  familyValues: source.familyValues,
  dateIdeas: source.dateIdeas,
  hometown: source.hometown,
  valuedQualities: source.valuedQualities,
  pronouns: source.pronouns,
  sexuality: source.sexuality,
  preferredTalkingHours: source.preferredTalkingHours,
  loveLanguages: source.loveLanguages,
  iceBreaker: source.iceBreaker,
  communicationStyle: source.communicationStyle,
);

void main() {
  final repository = LocalChatRepository.instance;
  final profile = _withNumericId(ImageRepository.profiles.first);

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    AmoraSession.logIn();
    await repository.resetForTesting();
    MonetizationRepository.debugOverride = MonetizationRepository(
      remote: _GiftRemote(),
    );
  });

  tearDown(() {
    MonetizationRepository.debugOverride = null;
    AmoraSession.logOut();
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    ValueChanged<RouteSettings>? onRoute,
    bool buildChat = false,
    Size size = const Size(430, 932),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(body: SizedBox.expand()),
        onGenerateRoute: (settings) {
          onRoute?.call(settings);
          if (settings.name == ProfileDetailScreen.routeName) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => ProfileDetailScreen(profile: profile),
            );
          }
          if (settings.name == ChatDetailScreen.routeName && buildChat) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const ChatDetailScreen(),
            );
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(
              body: Center(child: Text('${settings.name} destination')),
            ),
          );
        },
      ),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(ProfileDetailScreen.routeName, arguments: profile);
    await tester.pumpAndSettle();
  }

  Finder firstReply() =>
      find.byKey(ValueKey('profile-prompt-reply-${profile.id}-prompt-0'));

  Future<void> revealFirstReply(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      firstReply(),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('profile-detail-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openRoseSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('profile-gift-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
  }

  Future<void> finishRoseSend(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump(const Duration(milliseconds: 420));
  }

  testWidgets('prompt cards remove Like and keep one compact Reply action', (
    tester,
  ) async {
    await pumpProfile(tester, size: const Size(320, 760));
    await revealFirstReply(tester);

    final card = find.ancestor(
      of: firstReply(),
      matching: find.byType(ProfilePromptCard),
    );
    expect(card, findsOneWidget);
    expect(
      find.descendant(
        of: card,
        matching: find.byIcon(Icons.favorite_border_rounded),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.text('Reply')),
      findsOneWidget,
    );
    expect(find.byTooltip('Like prompt'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reply opens the existing chat with the exact prompt context', (
    tester,
  ) async {
    RouteSettings? opened;
    await pumpProfile(tester, onRoute: (settings) => opened = settings);
    await revealFirstReply(tester);
    await tester.tap(firstReply());
    await tester.pumpAndSettle();

    expect(opened?.name, ChatDetailScreen.routeName);
    final args = opened!.arguments! as ChatDetailArgs;
    final prompt = profile.promptAnswers.entries.first;
    expect(
      args.conversationId,
      repository.conversationIdForProfile(profile.id),
    );
    expect(args.recipientId, profile.id);
    expect(args.profileId, profile.id);
    expect(args.messageContext?.type, ChatMessageContextType.profilePrompt);
    expect(args.messageContext?.promptId, '${profile.id}-prompt-0');
    expect(args.messageContext?.title, prompt.key);
    expect(args.messageContext?.detail, prompt.value);
  });

  testWidgets('composer removes context without losing typed reply', (
    tester,
  ) async {
    await pumpProfile(tester, buildChat: true);
    await revealFirstReply(tester);
    await tester.tap(firstReply());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chat-composer-context')), findsOneWidget);
    expect(find.text('Replying to profile prompt'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('chat-message-field')),
      'That sounds wonderful.',
    );
    await tester.tap(find.byKey(const ValueKey('remove-chat-context')));
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('chat-message-field')),
    );
    expect(field.controller?.text, 'That sounds wonderful.');
    expect(find.byKey(const ValueKey('chat-composer-context')), findsNothing);
  });

  testWidgets('sent prompt reply appears in the correct conversation', (
    tester,
  ) async {
    await pumpProfile(tester, buildChat: true);
    await revealFirstReply(tester);
    await tester.tap(firstReply());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chat-message-field')),
      'I would enjoy that too.',
    );
    await tester.pump();
    final sendButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('chat-send-button')),
    );
    expect(sendButton.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('chat-send-button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    final conversationId = repository.conversationIdForProfile(profile.id)!;
    final sent = repository.conversation(conversationId)!.messages.last;
    expect(sent.text, 'I would enjoy that too.');
    expect(sent.context?.type, ChatMessageContextType.profilePrompt);
    expect(
      find.byKey(const ValueKey('prompt-reply-chat-context')),
      findsOneWidget,
    );
    expect(find.text('I would enjoy that too.'), findsOneWidget);
  });

  testWidgets('bottom actions are Gift, Super Like, Message, Like at 320px', (
    tester,
  ) async {
    await pumpProfile(tester, size: const Size(320, 760));
    const keys = <String>[
      'profile-gift-button',
      'profile-super-like-button',
      'profile-message-button',
      'profile-like-button',
    ];
    final centers = <double>[];
    for (final key in keys) {
      final finder = find.byKey(ValueKey(key));
      expect(finder, findsOneWidget);
      centers.add(tester.getCenter(finder).dx);
    }
    expect(centers, orderedEquals(centers.toList()..sort()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('four-action bar stays stable at every supported width', (
    tester,
  ) async {
    const widths = <double>[320, 360, 390, 412, 430, 600, 768, 1024];
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in widths) {
      await tester.binding.setSurfaceSize(Size(width, 220));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 220),
              textScaler: const TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ProfileActionBar(
                      liked: false,
                      superLiked: false,
                      superLikeSending: false,
                      giftSending: false,
                      onGift: () {},
                      onLike: () {},
                      onSuperLike: () {},
                      onMessage: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Action bar overflowed at ${width.toInt()} px.',
      );
    }
  });

  testWidgets('Gift offers only Rose for the real recipient', (tester) async {
    await pumpProfile(tester, size: const Size(320, 640));
    await openRoseSheet(tester);

    expect(find.text('Send a Rose'), findsOneWidget);
    expect(find.text('For ${profile.name.split(' ').first}'), findsOneWidget);
    expect(find.byKey(const ValueKey('rose-note-field')), findsOneWidget);
    expect(find.textContaining('Chocolate'), findsNothing);
    expect(find.textContaining('Teddy'), findsNothing);
    expect(find.textContaining('Ring'), findsNothing);
  });

  testWidgets('Rose with an optional note appears in the correct chat', (
    tester,
  ) async {
    await pumpProfile(tester, buildChat: true);
    await openRoseSheet(tester);
    await tester.enterText(
      find.byKey(const ValueKey('rose-note-field')),
      'I would love to get to know you.',
    );
    await tester.tap(find.byKey(const ValueKey('send-rose-button')));
    await finishRoseSend(tester);

    final conversationId = repository.conversationIdForProfile(profile.id)!;
    final sent = repository.conversation(conversationId)!.messages.last;
    expect(sent.text, 'I would love to get to know you.');
    expect(sent.context?.type, ChatMessageContextType.rose);
    expect(find.byKey(const ValueKey('rose-chat-message')), findsOneWidget);
    expect(find.text('Rose'), findsOneWidget);
  });

  testWidgets(
    'Rose send failure preserves note and retries without duplicate',
    (tester) async {
      await pumpProfile(tester, buildChat: true);
      await openRoseSheet(tester);
      await tester.enterText(
        find.byKey(const ValueKey('rose-note-field')),
        'Please keep this note.',
      );
      final conversationId = repository.conversationIdForProfile(profile.id)!;
      final initialMessageCount = repository
          .conversation(conversationId)!
          .messages
          .length;
      repository.failNextPersistenceForTesting();
      await tester.tap(find.byKey(const ValueKey('send-rose-button')));
      await tester.pump(const Duration(milliseconds: 320));

      expect(find.text('Couldn’t send the Rose'), findsOneWidget);
      final note = tester.widget<TextField>(
        find.byKey(const ValueKey('rose-note-field')),
      );
      expect(note.controller?.text, 'Please keep this note.');
      expect(
        repository.conversation(conversationId)!.messages,
        hasLength(initialMessageCount),
      );

      await tester.tap(find.byKey(const ValueKey('send-rose-button')));
      await finishRoseSend(tester);
      final messages = repository.conversation(conversationId)!.messages;
      expect(messages, hasLength(initialMessageCount + 1));
      expect(messages.last.status, ChatMessageStatus.sent);
    },
  );

  testWidgets('Rose sheet prevents duplicate sends while processing', (
    tester,
  ) async {
    final completer = Completer<bool>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmoraaRoseGiftSheet(
            recipientName: profile.name,
            onSend: (_) {
              calls++;
              return completer.future;
            },
          ),
        ),
      ),
    );

    final send = find.byKey(const ValueKey('send-rose-button'));
    await tester.tap(send);
    await tester.pump();
    await tester.tap(send);
    await tester.pump();
    expect(calls, 1);
    completer.complete(false);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
