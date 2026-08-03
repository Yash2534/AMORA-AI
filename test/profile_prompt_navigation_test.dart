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
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
      expect(
        tester.getTopLeft(second).dy,
        greaterThan(tester.getBottomLeft(first).dy),
      );
      expect(tester.getSize(first).width, tester.getSize(second).width);

      await tester.tap(find.byKey(const ValueKey('add-profile-prompt')));
      await tester.pumpAndSettle();
      expect(find.text('Choose a prompt'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('prompt-option-Together we could...')),
      );
      await tester.pumpAndSettle();

      final answer = find.byKey(const ValueKey('profile-prompt-answer-field'));
      expect(answer, findsOneWidget);
      await tester.enterText(answer, '   ');
      expect(formKey.currentState?.validate(), isFalse);
      await tester.pump();
      expect(find.text('Write an answer for this prompt'), findsOneWidget);

      await tester.enterText(
        answer,
        '  Explore local cafes and plan a weekend road trip.  ',
      );
      expect(formKey.currentState?.validate(), isTrue);
      await controller.save();
      await tester.pump();

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
