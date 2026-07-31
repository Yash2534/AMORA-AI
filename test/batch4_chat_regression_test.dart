import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = LocalChatRepository.instance;

  setUp(() async {
    await repository.resetForTesting();
  });

  testWidgets('chat rows pass their unique conversation ids', (tester) async {
    final opened = <ChatDetailArgs>[];
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == ChatDetailScreen.routeName) {
            final args = settings.arguments! as ChatDetailArgs;
            opened.add(args);
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('detail')),
            );
          }
          return null;
        },
        home: const ChatListScreen(showNavigation: false),
      ),
    );
    await tester.pumpAndSettle();

    final first = repository.conversations[0];
    final second = repository.conversations[1];
    await tester.tap(find.byKey(ValueKey('conversation-${first.id}')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('detail'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('conversation-${second.id}')));
    await tester.pumpAndSettle();

    expect(opened.map((item) => item.conversationId), <String>[
      first.id,
      second.id,
    ]);
    expect(opened.first.recipientId, first.user.id);
    expect(opened.first.recipientName, first.user.name);
    expect(opened.first.recipientImage, first.user.imageUrl);
    expect(opened.first.recipientStatus, isNotEmpty);
  });

  test(
    'sending updates only the selected conversation and its preview',
    () async {
      final first = repository.conversations[0];
      final second = repository.conversations[1];
      const message = 'This belongs to the first conversation';

      await repository.sendMessage(first.id, message);

      expect(repository.conversation(first.id)!.lastMessage, message);
      expect(repository.conversation(first.id)!.messages.last.text, message);
      expect(
        repository.conversation(second.id)!.lastMessage,
        second.lastMessage,
      );
    },
  );

  test('opening a conversation clears its unread state', () async {
    final unread = repository.conversations.firstWhere(
      (conversation) => conversation.unread > 0,
    );

    await repository.markRead(unread.id);

    expect(repository.conversation(unread.id)!.unread, 0);
  });

  test('incoming events stay isolated and update unread preview', () async {
    final first = repository.conversations.first;
    final second = repository.conversations[1];
    final updates = <ChatConversation>[];
    final subscription = repository
        .watchConversation(first.id)
        .listen(updates.add);
    addTearDown(subscription.cancel);

    repository.receiveMessage(
      second.id,
      ChatMessage(
        id: 'server-second',
        text: 'Second only',
        mine: false,
        time: '12:00',
        createdAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        status: ChatMessageStatus.delivered,
      ),
    );
    repository.receiveMessage(
      first.id,
      ChatMessage(
        id: 'server-first',
        text: 'First only',
        mine: false,
        time: '12:01',
        createdAtEpochMs: DateTime.now().millisecondsSinceEpoch + 1,
        status: ChatMessageStatus.delivered,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      updates.every((conversation) => conversation.id == first.id),
      isTrue,
    );
    expect(repository.conversation(first.id)!.lastMessage, 'First only');
    expect(repository.conversation(second.id)!.lastMessage, 'Second only');
  });
}
