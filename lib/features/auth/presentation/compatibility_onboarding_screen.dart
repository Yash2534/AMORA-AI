import 'dart:async';

import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/progress_header.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:flutter/material.dart';

class CompatibilityOnboardingScreen extends StatefulWidget {
  const CompatibilityOnboardingScreen({super.key});

  static const routeName = '/compatibility';

  @override
  State<CompatibilityOnboardingScreen> createState() =>
      _CompatibilityOnboardingScreenState();
}

class _CompatibilityOnboardingScreenState
    extends State<CompatibilityOnboardingScreen> {
  int _index = 0;
  bool _showResult = false;
  bool _loading = false;
  final Map<String, String> _answers = {};

  _QuizQuestion get _question => _questions[_index];
  bool get _isLast => _index == _questions.length - 1;
  double get _progress => _showResult ? 1 : (_index + 1) / _questions.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth < 390
                    ? AmoraSpacing.space16
                    : AmoraSpacing.space24;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AmoraSpacing.space16,
                    padding,
                    AmoraSpacing.space24 +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AmoraSpacing.space40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProgressHeader(
                          title: 'AI Questions',
                          subtitle:
                              'Question ${_index + 1} / 12. Auto-saved locally and takes about 2-3 minutes.',
                          progress: _progress,
                          onBack: _showResult
                              ? () => setState(() => _showResult = false)
                              : (_index == 0 ? null : _previous),
                        ),
                        const SizedBox(height: AmoraSpacing.space20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(.05, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _showResult
                              ? _ResultPreview(
                                  key: const ValueKey('result'),
                                  answers: _answers,
                                )
                              : _QuestionCard(
                                  key: ValueKey(_question.category),
                                  question: _question,
                                  index: _index,
                                  selected: _answers[_question.category],
                                  onSelected: (value) => setState(
                                    () => _answers[_question.category] = value,
                                  ),
                                ),
                        ),
                        const SizedBox(height: AmoraSpacing.space20),
                        if (!_showResult)
                          Row(
                            children: [
                              Expanded(
                                child: AppPrimaryButton(
                                  label: 'Back',
                                  icon: Icons.arrow_back_rounded,
                                  variant: AppPrimaryButtonVariant.outlined,
                                  onPressed: _index == 0 ? null : _previous,
                                ),
                              ),
                              const SizedBox(width: AmoraSpacing.space12),
                              Expanded(
                                child: AppPrimaryButton(
                                  label: _isLast ? 'Preview' : 'Next',
                                  icon: _isLast
                                      ? Icons.auto_awesome_rounded
                                      : Icons.arrow_forward_rounded,
                                  onPressed:
                                      _answers[_question.category] == null
                                      ? null
                                      : _next,
                                ),
                              ),
                            ],
                          )
                        else
                          AppPrimaryButton(
                            label: 'Enable AI Matching',
                            icon: Icons.favorite_rounded,
                            isLoading: _loading,
                            onPressed: _loading ? null : _finish,
                          ),
                        const SizedBox(height: AmoraSpacing.space12),
                        AppPrimaryButton(
                          label: 'Resume Later',
                          variant: AppPrimaryButtonVariant.text,
                          onPressed: _resumeLater,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _previous() {
    setState(() => _index = (_index - 1).clamp(0, _questions.length - 1));
  }

  void _next() {
    if (!_isLast) {
      setState(() => _index++);
      return;
    }
    setState(() => _showResult = true);
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    AmoraSession.completeProfileStep(80);
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false);
  }

  void _resumeLater() {
    AmoraSession.completeProfileStep(60);
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false);
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.question,
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final _QuizQuestion question;
  final int index;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CategoryIcon(icon: question.icon),
              const SizedBox(width: AmoraSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1} of ${_questions.length}',
                      style: AmoraTextStyles.titleSmall.copyWith(
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space4),
                    Text(
                      question.category,
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space20),
          Text(question.title, style: AmoraTextStyles.headlineMedium),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            question.helper,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          for (final option in question.options) ...[
            _AnswerCard(
              label: option,
              selected: selected == option,
              onTap: () => onSelected(option),
            ),
            const SizedBox(height: AmoraSpacing.space12),
          ],
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AmoraRadius.card,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AmoraSpacing.space16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryPurple.withValues(alpha: .10)
              : AppColors.lightPinkBackground,
          borderRadius: AmoraRadius.card,
          border: Border.all(
            color: selected ? AppColors.primaryPurple : AppColors.borderGray,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primaryPurple : AppColors.textGray,
            ),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Text(
                label,
                style: AmoraTextStyles.bodyLarge.copyWith(
                  color: AppColors.deepWine,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({super.key, required this.answers});

  final Map<String, String> answers;

  @override
  Widget build(BuildContext context) {
    final topValues = answers.entries.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(AmoraSpacing.space24),
          color: AppColors.deepWine,
          borderColor: AppColors.deepWine,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.premiumGold,
                size: 30,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              Text(
                'Your compatibility preview',
                style: AmoraTextStyles.headlineMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space12),
              Text(
                'AMORA AI will prioritize values-led introductions, safer first conversations, and matches who fit your daily rhythm.',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.background,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AmoraSpacing.space16),
        PremiumCard(
          radius: AmoraRadius.extraLarge,
          padding: const EdgeInsets.all(AmoraSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Result explanation',
                style: AmoraTextStyles.titleLarge.copyWith(
                  color: AppColors.deepWine,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                'These answers stay local in this frontend flow. They shape the next profile setup step and are ready for a future backend contract.',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              for (final entry in topValues) ...[
                _ResultLine(label: entry.key, value: entry.value),
                const SizedBox(height: AmoraSpacing.space12),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.favorite_rounded,
          color: AppColors.primaryRose,
          size: 18,
        ),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$label: ',
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.deepWine,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: .10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryPurple),
    );
  }
}

class _QuizQuestion {
  const _QuizQuestion({
    required this.category,
    required this.title,
    required this.helper,
    required this.icon,
    required this.options,
  });

  final String category;
  final String title;
  final String helper;
  final IconData icon;
  final List<String> options;
}

const _questions = [
  _QuizQuestion(
    category: 'Personality',
    title: 'What kind of energy feels most like you?',
    helper: 'This helps AMORA AI understand your everyday personality rhythm.',
    icon: Icons.self_improvement_rounded,
    options: [
      'Quiet routines and meaningful one-on-one time',
      'A mix of work, friends, family, and hobbies',
      'High energy schedule with events and plans',
      'Flexible and spontaneous, depending on the week',
    ],
  ),
  _QuizQuestion(
    category: 'Communication',
    title: 'How do you prefer to stay connected?',
    helper: 'Communication habits are a strong predictor of early chemistry.',
    icon: Icons.chat_bubble_rounded,
    options: [
      'Heritage walks and cultural cities',
      'Luxury escapes and boutique stays',
      'Mountains, beaches, and nature breaks',
      'Staycations with food and conversation',
    ],
  ),
  _QuizQuestion(
    category: 'Love Language',
    title: 'What makes you feel most cared for?',
    helper: 'Love-language signals shape better matches and date ideas.',
    icon: Icons.favorite_rounded,
    options: [
      'Very important and involved over time',
      'Important, with healthy boundaries',
      'Supportive but not central early on',
      'Open to discovering what works together',
    ],
  ),
  _QuizQuestion(
    category: 'Lifestyle',
    title: 'What does a balanced week look like for you?',
    helper: 'This helps AMORA AI understand your everyday rhythm.',
    icon: Icons.self_improvement_rounded,
    options: [
      'Traditions are a meaningful part of life',
      'Spiritual, but flexible in practice',
      'Respectful of all beliefs and preferences',
      'Not central, but open to my partner values',
    ],
  ),
  _QuizQuestion(
    category: 'Career',
    title: 'How do you view ambition and work?',
    helper: 'Career rhythm can strongly influence relationship expectations.',
    icon: Icons.work_rounded,
    options: [
      'Vegetarian',
      'Jain-friendly',
      'Non-vegetarian',
      'Flexible and curious',
    ],
  ),
  _QuizQuestion(
    category: 'Future Goals',
    title: 'What are you hoping to build over the next few years?',
    helper: 'Long-term direction helps AMORA identify relationship potential.',
    icon: Icons.route_rounded,
    options: [
      'Rom-coms and feel-good stories',
      'Thrillers, mystery, and sharp plots',
      'Drama, indie, and thoughtful cinema',
      'Big-screen action and comedy',
    ],
  ),
  _QuizQuestion(
    category: 'Family',
    title: 'How should family fit into your relationship?',
    helper:
        'Indian dating often includes family expectations, timing, and care.',
    icon: Icons.family_restroom_rounded,
    options: [
      'Bollywood and retro classics',
      'Indie, acoustic, and soft playlists',
      'Punjabi, Garba, and dance energy',
      'Global pop, fusion, and everything new',
    ],
  ),
  _QuizQuestion(
    category: 'Habits',
    title: 'Which daily habit matters most to you?',
    helper: 'Small routines often decide real-world compatibility.',
    icon: Icons.check_circle_rounded,
    options: [
      'Ambition is a big part of my identity',
      'Balanced success and personal life matter',
      'Purpose and creativity matter most',
      'I value stability and thoughtful growth',
    ],
  ),
  _QuizQuestion(
    category: 'Travel',
    title: 'What travel style would you love sharing?',
    helper: 'Shared adventure preferences make better date planning signals.',
    icon: Icons.flight_takeoff_rounded,
    options: [
      'Fitness is a consistent routine',
      'I enjoy walks, yoga, or light movement',
      'I am trying to become more active',
      'Not a priority, but I support my partner',
    ],
  ),
  _QuizQuestion(
    category: 'Finance',
    title: 'How do you approach money in a relationship?',
    helper: 'Financial comfort and planning styles affect future alignment.',
    icon: Icons.account_balance_wallet_rounded,
    options: [
      'I want children in the future',
      'I am open, depending on the relationship',
      'I do not see children in my future',
      'I prefer to discuss this later',
    ],
  ),
  _QuizQuestion(
    category: 'Conflict Resolution',
    title: 'What helps you repair after disagreement?',
    helper: 'Healthy conflict patterns create safer long-term connection.',
    icon: Icons.handshake_rounded,
    options: [
      'I love pets and want them around',
      'I like pets, with practical boundaries',
      'I am neutral and flexible',
      'I prefer a pet-free home',
    ],
  ),
  _QuizQuestion(
    category: 'Relationship Expectations',
    title: 'What are you hoping to build?',
    helper: 'This gives AMORA AI the clearest intent signal.',
    icon: Icons.favorite_rounded,
    options: [
      'A serious long-term relationship',
      'Intentional dating leading to commitment',
      'Companionship with emotional maturity',
      'Marriage-minded connection with shared values',
    ],
  ),
];
