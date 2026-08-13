import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AvailabilityRemote implements ChatRemoteDataSource {
  String? reason = 'you_blocked_profile';

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async => {
    'success': true,
    'data': {
      'conversations': [
        {
          'id': '41',
          'participant': {
            'id': '2',
            'name': 'Current Participant',
            'age': 28,
            'imageUrl': '',
            'gallery': <String>[],
          },
          'lastMessage': null,
          'unreadCount': 0,
          'muted': false,
          'canMessage': reason == null,
          'availabilityReason': reason,
        },
      ],
      'pagination': {'hasMore': false},
    },
  };

  @override
  Future<Map<String, dynamic>> upload(String path, AmoraPickedMedia media) =>
      throw UnimplementedError();
}

void main() {
  final repository = ChatRepository.instance;

  tearDown(() async => repository.resetForTesting());

  test(
    'unavailable reason maps from the API and clears after refresh',
    () async {
      final remote = _AvailabilityRemote();
      await repository.resetForTesting(remote: remote);
      await repository.refreshConversations();

      final blocked = repository.conversation('41')!;
      expect(blocked.canMessage, isFalse);
      expect(blocked.availabilityReasonCode, 'you_blocked_profile');
      expect(
        blocked.unavailableReason,
        'You blocked this profile. Messaging is disabled.',
      );

      remote.reason = null;
      await repository.refreshAvailability();
      final restored = repository.conversation('41')!;
      expect(restored.canMessage, isTrue);
      expect(restored.availabilityReasonCode, isNull);
      expect(restored.unavailableReason, isNull);
    },
  );

  Future<RouteSettings> openChatAction(
    WidgetTester tester,
    String action,
  ) async {
    await repository.resetForTesting();
    final conversation = repository.conversations.first;
    RouteSettings? opened;
    await tester.pumpWidget(
      MaterialApp(
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(
              name: ChatDetailScreen.routeName,
              arguments: ChatDetailArgs(conversationId: conversation.id),
            ),
            builder: (_) => const ChatDetailScreen(),
          ),
        ],
        onGenerateRoute: (settings) {
          opened = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Text('Destination')),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More chat options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
    return opened!;
  }

  testWidgets('chat View Profile passes the current participant', (
    tester,
  ) async {
    final expected = repository.conversations.first.user;
    final route = await openChatAction(tester, 'View Profile');

    expect(route.name, ProfileDetailScreen.routeName);
    expect(route.arguments, same(expected));
  });

  testWidgets(
    'chat Report User binds the current participant and conversation',
    (tester) async {
      final conversation = repository.conversations.first;
      final route = await openChatAction(tester, 'Report User');
      final arguments = route.arguments! as ReportFlowArgs;

      expect(route.name, ReportFlowScreen.routeName);
      expect(arguments.targetType, 'profile');
      expect(arguments.targetId, conversation.user.id);
      expect(arguments.conversationId, conversation.id);
    },
  );
}
