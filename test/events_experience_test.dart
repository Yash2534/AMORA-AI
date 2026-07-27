import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/events_browse_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('free users receive a dedicated member locked state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const EventsBrowseScreen(showNavigation: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Events are for Amora members'), findsOneWidget);
    expect(find.text('Explore Membership'), findsOneWidget);
    expect(find.textContaining('ticket', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member feed renders discovery and supported RSVP states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          backgroundColor: Color(0xFFFDF1F7),
          body: SafeArea(child: EventsMemberExperience()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    expect(find.text('Featured for you'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Upcoming events'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Upcoming events'), findsOneWidget);
    expect(find.text('Joined'), findsWidgets);
    expect(find.textContaining('ticket', findRichText: true), findsNothing);
    expect(find.textContaining('Rs ', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct event detail respects membership access', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: EventDetailScreen(event: events.first),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Events are for Amora members'), findsOneWidget);
    expect(find.textContaining('ticket', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member feed uses a two-column grid on desktop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          backgroundColor: Color(0xFFFDF1F7),
          body: SafeArea(child: EventsMemberExperience()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Upcoming events'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Upcoming events'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
