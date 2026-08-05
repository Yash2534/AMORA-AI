import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/referral/presentation/referral_leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('referral leaderboard supports compact 1.3 text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(
          theme: AmoraTheme.light(),
          home: const ReferralLeaderboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Referral Leaderboard'), findsOneWidget);
  });
}
