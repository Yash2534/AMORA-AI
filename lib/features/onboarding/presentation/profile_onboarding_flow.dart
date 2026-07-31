import 'dart:math' as math;

import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/onboarding/data/gujarat_cities.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileOnboardingFlow extends StatefulWidget {
  const ProfileOnboardingFlow({super.key});

  static const routeName = '/profile-onboarding';

  @override
  State<ProfileOnboardingFlow> createState() => _ProfileOnboardingFlowState();
}

class _ProfileOnboardingFlowState extends State<ProfileOnboardingFlow> {
  static const _stages = <OnboardingStage>[
    OnboardingStage.age,
    OnboardingStage.gender,
    OnboardingStage.interestedIn,
    OnboardingStage.relationshipGoal,
    OnboardingStage.location,
    OnboardingStage.photos,
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
    _page =
        _repository.state.birthDate == null &&
            _repository.state.stage == OnboardingStage.gender
        ? 0
        : stageIndex < 0
        ? 0
        : stageIndex;
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
                onBack: _page == 0
                    ? (Navigator.of(context).canPop()
                          ? () => Navigator.of(context).maybePop()
                          : null)
                    : _back,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _BirthDateQuestion(
                      state: _repository.state,
                      onChanged: _update,
                    ),
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
                    _PhotoQuestion(
                      photoCount:
                          LocalProfileRepository.instance.profile.photos.length,
                      onManagePhotos: _openPhotoManager,
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
      0 => state.birthDate != null && state.isAdult,
      1 =>
        state.gender != null &&
            (state.gender != 'Self-describe' ||
                _customGenderController.text.trim().isNotEmpty),
      2 => state.interestedIn.isNotEmpty,
      3 => state.relationshipGoal != null,
      4 => _cityController.text.trim().isNotEmpty,
      5 => LocalProfileRepository.instance.profile.photos.length >= 2,
      _ => false,
    };
  }

  void _update(LocalOnboardingState state) {
    _repository.update(state);
    setState(() {});
  }

  void _back() => _goTo(_page - 1, MediaQuery.disableAnimationsOf(context));

