import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = ChatRepository.instance;
  setUp(repository.resetForTesting);
  Future<void> pumpChats(
    WidgetTester tester, {
    Size size = const Size(430, 900),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
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
    expect(find.byType(AmoraaCompactSelect<ChatInboxFilter>), findsNothing);
    expect(
      tester
          .widget<ListView>(find.byKey(const ValueKey('chats-filter-scroll')))
          .scrollDirection,
      Axis.horizontal,
    );
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
    final chat = repository.conversations.last;
    final search = find.byKey(const ValueKey('chats-search-field'));

    await tester.enterText(search, chat.user.name);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('conversation-${chat.id}')), findsOneWidget);
    expect(
      find.byType(ConversationTile),
      findsOneWidget,
      reason: 'Search results must use the production conversation row.',
    );

    await tester.enterText(search, 'not-a-real-chat-keyword');
    await tester.pumpAndSettle();
    expect(find.text('No chats found'), findsOneWidget);
    expect(find.text('Try another name or keyword.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('chats-search-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chats-search-clear')), findsNothing);
    expect(find.text('Search chats...'), findsOneWidget);
    expect(find.text('No chats found'), findsNothing);
    expect(find.byType(ConversationTile), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search hint and icons keep production alignment', (
    tester,
  ) async {
    await pumpChats(tester, size: const Size(320, 760));

    final container = find.byKey(const ValueKey('chats-search-container'));
    final field = find.byKey(const ValueKey('chats-search-field'));
    final icon = find.byKey(const ValueKey('chats-search-icon'));
    final hint = find.text('Search chats...');
    final containerRect = tester.getRect(container);
    final iconRect = tester.getRect(icon);
    final hintRect = tester.getRect(hint);
    final textField = tester.widget<TextField>(field);

    expect(textField.decoration?.hintText, 'Search chats...');
    expect(textField.decoration?.prefixIconConstraints?.maxWidth, 48);
    expect(textField.decoration?.suffixIconConstraints?.maxWidth, 48);
    expect(iconRect.center.dy, closeTo(containerRect.center.dy, .1));
    expect(hintRect.left, greaterThan(iconRect.right));
    expect(hintRect.center.dy, closeTo(containerRect.center.dy, 1));
    expect(find.byKey(const ValueKey('chats-search-clear')), findsNothing);

    await tester.enterText(field, 'A');
    await tester.pumpAndSettle();

    final clear = find.byKey(const ValueKey('chats-search-clear'));
    final clearRect = tester.getRect(clear);
    expect(clear, findsOneWidget);
    expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
    expect(clearRect.width, 48);
    expect(clearRect.height, greaterThanOrEqualTo(48));
    expect(clearRect.right, closeTo(containerRect.right, 1));
    expect(clearRect.center.dy, closeTo(containerRect.center.dy, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('search rendering remains crisp without scaled clear control', (
    tester,
  ) async {
    await pumpChats(tester, size: const Size(320, 760));

    final container = find.byKey(const ValueKey('chats-search-container'));
    final searchSurface = tester.widget<AnimatedContainer>(container);
    expect(searchSurface.curve, Curves.easeOutCubic);
    expect(
      find.descendant(of: container, matching: find.byType(ScaleTransition)),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('chats-search-field')),
      'A',
    );
    await tester.pump();
    final clearSwitcher = tester.widget<AnimatedSwitcher>(
      find.descendant(of: container, matching: find.byType(AnimatedSwitcher)),
    );
    expect(clearSwitcher.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets('conversation rows keep avatar, profile, and time aligned', (
    tester,
  ) async {
    await pumpChats(tester, size: const Size(320, 760));
    final chat = repository.conversations.firstWhere(
      (chat) => chat.user.verified,
    );
    final tile = find.byKey(ValueKey('conversation-${chat.id}'));
    await tester.ensureVisible(tile);

    final tileRect = tester.getRect(tile);
    final avatarRect = tester.getRect(
      find.byKey(ValueKey('conversation-avatar-${chat.id}')),
    );
    final nameRect = tester.getRect(
      find.byKey(ValueKey('conversation-name-${chat.id}')),
    );
    final timeRect = tester.getRect(
      find.byKey(ValueKey('conversation-time-${chat.id}')),
    );
    final verifiedRect = tester.getRect(
      find.byKey(ValueKey('conversation-verified-badge-${chat.id}')),
    );

    expect(avatarRect.size, const Size.square(48));
    expect(avatarRect.left, closeTo(tileRect.left + 20, 1));
    expect(timeRect.right, closeTo(tileRect.right - 20, 1));
    expect(verifiedRect.center.dy, closeTo(nameRect.center.dy, 2));
    expect(nameRect.right, lessThanOrEqualTo(timeRect.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('conversation rows stay usable at 1.3 text scale', (
    tester,
  ) async {
    await pumpChats(tester, size: const Size(320, 760), textScale: 1.3);
    final chat = repository.conversations.first;
    final tile = find.byKey(ValueKey('conversation-${chat.id}'));
    await tester.ensureVisible(tile);
    expect(tester.getSize(tile).height, greaterThanOrEqualTo(76));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unread filter uses existing unread counts', (tester) async {
    await pumpChats(tester);
    final readChat = repository.conversations.firstWhere(
      (chat) => chat.unread == 0,
    );
    final unreadChat = repository.conversations.firstWhere(
      (chat) => chat.unread > 0,
    );

    await tester.tap(find.byKey(const ValueKey('chats-filter-Unread')));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('conversation-${readChat.id}')), findsNothing);
    expect(
      find.byKey(ValueKey('conversation-${unreadChat.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat filters remain one-line and single-select', (tester) async {
    await pumpChats(tester);

    final optionFinders = [
      for (final label in const ['All', 'Unread', 'Online'])
        find.byKey(ValueKey('chats-filter-$label')),
    ];
    final centerLines = optionFinders
        .map((finder) => tester.getCenter(finder).dy)
        .toList();
    expect(centerLines.toSet(), hasLength(1));
    expect(
      tester.widget<AmoraFilterChip>(optionFinders.first).selected,
      isTrue,
    );

    await tester.tap(optionFinders[1]);
    await tester.pumpAndSettle();
    await tester.tap(optionFinders[2]);
    await tester.pumpAndSettle();

    expect(tester.widget<AmoraFilterChip>(optionFinders[0]).selected, isFalse);
    expect(tester.widget<AmoraFilterChip>(optionFinders[1]).selected, isFalse);
    expect(tester.widget<AmoraFilterChip>(optionFinders[2]).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat filter rail stays horizontal at supported widths', (
    tester,
  ) async {
    for (final width in const [
      320.0,
      360.0,
      390.0,
      412.0,
      430.0,
      600.0,
      768.0,
      1024.0,
    ]) {
      await pumpChats(tester, size: Size(width, 900));
      final rail = find.byKey(const ValueKey('chats-filter-scroll'));
      expect(tester.widget<ListView>(rail).scrollDirection, Axis.horizontal);
      final search = find.byKey(const ValueKey('chats-search-field'));
      final searchContainer = tester.getRect(
        find.byKey(const ValueKey('chats-search-container')),
      );
      expect(find.text('Search chats...'), findsOneWidget);
      await tester.enterText(search, 'A');
      await tester.pumpAndSettle();
      final clearRect = tester.getRect(
        find.byKey(const ValueKey('chats-search-clear')),
      );
      expect(clearRect.right, closeTo(searchContainer.right, 1));
      expect(clearRect.center.dy, closeTo(searchContainer.center.dy, .1));
      await tester.tap(find.byKey(const ValueKey('chats-search-clear')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('chats-filter-Online')),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Chat filter overflowed at ${width.toInt()} px',
      );
    }
  });

  testWidgets('conversation tap preserves the existing chat-detail route', (
    tester,
  ) async {
    await pumpChats(tester);
    final firstChat = repository.conversations.first;
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

    final firstChat = repository.conversations.first;
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
    expect(appBarRect.width, lessThanOrEqualTo(680));
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
