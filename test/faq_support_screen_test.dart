import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/support/data/support_faq_data.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FAQ support exposes email as the only direct support method', (
    tester,
  ) async {
    Uri? composedUri;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: FaqSupportScreen(
          launchEmail: (uri) async {
            composedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FAQ & Support'), findsOneWidget);
    for (final removed in const [
      'WhatsApp Support',
      'Call Support',
      'Call Request',
      'Create Ticket',
      'Submit Ticket',
      'Ticket Status',
      'My Tickets',
    ]) {
      expect(find.textContaining(removed), findsNothing);
    }

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('email-support-button')),
      360,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('email-support-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text(SupportContact.email), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('email-support-button')));
    await tester.pumpAndSettle();

    expect(composedUri?.scheme, 'mailto');
    expect(composedUri?.path, SupportContact.email);
    expect(composedUri?.queryParameters['subject'], SupportContact.subject);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FAQ search matches question, answer, and category text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: FaqSupportScreen(launchEmail: (_) async => true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('faq-search-field')),
      'waitlist',
    );
    await tester.pumpAndSettle();
    expect(find.text('How do I join an AMORAA event?'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('faq-search-field')),
      'not-a-real-help-topic',
    );
    await tester.pumpAndSettle();
    expect(find.text('No help topics found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FAQ accordion expands accessibly without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: FaqSupportScreen(launchEmail: (_) async => true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('faq-search-field')),
      'compatibility',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('How does AMORAA compatibility work?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Compatibility combines profile intent'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('FAQ support remains responsive on desktop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: FaqSupportScreen(launchEmail: (_) async => true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Popular questions'), findsOneWidget);
    expect(find.text('Browse by topic'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
