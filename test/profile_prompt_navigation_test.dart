import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repository = LocalProfileRepository.instance;
  late UserProfile original;

  setUp(() {
    original = repository.profile;
  });

  tearDown(() async {
    await repository.resetForTesting(original);
  });

  UserProfile completeProfile() => original.copyWith(
    name: 'Complete Member',
    birthdate: '14/02/1998',
    gender: 'Man',
    profession: 'Designer',
    education: 'Undergraduate',
    location: 'Ahmedabad',
    datingIntention: 'Long-Term Relationship',
    bio:
        'A thoughtful profile introduction with enough detail for a genuine conversation.',
    interests: const ['Coffee', 'Cooking', 'Road trips', 'Yoga', 'Design'],
    lifestyle: const {
      'Height': '5\'5" · 165 cm',
      'Languages': 'English & Gujarati',
      'Religion': 'Hindu',
      'Exercise': 'Daily',
    },
    prompts: const {
      'My ideal Sunday is...': 'Coffee, a long walk, and a quiet evening.',
    },
  );

  test('pending fields are dynamic and one valid prompt is sufficient', () {
    final complete = completeProfile();
    expect(
      complete.pendingFields.map((field) => field.id),
      isNot(contains(ProfileFormFieldId.profilePrompt)),
    );
    expect(
      complete.completionResult.sections
          .firstWhere(
            (section) => section.id == ProfileCompletionSectionId.prompt,
          )
          .isComplete,
      isTrue,
    );

    final missing = complete.copyWith(
      lifestyle: const {'Exercise': 'Daily'},
      prompts: const {},
    );
    expect(
      missing.pendingFields.map((field) => field.id),
      containsAllInOrder(const [
        ProfileFormFieldId.height,
        ProfileFormFieldId.languages,
        ProfileFormFieldId.religion,
        ProfileFormFieldId.profilePrompt,
      ]),
    );
  });

  test(
    'saving one prompt preserves other unsaved Edit Profile values',
    () async {
      final profile = completeProfile();
      await repository.resetForTesting(profile);
      final controller = ProfileFormController(repository: repository);
      addTearDown(controller.dispose);

      controller.name.text = 'Unsaved edited name';
      controller.beginEditPrompt('My ideal Sunday is...');
      controller.promptAnswer.text = '  A slow breakfast and a long walk.  ';
      await controller.savePrompt();

      expect(repository.profile.name, profile.name);
      expect(controller.name.text, 'Unsaved edited name');
      expect(controller.draftProfile.name, 'Unsaved edited name');
      expect(controller.dirty, isTrue);
      expect(
        repository.profile.prompts['My ideal Sunday is...'],
        'A slow breakfast and a long walk.',
      );
    },
  );

  testWidgets(
    'saved prompts stack vertically and Add Prompt saves immediately',
    (tester) async {
      final profile = completeProfile().copyWith(
        prompts: const {
          'My ideal Sunday is...': 'Coffee and a long walk.',
          'A green flag I value is...': 'Kind, direct communication.',
        },
      );
      await repository.resetForTesting(profile);
      final controller = ProfileFormController(repository: repository);
      addTearDown(controller.dispose);
      final formKey = GlobalKey<FormState>();

      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: AmoraaProfilePromptField(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final first = find.byKey(const ValueKey('saved-profile-prompt-0'));
      final second = find.byKey(const ValueKey('saved-profile-prompt-1'));
      expect(find.byType(AmoraaProfilePromptsSection), findsOneWidget);
      expect(find.byType(AmoraaEditableProfilePromptCard), findsNWidgets(2));
      expect(find.text('Profile prompts'), findsOneWidget);
      expect(
        find.text('Thoughtful openings for a real conversation.'),
        findsOneWidget,
      );
      expect(find.text('“Coffee and a long walk.”'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Edit'), findsNWidgets(2));
      expect(find.text('Like'), findsNothing);
      expect(find.text('Reply'), findsNothing);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byType(DropdownMenu<String>), findsNothing);
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(
        tester.getTopLeft(second).dy,
        greaterThan(tester.getBottomLeft(first).dy),
      );
      expect(tester.getSize(first).width, tester.getSize(second).width);
      expect(
        tester.getSize(first).width,
        tester.getSize(find.byType(AmoraaProfilePromptField)).width,
      );
      expect(tester.getSize(first).height, lessThan(240));

      await tester.tap(find.byKey(const ValueKey('add-profile-prompt')));
      await tester.pumpAndSettle();
      expect(find.text('Choose a prompt'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('prompt-option-Together we could...')),
      );
      await tester.pumpAndSettle();

      final answer = find.byKey(const ValueKey('profile-prompt-answer-field'));
      final savePrompt = find.byKey(const ValueKey('save-profile-prompt-edit'));
      expect(answer, findsOneWidget);
      await tester.enterText(answer, '   ');
      expect(formKey.currentState?.validate(), isFalse);
      await tester.ensureVisible(savePrompt);
      await tester.pumpAndSettle();
      await tester.tap(savePrompt);
      await tester.pump();
      expect(find.text('Write an answer for this prompt'), findsOneWidget);
      expect(
        repository.profile.prompts.containsKey('Together we could...'),
        isFalse,
      );
      expect(answer, findsOneWidget);

      await tester.enterText(
        answer,
        '  Explore local cafes and plan a weekend road trip.  ',
      );
      expect(formKey.currentState?.validate(), isTrue);
      await tester.ensureVisible(savePrompt);
      await tester.pumpAndSettle();
      await tester.tap(savePrompt);
      await tester.pumpAndSettle();

      expect(
        repository.profile.prompts['Together we could...'],
        'Explore local cafes and plan a weekend road trip.',
      );
      expect(
        find.byKey(const ValueKey('saved-profile-prompt-2')),
        findsOneWidget,
      );
      expect(
        repository.profile.completionResult.recommendedNext?.id,
        isNot(ProfileCompletionSectionId.prompt),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('prompt cards respect dynamic count and adapt to long content', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const shortPrompt = MapEntry('My ideal Sunday is...', '“Already quoted”');
    const longPrompt = MapEntry(
      'A thoughtful opening that naturally wraps across the available card width',
      'A detailed answer that keeps wrapping naturally across several lines without clipping, overlapping the Edit action, or creating a large fixed blank area.',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(1.3),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AmoraaProfilePromptsSection(
                prompts: const [shortPrompt, longPrompt],
                onEditPrompt: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cards = find.byType(AmoraaEditableProfilePromptCard);
    expect(cards, findsNWidgets(2));
    expect(find.text('“Already quoted”'), findsOneWidget);
    expect(find.text('““Already quoted””'), findsNothing);
    expect(
      tester.getSize(cards.at(1)).height,
      greaterThan(tester.getSize(cards.at(0)).height),
    );
    expect(
      tester.getTopLeft(cards.at(1)).dy,
      greaterThan(tester.getBottomLeft(cards.at(0)).dy),
    );
    expect(find.widgetWithText(TextButton, 'Edit'), findsNWidgets(2));
    final firstTitle = tester.widget<Text>(find.text(shortPrompt.key));
    final secondTitle = tester.widget<Text>(find.text(longPrompt.key));
    final firstAnswer = tester.widget<Text>(find.text('“Already quoted”'));
    expect(firstTitle.style, secondTitle.style);
    expect(firstTitle.style?.fontWeight, FontWeight.w600);
    expect(firstAnswer.style?.fontWeight, FontWeight.w600);
    expect(
      firstAnswer.style?.fontSize,
      greaterThan(firstTitle.style?.fontSize ?? double.infinity),
    );
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Share'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline prompt edit cancels safely and only one card edits', (
    tester,
  ) async {
    await repository.resetForTesting(
      completeProfile().copyWith(
        prompts: const {
          'My ideal Sunday is...': 'Coffee and a long walk.',
          'A green flag I value is...': 'Kind, direct communication.',
        },
      ),
    );
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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

    final editActions = find.byKey(const ValueKey('edit-profile-prompt'));
    await tester.tap(editActions.first);
    await tester.pumpAndSettle();
    final answerField = find.byKey(
      const ValueKey('profile-prompt-answer-field'),
    );
    expect(answerField, findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('cancel-profile-prompt-edit')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('save-profile-prompt-edit')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.widget<TextFormField>(answerField).controller?.text,
      'Coffee and a long walk.',
    );

    await tester.enterText(answerField, 'Unsaved first answer');
    await tester.tap(find.byKey(const ValueKey('edit-profile-prompt')).last);
    await tester.pumpAndSettle();
    expect(answerField, findsOneWidget);
    expect(
      tester.widget<TextFormField>(answerField).controller?.text,
      'Kind, direct communication.',
    );

    await tester.enterText(answerField, 'Unsaved second answer');
    await tester.tap(find.byKey(const ValueKey('cancel-profile-prompt-edit')));
    await tester.pumpAndSettle();
    expect(answerField, findsNothing);
    expect(find.text('“Kind, direct communication.”'), findsOneWidget);
    expect(
      repository.profile.prompts['A green flag I value is...'],
      'Kind, direct communication.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('save failure keeps inline prompt text and allows Retry', (
    tester,
  ) async {
    final answerController = TextEditingController(text: 'Original answer');
    addTearDown(answerController.dispose);
    var shouldFail = true;
    var attempts = 0;
    var savedAnswer = 'Original answer';
    var editing = true;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setHostState) => Padding(
              padding: const EdgeInsets.all(16),
              child: AmoraaEditableProfilePromptCard(
                promptTitle: 'My ideal Sunday is...',
                answer: savedAnswer,
                editing: editing,
                answerController: answerController,
                onEdit: () {},
                onCancel: () {},
                onSave: () async {
                  attempts++;
                  if (shouldFail) throw StateError('save failed');
                  setHostState(() {
                    savedAnswer = answerController.text.trim();
                    editing = false;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-prompt-answer-field')),
      'Keep this typed answer',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile-prompt-edit')));
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(answerController.text, 'Keep this typed answer');
    expect(
      find.text('Could not save this prompt. Please retry.'),
      findsOneWidget,
    );

    shouldFail = false;
    await tester.tap(find.byKey(const ValueKey('save-profile-prompt-edit')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('“Keep this typed answer”'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-prompt-save-error')),
      findsNothing,
    );
  });

  testWidgets('prompt cards stay full width at every supported viewport', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const prompts = <MapEntry<String, String>>[
      MapEntry('My ideal Sunday is...', 'Coffee and a long walk.'),
      MapEntry(
        'A green flag I value is...',
        'Kind communication and a thoughtful answer that wraps naturally.',
      ),
      MapEntry('Together we could...', 'Explore somewhere new.'),
    ];
    for (final width in const <double>[
      320,
      360,
      390,
      412,
      430,
      600,
      768,
      1024,
    ]) {
      await tester.binding.setSurfaceSize(Size(width, 1200));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: const TextScaler.linear(1.3),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AmoraaProfilePromptsSection(
                  prompts: prompts,
                  onEditPrompt: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = find.byType(AmoraaEditableProfilePromptCard);
      expect(cards, findsNWidgets(3), reason: '$width px');
      final expectedWidth = width - 32;
      for (var index = 0; index < 3; index++) {
        expect(
          tester.getSize(cards.at(index)).width,
          expectedWidth,
          reason: '$width px card $index',
        );
      }
      expect(find.widgetWithText(TextButton, 'Edit'), findsNWidgets(3));
      expect(tester.takeException(), isNull, reason: '$width px');
    }
  });

  testWidgets(
    'Completion expands and scrolls to every requested pending field',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final target in const [
        ProfileFormFieldId.height,
        ProfileFormFieldId.languages,
        ProfileFormFieldId.religion,
        ProfileFormFieldId.profilePrompt,
      ]) {
        final lifestyle = Map<String, String>.of(completeProfile().lifestyle);
        switch (target) {
          case ProfileFormFieldId.height:
            lifestyle.remove('Height');
            break;
          case ProfileFormFieldId.languages:
            lifestyle.remove('Languages');
            break;
          case ProfileFormFieldId.religion:
            lifestyle.remove('Religion');
            break;
          case ProfileFormFieldId.profilePrompt:
          default:
            break;
        }
        final profile = completeProfile().copyWith(
          name: '',
          lifestyle: lifestyle,
          prompts: target == ProfileFormFieldId.profilePrompt
              ? const {}
              : completeProfile().prompts,
        );
        await repository.resetForTesting(profile);
        await tester.pumpWidget(
          MaterialApp(
            theme: AmoraTheme.light(),
            home: const ProfileCompletionScreen(),
          ),
        );
        await tester.pumpAndSettle();

        final pending = find.byKey(
          ValueKey('completion-pending-${target.name}'),
        );
        await tester.ensureVisible(pending);
        await tester.pumpAndSettle();
        await tester.tap(pending);
        await tester.pumpAndSettle();

        final field = find.byKey(ValueKey('profile-target-${target.name}'));
        expect(field, findsOneWidget, reason: target.name);
        final firstPosition = tester.getTopLeft(field);
        expect(firstPosition.dy, lessThan(700), reason: target.name);
        expect(
          tester.getBottomLeft(field).dy,
          greaterThan(0),
          reason: target.name,
        );
        await tester.pump(const Duration(milliseconds: 1200));
        expect(
          tester.getTopLeft(field).dy,
          firstPosition.dy,
          reason: target.name,
        );
        expect(tester.takeException(), isNull, reason: target.name);
      }
    },
  );

  testWidgets('Edit pending item scrolls to Languages exactly once', (
    tester,
  ) async {
    final lifestyle = Map<String, String>.of(completeProfile().lifestyle)
      ..remove('Languages');
    await repository.resetForTesting(
      completeProfile().copyWith(lifestyle: lifestyle),
    );
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const ProfileEditScreen()),
    );
    await tester.pumpAndSettle();

    final pending = find.byKey(const ValueKey('edit-pending-languages'));
    await tester.ensureVisible(pending);
    await tester.pumpAndSettle();
    await tester.tap(pending);
    await tester.pumpAndSettle();
    final target = find.byKey(const ValueKey('profile-target-languages'));
    expect(target, findsOneWidget);
    final position = tester.getTopLeft(target);
    expect(position.dy, lessThan(700));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(tester.getTopLeft(target).dy, position.dy);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Edit save validation scrolls and focuses the first invalid field',
    (tester) async {
      await repository.resetForTesting(completeProfile().copyWith(name: ''));
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(theme: AmoraTheme.light(), home: const ProfileEditScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('profile-save-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('edit-profile-validation-summary')),
        findsOneWidget,
      );
      final target = find.byKey(const ValueKey('profile-target-name'));
      expect(target, findsOneWidget);
      expect(tester.getTopLeft(target).dy, lessThan(700));
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('profile-name-field')),
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