  void _continue() {
    if (_page == 1) {
      _repository.update(
        _repository.state.copyWith(
          customGender: _customGenderController.text.trim(),
        ),
      );
    }
    if (_page == 4) {
      _repository.update(
        _repository.state.copyWith(city: _cityController.text.trim()),
      );
    }
    if (_page == _stages.length - 1) {
      _repository.update(
        _repository.state.copyWith(
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

  Future<void> _openPhotoManager() async {
    await Navigator.of(context).pushNamed(PhotoManagerScreen.routeName);
    if (mounted) setState(() {});
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

class _PhotoQuestion extends StatelessWidget {
  const _PhotoQuestion({
    required this.photoCount,
    required this.onManagePhotos,
  });

  final int photoCount;
  final VoidCallback onManagePhotos;

  @override
  Widget build(BuildContext context) {
    final complete = photoCount >= 2;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add your best photos', style: AmoraTextStyles.headlineMedium),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            'Add 2–6 photos, choose a primary photo, and put them in the order you want people to see.',
            style: AmoraTextStyles.bodyLarge,
          ),
          const SizedBox(height: AmoraSpacing.space24),
          PremiumCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: complete
                        ? AppColors.success.withValues(alpha: .12)
                        : AppColors.tertiary.withValues(alpha: .28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    complete
                        ? Icons.check_rounded
                        : Icons.add_photo_alternate_rounded,
                    color: complete ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$photoCount of 6 photos added',
                        style: AmoraTextStyles.titleMedium,
                      ),
                      const SizedBox(height: AmoraSpacing.space4),
                      Text(
                        complete
                            ? 'Minimum photo requirement met.'
                            : 'Add at least ${2 - photoCount} more.',
                        style: AmoraTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AmoraSpacing.space16),
          AppPrimaryButton(
            label: complete ? 'Manage photos' : 'Add photos',
            icon: Icons.photo_library_rounded,
            variant: AppPrimaryButtonVariant.outlined,
            onPressed: onManagePhotos,
          ),
        ],
      ),
    );
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

class _BirthDateQuestion extends StatefulWidget {
  const _BirthDateQuestion({required this.state, required this.onChanged});

  final LocalOnboardingState state;
  final ValueChanged<LocalOnboardingState> onChanged;

  @override
  State<_BirthDateQuestion> createState() => _BirthDateQuestionState();
}

class _BirthDateQuestionState extends State<_BirthDateQuestion> {
  static const _minimumAge = 18;
  static const _maximumAge = 100;
  static const _itemExtent = 52.0;

  late final FixedExtentScrollController _dayController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _yearController;
  final _dayFocusNode = FocusNode(debugLabel: 'Birth date day');
  final _monthFocusNode = FocusNode(debugLabel: 'Birth date month');
  final _yearFocusNode = FocusNode(debugLabel: 'Birth date year');

  late final int _currentYear;
  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  int get _dayCount => DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  int get _yearCount => _maximumAge + 1;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _currentYear = today.year;
    final saved = widget.state.birthDate;
    final initialYear = (saved?.year ?? today.year - 24).clamp(
      today.year - _maximumAge,
      today.year,
    );
    final initialMonth = saved?.month ?? today.month;
    final initialDay = math.min(
      saved?.day ?? today.day,
      DateTime(initialYear, initialMonth + 1, 0).day,
    );

    _selectedDay = initialDay;
    _selectedMonth = initialMonth;
    _selectedYear = initialYear;
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _yearController = FixedExtentScrollController(
      initialItem: _currentYear - _selectedYear,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _dayFocusNode.dispose();
    _monthFocusNode.dispose();
    _yearFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final age = widget.state.age;
    final hasSelection = widget.state.birthDate != null;
    final isUnderage = hasSelection && !widget.state.isAdult;
    final compactHeight = MediaQuery.sizeOf(context).height < 680;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, compactHeight ? 4 : 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: compactHeight ? 0 : 8),
          Text(
            "When's your birthday?",
            textAlign: TextAlign.center,
            style: AmoraTextStyles.headlineMedium.copyWith(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: compactHeight ? 6 : 10),
          Text(
            'We use your date of birth to calculate your age. Your full birth '
            'date won’t appear on your public profile.',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyLarge.copyWith(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: compactHeight ? 14 : 24),
          Semantics(
            container: true,
            label: hasSelection
                ? 'Birth date picker, ${_spokenDate(widget.state.birthDate!)}'
                : 'Birth date picker. Choose day, month, and year.',
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.tertiary),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                12,
                compactHeight ? 10 : 14,
                12,
                compactHeight ? 8 : 12,
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Expanded(child: _WheelLabel('Day')),
                      Expanded(child: _WheelLabel('Month')),
                      Expanded(child: _WheelLabel('Year')),
                    ],
                  ),
                  SizedBox(height: compactHeight ? 2 : 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: compactHeight
                        ? isUnderage
                              ? 120
                              : 156
                        : 184,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IgnorePointer(
                          child: Container(
                            height: _itemExtent,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.tertiary),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _WheelColumn(
                                key: const Key('birthdate-day-wheel'),
                                controller: _dayController,
                                focusNode: _dayFocusNode,
                                itemCount: _dayCount,
                                semanticLabel: 'Day',
                                displayValue: (index) => '${index + 1}',
                                spokenValue: (index) => '${index + 1}',
                                selectedIndex: _selectedDay - 1,
                                onSelectedItemChanged: _selectDay,
                              ),
                            ),
                            Expanded(
                              child: _WheelColumn(
                                key: const Key('birthdate-month-wheel'),
                                controller: _monthController,
                                focusNode: _monthFocusNode,
                                itemCount: _monthNames.length,
                                semanticLabel: 'Month',
                                displayValue: (index) =>
                                    _monthAbbreviations[index],
                                spokenValue: (index) => _monthNames[index],
                                selectedIndex: _selectedMonth - 1,
                                onSelectedItemChanged: _selectMonth,
                              ),
                            ),
                            Expanded(
                              child: _WheelColumn(
                                key: const Key('birthdate-year-wheel'),
                                controller: _yearController,
                                focusNode: _yearFocusNode,
                                itemCount: _yearCount,
                                semanticLabel: 'Year',
                                displayValue: (index) =>
                                    '${_currentYear - index}',
                                spokenValue: (index) =>
                                    '${_currentYear - index}',
                                selectedIndex: _currentYear - _selectedYear,
                                onSelectedItemChanged: _selectYear,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compactHeight ? 2 : 4),
                  Text(
                    hasSelection
                        ? _formattedDate(widget.state.birthDate!)
                        : 'Scroll to select your date',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: compactHeight ? 10 : 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: hasSelection
                ? Semantics(
                    key: ValueKey(age),
                    liveRegion: true,
                    label: 'Age, $age years',
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.tertiary),
                      ),
                      child: Text(
                        'Age: $age years',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-age')),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: isUnderage
                ? Semantics(
                    key: const ValueKey('underage-error'),
                    liveRegion: true,
                    label: 'You must be at least 18 years old.',
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You must be at least $_minimumAge years old.',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('no-error')),
          ),
        ],
      ),
    );
  }

  void _selectDay(int index) {
    setState(() => _selectedDay = index + 1);
    _commitSelection();
  }

  void _selectMonth(int index) {
    setState(() {
      _selectedMonth = index + 1;
      _selectedDay = math.min(_selectedDay, _dayCount);
    });
    _syncDayWheel();
    _commitSelection();
  }

  void _selectYear(int index) {
    setState(() {
      _selectedYear = _currentYear - index;
      _selectedDay = math.min(_selectedDay, _dayCount);
    });
    _syncDayWheel();
    _commitSelection();
  }

  void _syncDayWheel() {
    if (_dayController.hasClients &&
        _dayController.selectedItem != _selectedDay - 1) {
      _dayController.jumpToItem(_selectedDay - 1);
    }
  }

  void _commitSelection() {
    widget.onChanged(
      widget.state.copyWith(
        birthDate: DateTime(_selectedYear, _selectedMonth, _selectedDay),
      ),
    );
  }
}

class _WheelLabel extends StatelessWidget {
  const _WheelLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 14,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.itemCount,
    required this.semanticLabel,
    required this.displayValue,
    required this.spokenValue,
    required this.selectedIndex,
    required this.onSelectedItemChanged,
  });

  final FixedExtentScrollController controller;
  final FocusNode focusNode;
  final int itemCount;
  final String semanticLabel;
  final String Function(int index) displayValue;
  final String Function(int index) spokenValue;
  final int selectedIndex;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: spokenValue(selectedIndex),
      increasedValue: selectedIndex > 0 ? spokenValue(selectedIndex - 1) : null,
      decreasedValue: selectedIndex < itemCount - 1
          ? spokenValue(selectedIndex + 1)
          : null,
      onIncrease: selectedIndex > 0 ? () => _moveTo(selectedIndex - 1) : null,
      onDecrease: selectedIndex < itemCount - 1
          ? () => _moveTo(selectedIndex + 1)
          : null,
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (_, event) => _handleKey(event),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => focusNode.requestFocus(),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _BirthDateQuestionState._itemExtent,
            diameterRatio: 1.45,
            squeeze: 1.05,
            useMagnifier: true,
            magnification: 1.05,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelectedItemChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) {
                final selected = index == selectedIndex;
                return Center(
                  child: ExcludeSemantics(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.text,
                        fontSize: 20,
                        height: 1.2,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      child: Text(
                        displayValue(index),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
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

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveTo((selectedIndex - 1).clamp(0, itemCount - 1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveTo((selectedIndex + 1).clamp(0, itemCount - 1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _moveTo(int index) {
    if (index == selectedIndex) return;
    onSelectedItemChanged(index);
    controller.animateToItem(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
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
      title: 'Your city',
      supporting: 'Choose the city where you currently live.',
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OnboardingCityField(
              key: const Key('onboarding-city'),
              city: cityController.text,
              onSelect: () => _selectCity(context),
              onClear: cityController.text.trim().isEmpty
                  ? null
                  : () {
                      cityController.clear();
                      onChanged(state.copyWith(city: ''));
                    },
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

  Future<void> _selectCity(BuildContext context) async {
    final width = MediaQuery.sizeOf(context).width;
    final current = cityController.text.trim();
    final result = width >= 700
        ? await showDialog<String>(
            context: context,
            builder: (_) => Dialog(
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 560,
                  maxHeight: 680,
                ),
                child: _GujaratCitySearchSheet(currentCity: current),
              ),
            ),
          )
        : await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            builder: (_) => FractionallySizedBox(
              heightFactor: .88,
              child: _GujaratCitySearchSheet(currentCity: current),
            ),
          );
    if (result == null || !context.mounted) return;
    cityController.text = result;
    onChanged(state.copyWith(city: result));
  }
}

class _OnboardingCityField extends StatelessWidget {
  const _OnboardingCityField({
    super.key,
    required this.city,
    required this.onSelect,
    this.onClear,
  });

  final String city;
  final VoidCallback onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasCity = city.trim().isNotEmpty;
    return Semantics(
      button: true,
      liveRegion: hasCity,
      label: hasCity
          ? 'Your city, $city. Open city selection.'
          : 'Search or select a city',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.tertiary),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Your city',
                        style: AmoraTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasCity ? city : 'Search or select a city',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.bodyLarge.copyWith(
                          color: hasCity
                              ? AppColors.text
                              : AppColors.text.withValues(alpha: .58),
                          fontWeight: hasCity
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    tooltip: 'Clear selected city',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GujaratCitySearchSheet extends StatefulWidget {
  const _GujaratCitySearchSheet({required this.currentCity});

  final String currentCity;

  @override
  State<_GujaratCitySearchSheet> createState() =>
      _GujaratCitySearchSheetState();
}

class _GujaratCitySearchSheetState extends State<_GujaratCitySearchSheet> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'Gujarat city search');
  final _keyboardFocusNode = FocusNode(debugLabel: 'Gujarat city keyboard');
  int _highlightedIndex = 0;

  List<String> get _filteredCities {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return gujaratCities;
    return gujaratCities
        .where((city) => city.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_filterChanged)
      ..dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _filterChanged() {
    setState(() => _highlightedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final cities = _filteredCities;
    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (_, event) => _handleKey(event, cities),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose your city',
                      style: AmoraTextStyles.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close city selection',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('gujarat-city-search'),
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  if (cities.isNotEmpty) {
                    Navigator.pop(context, cities[_highlightedIndex]);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search or select a city',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear city search',
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              if (widget.currentCity.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Current selection: ${widget.currentCity}',
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: cities.isEmpty
                    ? const _NoCityResults()
                    : ListView.builder(
                        key: const ValueKey('gujarat-city-list'),
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          final selected = city == widget.currentCity;
                          final highlighted = index == _highlightedIndex;
                          return Semantics(
                            selected: selected,
                            button: true,
                            child: ListTile(
                              key: ValueKey('gujarat-city-$city'),
                              minTileHeight: 52,
                              selected: selected || highlighted,
                              selectedTileColor: AppColors.tertiary.withValues(
                                alpha: selected ? .32 : .16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              leading: Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.location_city_rounded,
                                color: selected
                                    ? AppColors.secondary
                                    : AppColors.primary,
                              ),
                              title: Text(
                                city,
                                style: AmoraTextStyles.bodyLarge.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              onTap: () => Navigator.pop(context, city),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(KeyEvent event, List<String> cities) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    if (cities.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1).clamp(0, cities.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex = (_highlightedIndex - 1).clamp(0, cities.length - 1);
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      Navigator.pop(context, cities[_highlightedIndex]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _NoCityResults extends StatelessWidget {
  const _NoCityResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_off_rounded,
            color: AppColors.secondary,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            'No Gujarat cities found',
            style: AmoraTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a shorter or different spelling.',
            style: AmoraTextStyles.bodyMedium,
          ),
        ],
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

String _formattedDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

String _spokenDate(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
}

const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _monthAbbreviations = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
