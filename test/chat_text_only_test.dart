import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chat exposes only text messaging controls and sends text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChatDetailScreen())),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byTooltip('Emoji'), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);
    expect(find.byTooltip('Voice call'), findsNothing);
    expect(find.byTooltip('Video call'), findsNothing);
    expect(find.byTooltip('Attachments'), findsNothing);
    expect(find.text('Shared Media'), findsNothing);
    expect(find.textContaining('Date invite'), findsNothing);
    expect(find.text('Draft'), findsNothing);
    expect(find.text('AI Icebreaker'), findsNothing);
    expect(find.byType(ChatDateDivider), findsOneWidget);
    expect(find.byType(MessageBubble), findsWidgets);
    expect(find.byType(TypingIndicator), findsOneWidget);

    const message = 'Text chat still works';
    await tester.enterText(find.byType(TextFormField), message);
    await tester.tap(find.byTooltip('Send'));
    await tester.pump(const Duration(milliseconds: 300));

    final composer = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(composer.controller?.text, isEmpty);

    tester.testTextInput.hide();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byTooltip('More'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Voice Call'), findsNothing);
    expect(find.text('Video Call'), findsNothing);
    expect(find.text('Shared Media'), findsNothing);
    expect(find.text('View Profile'), findsOneWidget);
    expect(find.text('Read Receipts'), findsOneWidget);
  });
}
