import 'dart:async';

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthService.instance.currentUser = const AmoraUser(
      id: 42,
      name: 'Prompt Owner',
      email: 'prompt-owner@example.test',
      phoneNumber: '+910000000000',
      isVerified: true,
    );
  });

  tearDown(() {
    AuthService.instance.currentUser = null;
  });

  Future<_PromptHarness> pumpPrompts(
    WidgetTester tester, {
    bool failPut = false,
    Completer<void>? putGate,
  }) async {
    final remote = _PromptRemote(
      profile: _profile().toJson().cast<String, dynamic>(),
      failPut: failPut,
      putGate: putGate,
    );
    final repository = LocalProfileRepository.testing(remote: remote);
    addTearDown(repository.dispose);
    await repository.refreshFromServer();
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AmoraaProfilePromptField(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return _PromptHarness(remote, repository, controller);
  }

  testWidgets(
    'prompt actions are accessible icon-only controls in edit order',
    (tester) async {
      await pumpPrompts(tester);

      final edits = find.byKey(const ValueKey('edit-profile-prompt'));
      final deletes = find.byKey(const ValueKey('delete-profile-prompt'));
      expect(edits, findsNWidgets(2));
      expect(deletes, findsNWidgets(2));
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));
      expect(find.byTooltip('Edit prompt'), findsNWidgets(2));
      expect(find.byTooltip('Delete prompt'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Edit prompt'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Delete prompt'), findsNWidgets(2));

      final editCenter = tester.getCenter(edits.first);
      final deleteCenter = tester.getCenter(deletes.first);
      expect(editCenter.dx, lessThan(deleteCenter.dx));
      expect(editCenter.dy, closeTo(deleteCenter.dy, 1));
      expect(tester.getSize(edits.first).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(deletes.first).width, greaterThanOrEqualTo(48));

      await tester.tap(edits.first);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('profile-prompt-answer-field')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('profile-prompt-answer-field')),
            )
            .controller
            ?.text,
        'Coffee and a long walk.',
      );
    },
  );

  testWidgets('delete opens confirmation and Cancel preserves the prompt', (
    tester,
  ) async {
    final harness = await pumpPrompts(tester);

    await tester.tap(find.byKey(const ValueKey('delete-profile-prompt')).first);
    await tester.pumpAndSettle();
    expect(find.text('Delete prompt?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete this prompt?'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('confirm-action-cancel')));
    await tester.pumpAndSettle();

    expect(find.text('My ideal Sunday is...'), findsOneWidget);
    expect(harness.remote.putCalls, 0);
  });

  testWidgets(
    'confirmed delete persists one prompt, reloads, and updates preview state',
    (tester) async {
      final harness = await pumpPrompts(tester);
      final original = harness.repository.profile;

      await tester.tap(
        find.byKey(const ValueKey('delete-profile-prompt')).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-action-confirm')));
      await tester.pumpAndSettle();

      expect(harness.remote.putCalls, 1);
      expect(harness.remote.lastBody?['prompts'], const {
        'A green flag I value is...': 'Kind communication.',
      });
      expect(find.text('My ideal Sunday is...'), findsNothing);
      expect(find.text('A green flag I value is...'), findsOneWidget);
      expect(harness.repository.profile.prompts.length, 1);
      expect(harness.repository.profile.name, original.name);
      expect(harness.repository.profile.bio, original.bio);
      expect(harness.repository.profile.interests, original.interests);

      await harness.repository.refreshFromServer();
      expect(
        harness.repository.profile.prompts.containsKey('My ideal Sunday is...'),
        isFalse,
      );
      final preview = AmoraaPublicProfileData.fromProfile(
        harness.repository.profile,
        harness.repository.currentPhotos,
      );
      expect(
        preview.prompts.map((entry) => entry.key),
        isNot(contains('My ideal Sunday is...')),
      );
      expect(preview.toPublicDisplayProfile().promptAnswers, const {
        'A green flag I value is...': 'Kind communication.',
      });
    },
  );

  testWidgets(
    'failed persistence keeps the prompt and shows controlled error',
    (tester) async {
      final harness = await pumpPrompts(tester, failPut: true);

      await tester.tap(
        find.byKey(const ValueKey('delete-profile-prompt')).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-action-confirm')));
      await tester.pumpAndSettle();

      expect(harness.remote.putCalls, 1);
      expect(find.text('My ideal Sunday is...'), findsOneWidget);
      expect(
        harness.repository.profile.prompts,
        containsPair('My ideal Sunday is...', 'Coffee and a long walk.'),
      );
      expect(
        find.text('Could not delete this prompt. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('delete confirmation prevents duplicate submissions', (
    tester,
  ) async {
    final gate = Completer<void>();
    final harness = await pumpPrompts(tester, putGate: gate);

    await tester.tap(find.byKey(const ValueKey('delete-profile-prompt')).first);
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('confirm-action-confirm'));
    await tester.tap(confirm);
    await tester.pump();
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pump();

    expect(harness.remote.putCalls, 1);
    expect(
      find.byKey(const ValueKey('confirm-action-progress')),
      findsOneWidget,
    );
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('My ideal Sunday is...'), findsNothing);
  });
}

class _PromptHarness {
  const _PromptHarness(this.remote, this.repository, this.controller);

  final _PromptRemote remote;
  final LocalProfileRepository repository;
  final ProfileFormController controller;
}

class _PromptRemote implements OwnProfileRemoteDataSource {
  _PromptRemote({
    required this.profile,
    required this.failPut,
    required this.putGate,
  });

  Map<String, dynamic> profile;
  final bool failPut;
  final Completer<void>? putGate;
  int putCalls = 0;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (method == 'PUT') {
      putCalls += 1;
      lastBody = Map<String, dynamic>.from(body ?? const {});
      if (failPut) throw StateError('profile update failed');
      if (putGate != null) await putGate!.future;
      profile = <String, dynamic>{...profile, ...?body};
    }
    return <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'profile': profile},
    };
  }
}

UserProfile _profile() => const UserProfile(
  name: 'Prompt Owner',
  email: 'prompt-owner@example.test',
  phoneNumber: '+910000000000',
  birthdate: '14/02/1998',
  gender: 'Female',
  bio:
      'A profile biography that should remain unchanged after prompt deletion.',
  profession: 'Designer',
  company: 'AMORAA',
  education: 'Graduate',
  location: 'Ahmedabad',
  datingIntention: 'Long-Term Relationship',
  interests: ['Coffee', 'Travel'],
  prompts: {
    'My ideal Sunday is...': 'Coffee and a long walk.',
    'A green flag I value is...': 'Kind communication.',
  },
  lifestyle: {'Languages': 'English', 'Religion': 'Hindu'},
  photos: [],
  primaryPhotoIndex: 0,
  serverCompletionPercent: 100,
);
