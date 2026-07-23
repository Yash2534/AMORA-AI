import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

class ProfileOnboardingFlow extends StatefulWidget {
  const ProfileOnboardingFlow({super.key});

  static const routeName = '/profile-onboarding';

  @override
  State<ProfileOnboardingFlow> createState() => _ProfileOnboardingFlowState();
}

class _ProfileOnboardingFlowState extends State<ProfileOnboardingFlow> {
  static const _stages = <OnboardingStage>[
    OnboardingStage.gender,
    OnboardingStage.interestedIn,
    OnboardingStage.relationshipGoal,
    OnboardingStage.location,
  ];

  final _repository = LocalOnboardingRepository.instance;
  final _customGenderController = TextEditingController();
  final _cityController = TextEditingController();
  late final PageController _pageController;
  late int _page;

  @override
  void initState() {
    super.initState();
    final stageIndex = _stages.indexOf(_repository.state.stage);
    _page = stageIndex < 0 ? 0 : stageIndex;
    _pageController = PageController(initialPage: _page);
    _customGenderController.text = _repository.state.customGender;
    _cityController.text = _repository.state.city ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _customGenderController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 620,
          child: Column(
            children: [
              _FlowHeader(
                page: _page,
                total: _stages.length,
                onBack: _page == 0 ? null : _back,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _GenderQuestion(
                      state: _repository.state,
                      customController: _customGenderController,
                      onChanged: _update,
                    ),
                    _InterestedQuestion(
                      state: _repository.state,
                      onChanged: _update,
                    ),
                    _RelationshipQuestion(
                      state: _repository.state,
                      onChanged: _update,
                    ),
                    _LocationQuestion(
                      state: _repository.state,
                      cityController: _cityController,
                      onChanged: _update,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        key: const Key('onboarding-continue'),
                        label: _page == _stages.length - 1
                            ? 'Start discovering'
                            : 'Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _canContinue ? _continue : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canContinue {
    final state = _repository.state;
    return switch (_page) {
      0 =>
        state.gender != null &&
            (state.gender != 'Self-describe' ||
                _customGenderController.text.trim().isNotEmpty),
      1 => state.interestedIn.isNotEmpty,
      2 => state.relationshipGoal != null,
      3 => _cityController.text.trim().isNotEmpty,
      _ => false,
    };
  }

  void _update(LocalOnboardingState state) {
    _repository.update(state);
    setState(() {});
  }

  void _back() => _goTo(_page - 1, MediaQuery.disableAnimationsOf(context));

  void _continue() {
    if (_page == 0) {
      _repository.update(
        _repository.state.copyWith(
          customGender: _customGenderController.text.trim(),
        ),
      );
    }
    if (_page == _stages.length - 1) {
      _repository.update(
        _repository.state.copyWith(
          city: _cityController.text.trim(),
          onboardingCompleted: true,
          stage: OnboardingStage.complete,
        ),
      );
      _seedStarterProfile();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(MainShell.routeName, (route) => false);
      return;
    }
    _goTo(_page + 1, MediaQuery.disableAnimationsOf(context));
  }

  void _seedStarterProfile() {
    final onboarding = _repository.state;
    final current = LocalProfileRepository.instance.profile;
    LocalProfileRepository.instance.save(
      current.copyWith(
        gender: onboarding.gender == 'Self-describe'
            ? onboarding.customGender
            : onboarding.gender,
        location: onboarding.city,
        datingIntention: onboarding.relationshipGoal,
      ),
    );
  }

  void _goTo(int page, bool reducedMotion) {
    final target = page.clamp(0, _stages.length - 1);
    setState(() {
      _page = target;
    });
    _repository.update(_repository.state.copyWith(stage: _stages[target]));
    if (reducedMotion) {
      _pageController.jumpToPage(target);
    } else {
      _pageController.animateToPage(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _FlowHeader extends StatelessWidget {
  const _FlowHeader({required this.page, required this.total, this.onBack});

  final int page;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: onBack == null
                ? null
                : IconButton(
                    tooltip: 'Go back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Step ${page + 1} of $total',
                  style: AmoraTextStyles.labelLarge,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (page + 1) / total,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _QuestionFrame extends StatelessWidget {
  const _QuestionFrame({
    required this.icon,
    required this.title,
    required this.supporting,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String supporting;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 42, color: AppColors.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AmoraTextStyles.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            supporting,
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _GenderQuestion extends StatelessWidget {
  const _GenderQuestion({
    required this.state,
    required this.customController,
    required this.onChanged,
  });
  final LocalOnboardingState state;
  final TextEditingController customController;
  final ValueChanged<LocalOnboardingState> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [
      'Woman',
      'Man',
      'Non-binary',
      'Self-describe',
      'Prefer not to say',
    ];
    return _QuestionFrame(
      icon: Icons.person_rounded,
      title: 'How do you identify?',
      supporting: 'Choose the language that feels right for you.',
      child: Column(
        children: [
          for (final option in options)
            _ChoiceCard(
              label: option,
              selected: state.gender == option,
              onTap: () => onChanged(state.copyWith(gender: option)),
            ),
          if (state.gender == 'Self-describe') ...[
            const SizedBox(height: 8),
            TextField(
              controller: customController,
              decoration: const InputDecoration(
                labelText: 'Describe your gender',
              ),
              onChanged: (_) => onChanged(
                state.copyWith(customGender: customController.text),
              ),
            ),
          ],
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show my gender on my profile'),
            value: state.showGender,
            onChanged: (value) => onChanged(state.copyWith(showGender: value)),
          ),
        ],
      ),
    );
  }
}

class _InterestedQuestion extends StatelessWidget {
  const _InterestedQuestion({required this.state, required this.onChanged});
  final LocalOnboardingState state;
  final ValueChanged<LocalOnboardingState> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = ['Women', 'Men', 'Non-binary people', 'Everyone'];
    return _QuestionFrame(
      icon: Icons.people_alt_rounded,
      title: 'Who would you like to meet?',
      supporting: 'You can update this later in Dating Preferences.',
      child: Column(
        children: [
          for (final option in options)
            _ChoiceCard(
              label: option,
              selected: state.interestedIn.contains(option),
              onTap: () {
                final selected = Set<String>.of(state.interestedIn);
                if (option == 'Everyone') {
                  selected
                    ..clear()
                    ..add(option);
                } else {
                  selected.remove('Everyone');
                  selected.contains(option)
                      ? selected.remove(option)
                      : selected.add(option);
                }
                onChanged(state.copyWith(interestedIn: selected));
              },
            ),
        ],
      ),
    );
  }
}

class _RelationshipQuestion extends StatelessWidget {
  const _RelationshipQuestion({required this.state, required this.onChanged});
  final LocalOnboardingState state;
  final ValueChanged<LocalOnboardingState> onChanged;

  static const options = <String, String>{
    'Long-term relationship': 'Build something lasting and intentional.',
    'Serious dating': 'Meet people ready for committed dating.',
    'Dating and seeing where it goes': 'Stay open while dating thoughtfully.',
    'Friendship': 'Begin with genuine companionship.',
    'Still figuring it out': 'Explore honestly without pressure.',
  };

  @override
  Widget build(BuildContext context) {
    return _QuestionFrame(
      icon: Icons.favorite_rounded,
      title: 'What are you looking for?',
      supporting: 'This helps people understand your intention from the start.',
      child: Column(
        children: [
          for (final entry in options.entries)
            _ChoiceCard(
              label: entry.key,
              supporting: entry.value,
              selected: state.relationshipGoal == entry.key,
              onTap: () =>
                  onChanged(state.copyWith(relationshipGoal: entry.key)),
            ),
        ],
      ),
    );
  }
}

class _LocationQuestion extends StatelessWidget {
  const _LocationQuestion({
    required this.state,
    required this.cityController,
    required this.onChanged,
  });
  final LocalOnboardingState state;
  final TextEditingController cityController;
  final ValueChanged<LocalOnboardingState> onChanged;

  @override
  Widget build(BuildContext context) {
    return _QuestionFrame(
      icon: Icons.location_on_rounded,
      title: 'Where would you like to meet people?',
      supporting:
          'Enter a city manually. This demo does not request or claim live GPS access.',
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('onboarding-city'),
              controller: cityController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'City',
                prefixIcon: Icon(Icons.location_city_rounded),
              ),
              onChanged: (value) =>
                  onChanged(state.copyWith(city: value.trim())),
            ),
            const SizedBox(height: 20),
            Text('Preferred distance: ${state.preferredDistance.round()} km'),
            Slider(
              value: state.preferredDistance,
              min: 5,
              max: 150,
              divisions: 29,
              label: '${state.preferredDistance.round()} km',
              onChanged: (value) =>
                  onChanged(state.copyWith(preferredDistance: value)),
            ),
            Text(
              'Only your city is shown on your profile.',
              style: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.supporting,
  });
  final String label;
  final String? supporting;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Select $label',
        child: InkWell(
          onTap: onTap,
          borderRadius: AmoraRadius.card,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AppColors.selectedContainer : AppColors.surface,
              borderRadius: AmoraRadius.card,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AmoraTextStyles.titleMedium),
                      if (supporting != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          supporting!,
                          style: AmoraTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
