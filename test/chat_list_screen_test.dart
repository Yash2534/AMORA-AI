import 'package:amora_ai/core/data/amora_dummy_data.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpChats(
    WidgetTester tester, {
    Size size = const Size(430, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/chat-detail': (_) => const _RouteMarker('chat-detail'),
          '/profile-detail': (_) => const _RouteMarker('profile-detail'),
          '/browse': (_) => const _RouteMarker('browse'),
        },
        home: const ChatListScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a compact real-data inbox at 320px', (tester) async {
    await pumpChats(tester, size: const Size(320, 760));

    expect(find.byType(ChatsAppBar), findsOneWidget);
    expect(find.byKey(const ValueKey('chats-search-field')), findsOneWidget);
    expect(find.text('Search chats...'), findsOneWidget);
    expect(find.byTooltip('Search chats'), findsNothing);
    expect(find.byTooltip('Compose message'), findsOneWidget);
    expect(find.byTooltip('More'), findsNothing);
    expect(find.text('Active now'), findsOneWidget);
    expect(find.byKey(const ValueKey('chats-filter-bar')), findsOneWidget);
    expect(find.text('Conversations'), findsOneWidget);
    expect(find.byType(ConversationTile), findsWidgets);
    expect(find.textContaining('Date invite'), findsNothing);
    expect(find.text('Draft'), findsNothing);
    expect(find.text('Pinned'), findsNothing);
    expect(find.text('Archived'), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => widget is FloatingBottomNav),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('searches existing names and message content and clears', (
    tester,
  ) async {
    await pumpChats(tester);
    final chat = AmoraDummyData.chats[4];
    final search = find.byKey(const ValueKey('chats-search-field'));

    await tester.enterText(search, chat.user.name);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('conversation-${chat.id}')), findsOneWidget);

    await tester.enterText(search, 'not-a-real-chat-keyword');
    await tester.pumpAndSettle();
    expect(find.text('No chats found'), findsOneWidget);
    expect(find.text('Try another name or keyword.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chats-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('No chats found'), findsNothing);
    expect(find.byType(ConversationTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unread filter uses existing unread counts', (tester) async {
    await pumpChats(tester);
    final readChat = AmoraDummyData.chats.firstWhere(
      (chat) => chat.unread == 0,
    );
    final unreadChat = AmoraDummyData.chats.firstWhere(
      (chat) => chat.unread > 0,
    );

    await tester.tap(find.byKey(const ValueKey('chat-filter-unread')));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('conversation-${readChat.id}')), findsNothing);
    expect(
      find.byKey(ValueKey('conversation-${unreadChat.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('conversation tap preserves the existing chat-detail route', (
    tester,
  ) async {
    await pumpChats(tester);
    final firstChat = AmoraDummyData.chats.first;
    final tile = find.byKey(ValueKey('conversation-${firstChat.id}'));

    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('chat-detail'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compose and long press expose supported conversation actions', (
    tester,
  ) async {
    await pumpChats(tester);

    await tester.tap(find.byTooltip('Compose message'));
    await tester.pumpAndSettle();
    expect(find.text('New message'), findsOneWidget);
    expect(
      find.text('Continue a conversation with one of your matches.'),
      findsOneWidget,
    );

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    final firstChat = AmoraDummyData.chats.first;
    await tester.longPress(
      find.byKey(ValueKey('conversation-${firstChat.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open conversation'), findsOneWidget);
    expect(find.text('View profile'), findsOneWidget);
    expect(find.text('Archive'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('desktop inbox remains centred and constrained', (tester) async {
    await pumpChats(tester, size: const Size(1200, 900));

    final appBarRect = tester.getRect(find.byType(ChatsAppBar));
    expect(appBarRect.width, lessThanOrEqualTo(648));
    expect(appBarRect.center.dx, closeTo(600, 1));
    expect(find.byType(ConversationTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
