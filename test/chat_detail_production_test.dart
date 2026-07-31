import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
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
          builder: (_) => const ChatDetailScreen(),
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

    expect(find.text(conversation.user.name.split(' ').first), findsOneWidget);
    expect(find.text(conversation.messages.first.text), findsOneWidget);
    expect(find.text(repository.conversations.first.user.name), findsNothing);
    expect(repository.hasActiveConversationSubscriptions, isTrue);
  });

  testWidgets('text and emoji-only messages are queued in selected thread', (
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
      ChatMessageStatus.queued,
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

  test('failed local persistence can be retried without duplication', () async {
    final conversation = repository.conversations.first;
    repository.failNextPersistenceForTesting();

    await expectLater(
      repository.sendMessage(conversation.id, 'Retry this'),
      throwsStateError,
    );
    final failed = repository.conversation(conversation.id)!.messages.last;
    expect(failed.status, ChatMessageStatus.failed);

    await repository.retryMessage(conversation.id, failed.id);
    final messages = repository.conversation(conversation.id)!.messages;
    expect(messages.where((message) => message.id == failed.id), hasLength(1));
    expect(messages.last.status, ChatMessageStatus.queued);
  });
}
