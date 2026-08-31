import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/rose/data/rose_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_rose_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _RoseRemote implements RoseRemoteDataSource {
  int sendCalls = 0;
  Object? sendError;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (method == 'POST' && path == '/api/roses/send') {
      sendCalls++;
      if (sendError case final error?) throw error;
      return {
        'success': true,
        'data': {
          'roseTransaction': {
            'id': '101',
            'senderId': '1',
            'recipientId': body?['recipientId'].toString(),
            'status': 'sent',
            'note': body?['note'],
            'createdAt': '2026-08-12T10:00:00.000Z',
          },
          'notification': {'id': '12'},
        },
      };
    }
    return {'success': true, 'data': <String, dynamic>{}};
  }
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
  status: source.status,
  bio: source.bio,
  interests: source.interests,
  imageUrl: source.imageUrl,
  gallery: source.gallery,
  languages: source.languages,
  verification: source.verification,
  lifestyle: source.lifestyle,
  promptAnswers: source.promptAnswers,
  religion: source.religion,
  community: source.community,
  height: source.height,
  smoking: source.smoking,
  drinking: source.drinking,
  weed: source.weed,
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
  late _RoseRemote roseRemote;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    AmoraSession.logIn();
    await repository.resetForTesting();
    roseRemote = _RoseRemote();
    RoseRepository.debugOverride = RoseRepository(remote: roseRemote);
  });

  tearDown(() {
    RoseRepository.debugOverride = null;
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
    await tester.tap(find.byKey(const ValueKey('profile-rose-button')));
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

  testWidgets('bottom actions are Rose, Super Like, Message, Like at 320px', (
    tester,
  ) async {
    await pumpProfile(tester, size: const Size(320, 760));
    const keys = <String>[
      'profile-rose-button',
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
    const widths = <double>[320, 360, 375, 390, 393, 412, 430, 600, 768, 1024];
    const buttonKeys = <String>[
      'profile-rose-button',
      'profile-super-like-button',
      'profile-message-button',
      'profile-like-button',
    ];
    const labels = <String>['Rose', 'Super Like', 'Message', 'Like'];
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
                      liked: true,
                      superLiked: false,
                      superLikeSending: false,
                      roseSending: false,
                      onRose: () {},
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
      final buttonWidths = <double>[];
      final buttonCenters = <double>[];
      final iconCenters = <double>[];
      final labelCenters = <double>[];
      TextStyle? referenceLabelStyle;
      for (var index = 0; index < buttonKeys.length; index++) {
        final button = find.byKey(ValueKey(buttonKeys[index]));
        final circle = find.descendant(
          of: button,
          matching: find.byType(AnimatedContainer),
        );
        final label = find.descendant(
          of: button,
          matching: find.text(labels[index]),
        );
        final paragraph = find.descendant(
          of: label,
          matching: find.byType(RichText),
        );
        expect(circle, findsOneWidget, reason: labels[index]);
        expect(label, findsOneWidget, reason: labels[index]);
        expect(tester.getSize(circle), const Size.square(36));
        expect(
          tester.renderObject<RenderParagraph>(paragraph).didExceedMaxLines,
          isFalse,
          reason: '${labels[index]} truncated at ${width.toInt()} px',
        );
        buttonWidths.add(tester.getSize(button).width);
        buttonCenters.add(tester.getCenter(button).dx);
        iconCenters.add(tester.getCenter(circle).dy);
        labelCenters.add(tester.getCenter(label).dy);

        final style = tester.widget<Text>(label).style!;
        referenceLabelStyle ??= style;
        expect(style.fontFamily, referenceLabelStyle.fontFamily);
        expect(style.fontSize, referenceLabelStyle.fontSize);
        expect(style.fontWeight, referenceLabelStyle.fontWeight);
        expect(style.height, referenceLabelStyle.height);
        expect(style.letterSpacing, referenceLabelStyle.letterSpacing);
        expect(style.color, referenceLabelStyle.color);
        expect(style.color, AppColors.textNeutral);
      }
      for (final buttonWidth in buttonWidths.skip(1)) {
        expect(buttonWidth, moreOrLessEquals(buttonWidths.first, epsilon: .01));
      }
      for (final iconCenter in iconCenters.skip(1)) {
        expect(iconCenter, moreOrLessEquals(iconCenters.first, epsilon: .01));
      }
      for (final labelCenter in labelCenters.skip(1)) {
        expect(labelCenter, moreOrLessEquals(labelCenters.first, epsilon: .01));
      }
      final gaps = <double>[
        for (var index = 1; index < buttonCenters.length; index++)
          buttonCenters[index] - buttonCenters[index - 1],
      ];
      for (final gap in gaps.skip(1)) {
        expect(gap, moreOrLessEquals(gaps.first, epsilon: .01));
      }
      expect(
        tester.takeException(),
        isNull,
        reason: 'Action bar overflowed at ${width.toInt()} px.',
      );
    }
  });

  testWidgets('profile content stays above actions and the bottom safe area', (
    tester,
  ) async {
    const scenarios = <({Size size, double bottomInset})>[
      (size: Size(320, 568), bottomInset: 24),
      (size: Size(360, 640), bottomInset: 0),
      (size: Size(375, 667), bottomInset: 34),
      (size: Size(390, 700), bottomInset: 24),
      (size: Size(393, 852), bottomInset: 34),
      (size: Size(412, 915), bottomInset: 24),
      (size: Size(430, 932), bottomInset: 34),
      (size: Size(600, 960), bottomInset: 24),
    ];
    const longAbout =
        'Thoughtful conversation, a calm sense of humour, and kindness matter. '
        'Weekends are for books, long walks, family dinners, and finding small '
        'places with excellent coffee. Looking for a grounded partnership '
        'where curiosity, honesty, warmth, and mutual respect can keep growing. '
        'The final sentence must remain completely visible above the actions.';
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final scenario in scenarios) {
      await tester.binding.setSurfaceSize(scenario.size);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: scenario.size,
              padding: EdgeInsets.only(bottom: scenario.bottomInset),
              textScaler: const TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SafeArea(
                child: AmoraaPublicProfileView(
                  mode: PublicProfileViewMode.otherUser,
                  scrollKey: const ValueKey('profile-overlap-test-scroll'),
                  galleryBuilder: (context, height, desktop) => SizedBox(
                    height: height,
                    child: const ColoredBox(color: AppColors.tertiary),
                  ),
                  story: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About me'),
                      SizedBox(height: AmoraSpacing.space12),
                      Text(
                        longAbout,
                        key: ValueKey('profile-overlap-test-last-content'),
                      ),
                    ],
                  ),
                  interactionBar: ProfileActionBar(
                    liked: true,
                    superLiked: false,
                    superLikeSending: false,
                    roseSending: false,
                    onRose: () {},
                    onLike: () {},
                    onSuperLike: () {},
                    onMessage: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(
            of: find.byKey(const ValueKey('profile-overlap-test-scroll')),
            matching: find.byType(Scrollable),
          )
          .first;
      final actionBar = find.byType(ProfileActionBar);
      expect(
        tester.getTopLeft(actionBar).dy - tester.getBottomLeft(scrollable).dy,
        greaterThanOrEqualTo(AmoraSpacing.space8),
        reason: '${scenario.size} fixed action separation',
      );
      expect(
        tester.getBottomLeft(actionBar).dy,
        lessThanOrEqualTo(
          scenario.size.height - scenario.bottomInset - AmoraSpacing.space8,
        ),
        reason: '${scenario.size} bottom safe area',
      );

      final scrollState = tester.state<ScrollableState>(scrollable);
      scrollState.position.jumpTo(scrollState.position.maxScrollExtent);
      await tester.pump();
      final lastContent = find.byKey(
        const ValueKey('profile-overlap-test-last-content'),
      );
      expect(
        tester.getBottomLeft(lastContent).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(actionBar).dy - AmoraSpacing.space16,
        ),
        reason: '${scenario.size} long About me visibility',
      );
      expect(tester.takeException(), isNull, reason: '${scenario.size}');
    }
  });

  testWidgets('Rose sheet targets the real recipient', (tester) async {
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
    expect(find.text('Rose'), findsWidgets);
  });

  testWidgets(
    'confirmed Rose remains successful when optional chat card fails',
    (tester) async {
      await pumpProfile(tester, buildChat: true);
      final conversationId = await repository.createConversationForProfile(
        profile,
      );
      await openRoseSheet(tester);
      await tester.enterText(
        find.byKey(const ValueKey('rose-note-field')),
        'Please keep this note.',
      );
      final initialMessageCount = repository
          .conversation(conversationId)!
          .messages
          .length;
      repository.failNextPersistenceForTesting();
      await tester.tap(find.byKey(const ValueKey('send-rose-button')));
      await finishRoseSend(tester);

      expect(
        repository.conversation(conversationId)!.messages,
        hasLength(initialMessageCount),
      );
      expect(roseRemote.sendCalls, 1);
    },
  );

  testWidgets('Rose sheet prevents duplicate sends while processing', (
    tester,
  ) async {
    final completer = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmoraaRoseSheet(
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
    completer.completeError(
      const AuthException('Rose sending is temporarily unavailable.'),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text('Rose sending is temporarily unavailable.'),
      findsOneWidget,
    );
  });

  testWidgets('failed Rose creates no optional conversation or success state', (
    tester,
  ) async {
    roseRemote.sendError = const AuthException(
      'Rose sending is unavailable for this profile.',
      code: 'ROSE_NOT_ALLOWED',
      statusCode: 403,
    );
    await pumpProfile(tester);
    expect(repository.conversationIdForProfile(profile.id), isNull);

    await openRoseSheet(tester);
    expect(repository.conversationIdForProfile(profile.id), isNull);
    await tester.tap(find.byKey(const ValueKey('send-rose-button')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(roseRemote.sendCalls, 1);
    expect(repository.conversationIdForProfile(profile.id), isNull);
    expect(
      find.text('Rose sending is unavailable for this profile.'),
      findsOneWidget,
    );
    expect(
      find.text('Rose sent to ${profile.name.split(' ').first}'),
      findsNothing,
    );
  });
}
