import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/presentation/widgets/chat_presence_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = LocalChatRepository.instance;

  setUp(() async {
    await repository.resetForTesting();
  });

  Future<void> pumpConversation(
    WidgetTester tester,
    String conversationId, {
    Size size = const Size(430, 932),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: RouteSettings(
            name: ChatDetailScreen.routeName,
            arguments: ChatDetailArgs(conversationId: conversationId),
          ),
          builder: (_) => ChatDetailScreen(key: ValueKey(conversationId)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpHeader(
    WidgetTester tester, {
    required DummyProfile profile,
    required bool online,
    required String status,
    Size size = const Size(320, 568),
    double textScale = 1,
    VoidCallback? onBack,
    VoidCallback? onMore,
    VoidCallback? onProfileTap,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: ChatHeader(
                profile: profile,
                online: online,
                status: status,
                onBack: onBack ?? () {},
                onMore: onMore ?? () {},
                onProfileTap: onProfileTap ?? () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selected conversation renders its own participant and history', (
    tester,
  ) async {
    final conversation = repository.conversations[1];
    await pumpConversation(tester, conversation.id);

    expect(find.text(conversation.user.name), findsOneWidget);
    expect(
      find.text(
        conversation.online
            ? 'Online'
            : conversation.user.status.trim().isEmpty
            ? 'Offline'
            : conversation.user.status.trim(),
      ),
      findsOneWidget,
    );
    expect(find.text(conversation.messages.first.text), findsOneWidget);
    expect(
      find.text('Offline: messages remain queued on this device.'),
      findsNothing,
    );
    expect(find.text(repository.conversations.first.user.name), findsNothing);
    expect(repository.hasActiveConversationSubscriptions, isTrue);
  });

  testWidgets('shared header keeps identity directly beside Back', (
    tester,
  ) async {
    final profile = repository.conversations.first.user;
    var backTaps = 0;
    var moreTaps = 0;
    var profileTaps = 0;
    await pumpHeader(
      tester,
      profile: profile,
      online: true,
      status: 'Online',
      onBack: () => backTaps++,
      onMore: () => moreTaps++,
      onProfileTap: () => profileTaps++,
    );

    final back = tester.getRect(find.byKey(const ValueKey('chat-header-back')));
    final avatar = tester.getRect(
      find.byKey(const ValueKey('chat-header-avatar')),
    );
    final identity = tester.getRect(
      find.byKey(const ValueKey('chat-header-name-status')),
    );
    final more = tester.getRect(find.byKey(const ValueKey('chat-header-more')));
    expect(back.left, lessThan(avatar.left));
    expect(avatar.left - back.right, inInclusiveRange(0, 8));
    expect(avatar.right, lessThan(identity.left));
    expect(identity.left - avatar.right, closeTo(10, .1));
    expect(identity.right, lessThanOrEqualTo(more.left));
    expect(back.left, closeTo(AmoraHeaderTokens.pageHorizontalInset, .1));
    expect(
      more.right,
      closeTo(320 - AmoraHeaderTokens.pageHorizontalInset, .1),
    );
    expect(back.size, const Size.square(48));
    expect(more.size, const Size.square(48));
    expect(back.center.dy, closeTo(more.center.dy, .1));
    expect(back.center.dy, closeTo(avatar.center.dy, .1));
    expect(back.center.dy, closeTo(identity.center.dy, .1));

    final column = tester.widget<Column>(
      find.byKey(const ValueKey('chat-header-name-status')),
    );
    expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    final avatarWidget = tester.widget<ChatPresenceAvatar>(
      find.byKey(const ValueKey('chat-header-avatar')),
    );
    expect(avatarWidget.radius, 20);
    expect(avatarWidget.showVerified, isFalse);
    expect(
      find.bySemanticsLabel(RegExp('Chat profile picture for ${profile.name}')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.tap(find.byTooltip('More chat options'));
    await tester.tap(find.byKey(const ValueKey('chat-header-identity')));
    expect(backTaps, 1);
    expect(moreTaps, 1);
    expect(profileTaps, 1);
  });

  testWidgets('header alignment remains identical at supported widths', (
    tester,
  ) async {
    final profile = _renamedProfile(
      repository.conversations.first.user,
      'Alexandria Priyadarshini Verylongsurname',
    );
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768]) {
      await pumpHeader(
        tester,
        profile: profile,
        online: true,
        status: 'Online',
        size: Size(width, 700),
      );
      final back = tester.getRect(
        find.byKey(const ValueKey('chat-header-back')),
      );
      final avatar = tester.getRect(
        find.byKey(const ValueKey('chat-header-avatar')),
      );
      final identity = tester.getRect(
        find.byKey(const ValueKey('chat-header-name-status')),
      );
      final more = tester.getRect(
        find.byKey(const ValueKey('chat-header-more')),
      );
      expect(back.left, closeTo(AmoraHeaderTokens.pageHorizontalInset, .1));
      expect(
        more.right,
        closeTo(width - AmoraHeaderTokens.pageHorizontalInset, .1),
      );
      expect(back.center.dy, closeTo(more.center.dy, .1));
      expect(back.center.dy, closeTo(avatar.center.dy, .1));
      expect(back.center.dy, closeTo(identity.center.dy, .1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('long identity and 1.3 text scale stay compact at 320px', (
    tester,
  ) async {
    final profile = _renamedProfile(
      repository.conversations.first.user,
      'Alexandria Priyadarshini Verylongsurname',
    );
    await pumpHeader(
      tester,
      profile: profile,
      online: false,
      status: 'Last active recently',
      textScale: 1.3,
    );

    final name = tester.widget<Text>(
      find.byKey(const ValueKey('chat-header-name')),
    );
    final status = tester.widget<Text>(
      find.byKey(const ValueKey('chat-header-status')),
    );
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(name.textAlign, TextAlign.left);
    expect(status.maxLines, 1);
    expect(status.overflow, TextOverflow.ellipsis);
    expect(tester.getSize(find.byType(ChatHeader)).height, 72);
    expect(find.byTooltip('More chat options'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verified badge and online dot each render once', (tester) async {
    final profile = repository.conversations
        .map((conversation) => conversation.user)
        .firstWhere((user) => user.verified);
    await pumpHeader(tester, profile: profile, online: true, status: 'Online');

    expect(find.byKey(const ValueKey('chat-header-verified')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('chat-presence-online-indicator')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('verified', caseSensitive: false)),
      findsOneWidget,
    );
    final avatarSemantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byKey(const ValueKey('chat-header-avatar')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(avatarSemantics.properties.label, contains(profile.name));
  });

  testWidgets('typing text does not change shared header height', (
    tester,
  ) async {
    final profile = repository.conversations.first.user;
    await pumpHeader(tester, profile: profile, online: true, status: 'Online');
    final normalHeight = tester.getSize(find.byType(ChatHeader)).height;

    await pumpHeader(
      tester,
      profile: profile,
      online: true,
      status: 'Typingâ€¦',
    );
    expect(find.text('Typingâ€¦'), findsOneWidget);
    expect(tester.getSize(find.byType(ChatHeader)).height, normalHeight);
  });

  testWidgets('every conversation uses the same dynamic ChatHeader', (
    tester,
  ) async {
    final conversations = repository.conversations.take(2).toList();
    for (final conversation in conversations) {
      await pumpHeader(
        tester,
        profile: conversation.user,
        online: conversation.online,
        status: conversation.online
            ? 'Online'
            : conversation.user.status.trim().isEmpty
            ? 'Offline'
            : conversation.user.status.trim(),
      );
      expect(find.byType(ChatHeader), findsOneWidget);
      expect(find.text(conversation.user.name), findsOneWidget);
      expect(find.byKey(const ValueKey('chat-header-avatar')), findsOneWidget);
    }
  });

  testWidgets('existing overflow menu actions remain available', (
    tester,
  ) async {
    await pumpConversation(tester, repository.conversations.first.id);
    await tester.tap(find.byTooltip('More chat options'));
    await tester.pumpAndSettle();

    for (final action in const [
      'View Profile',
      'Mute Conversation',
      'Report User',
      'Block User',
      'Read Receipts',
    ]) {
      expect(find.text(action), findsOneWidget);
    }
  });

  testWidgets('text and emoji-only messages persist in selected thread', (
    tester,
  ) async {
    final conversation = repository.conversations.first;
    await pumpConversation(tester, conversation.id);

    await tester.enterText(
      find.byKey(const ValueKey('chat-message-field')),
      'A real message',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chat-send-button')));
    await tester.pumpAndSettle();

    expect(
      repository.conversation(conversation.id)!.messages.last.text,
      'A real message',
    );
    expect(
      repository.conversation(conversation.id)!.messages.last.status,
      ChatMessageStatus.sent,
    );

    await tester.enterText(
      find.byKey(const ValueKey('chat-message-field')),
      '😊✨',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chat-send-button')));
    await tester.pumpAndSettle();

    expect(repository.conversation(conversation.id)!.messages.last.text, '😊✨');
  });

  testWidgets('emoji picker inserts multiple emoji at the current cursor', (
    tester,
  ) async {
    final conversation = repository.conversations.first;
    await pumpConversation(tester, conversation.id);

    final field = find.byKey(const ValueKey('chat-message-field'));
    await tester.enterText(field, 'Hi there');
    final editable = tester.widget<TextFormField>(field);
    editable.controller!.selection = const TextSelection.collapsed(offset: 2);

    await tester.tap(find.byTooltip('Emoji'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-emoji-picker')), findsOneWidget);

    await tester.tap(find.text('😀').first);
    await tester.pump();
    await tester.tap(find.text('😀').first);
    await tester.pump();

    expect(editable.controller!.text, 'Hi😀😀 there');
    expect(editable.controller!.selection.baseOffset, 6);
  });

  testWidgets('empty message is disabled and subscription ends on exit', (
    tester,
  ) async {
    final conversation = repository.conversations.first;
    await pumpConversation(tester, conversation.id);

    final send = tester.widget<IconButton>(
      find.byKey(const ValueKey('chat-send-button')),
    );
    expect(send.onPressed, isNull);
    expect(repository.hasActiveConversationSubscriptions, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(repository.hasActiveConversationSubscriptions, isFalse);
  });

  testWidgets('composer stays overflow-free at supported viewport sizes', (
    tester,
  ) async {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
      Size(600, 360),
      Size(768, 600),
      Size(1024, 768),
    ];
    final conversationId = repository.conversations.first.id;

    for (final size in sizes) {
      await pumpConversation(tester, conversationId, size: size);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'The chat detail layout should fit before opening emoji at '
            '${size.width}×${size.height}.',
      );
      await tester.tap(find.byTooltip('Emoji'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('chat-emoji-picker')),
        findsOneWidget,
        reason: 'Emoji picker should fit at ${size.width}×${size.height}.',
      );
      if (size.height < 500) {
        expect(
          find.byKey(const ValueKey('chat-compact-emoji-tray')),
          findsOneWidget,
        );
      }
      final layoutException = tester.takeException();
      expect(
        layoutException,
        isNull,
        reason: 'No overflow is allowed at ${size.width}×${size.height}.',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  test('failed API send does not insert a fake message', () async {
    final conversation = repository.conversations.first;
    final before = conversation.messages.length;
    repository.failNextPersistenceForTesting();

    await expectLater(
      repository.sendMessage(conversation.id, 'Retry this'),
      throwsStateError,
    );
    final messages = repository.conversation(conversation.id)!.messages;
    expect(messages, hasLength(before));
  });
}

DummyProfile _renamedProfile(DummyProfile source, String name) => DummyProfile(
  id: source.id,
  gender: source.gender,
  name: name,
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
  children: source.children,
  loveLanguage: source.loveLanguage,
  greenFlags: source.greenFlags,
  redFlags: source.redFlags,
  familyValues: source.familyValues,
  dateIdeas: source.dateIdeas,
);
