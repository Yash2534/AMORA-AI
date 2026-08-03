import 'dart:io';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared resolver returns the exact four identity states', () {
    expect(
      resolveAmoraaIdentityBadge(isAadhaarVerified: false, isPremium: false),
      AmoraaIdentityBadgeType.none,
    );
    expect(
      resolveAmoraaIdentityBadge(isAadhaarVerified: true, isPremium: false),
      AmoraaIdentityBadgeType.verified,
    );
    expect(
      resolveAmoraaIdentityBadge(isAadhaarVerified: false, isPremium: true),
      AmoraaIdentityBadgeType.premium,
    );
    expect(
      resolveAmoraaIdentityBadge(isAadhaarVerified: true, isPremium: true),
      AmoraaIdentityBadgeType.premiumVerified,
    );
  });

  testWidgets('unverified non-premium user renders no public badge', (
    tester,
  ) async {
    await _pumpBadge(tester, isAadhaarVerified: false, isPremium: false);

    expect(find.text('Verified'), findsNothing);
    expect(find.text('Premium'), findsNothing);
    expect(
      find.byKey(const ValueKey('amoraa-identity-badge-none')),
      findsNothing,
    );
  });

  testWidgets('Aadhaar-verified user receives one pink Verified badge', (
    tester,
  ) async {
    await _pumpBadge(tester, isAadhaarVerified: true, isPremium: false);

    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Premium'), findsNothing);
    expect(_badgeColor(tester, 'verified'), AppColors.secondary);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('amoraa-identity-badge-verified')),
          )
          .getSemanticsData()
          .label,
      contains('Verified profile'),
    );
  });

  testWidgets('Premium-only user receives one purple Premium badge', (
    tester,
  ) async {
    await _pumpBadge(tester, isAadhaarVerified: false, isPremium: true);

    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Verified'), findsNothing);
    expect(_badgeColor(tester, 'premium'), AppColors.primary);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('amoraa-identity-badge-premium')),
          )
          .getSemanticsData()
          .label,
      contains('Premium member'),
    );
  });

  testWidgets('Premium verified user receives only purple Verified', (
    tester,
  ) async {
    await _pumpBadge(tester, isAadhaarVerified: true, isPremium: true);

    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Premium'), findsNothing);
    expect(_badgeColor(tester, 'premiumVerified'), AppColors.primary);
    expect(
      find.byKey(const ValueKey('amoraa-identity-badge-premiumVerified')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('amoraa-identity-badge-verified')),
      findsNothing,
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('amoraa-identity-badge-premiumVerified')),
          )
          .getSemanticsData()
          .label,
      contains('Premium verified profile'),
    );
  });

  testWidgets('badge remains compact beside a long profile name at 320 px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(
                child: Text(
                  'A very long public profile name that must truncate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              AmoraaIdentityBadge(isAadhaarVerified: true, isPremium: true),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('amoraa-identity-badge-premiumVerified')),
          )
          .height,
      28,
    );
  });

  test('badge source contains no private Aadhaar or transaction data', () {
    final source = File(
      'lib/core/widgets/amoraa_identity_badge.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('aadhaarNumber')));
    expect(source, isNot(contains('documentId')));
    expect(source, isNot(contains('transactionId')));
    expect(source, isNot(contains('verificationReference')));
  });
}

Future<void> _pumpBadge(
  WidgetTester tester, {
  required bool isAadhaarVerified,
  required bool isPremium,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AmoraTheme.light(),
      home: Scaffold(
        body: Center(
          child: AmoraaIdentityBadge(
            isAadhaarVerified: isAadhaarVerified,
            isPremium: isPremium,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _badgeColor(WidgetTester tester, String type) {
  final container = tester.widget<Container>(
    find.byKey(ValueKey('amoraa-identity-badge-$type')),
  );
  return (container.decoration as BoxDecoration).color;
}
