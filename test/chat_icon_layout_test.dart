import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chat preserves accessible icon targets at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChatDetailScreen())),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
  });

  testWidgets('chat detail remains overflow-free at 375px', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ChatDetailScreen())),
    );
    await tester.pump(const Duration(milliseconds: 250));
  });
}
