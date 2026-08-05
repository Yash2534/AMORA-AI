import 'dart:math' as math;

import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
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
    final storedGender = _repository.state.gender;
    final normalizedGender = ProfileFormOptions.normalizeGender(storedGender);
    _customGenderController.text =
        _repository.state.customGender.trim().isEmpty &&
            normalizedGender == 'Other' &&
            storedGender != null &&
            storedGender.toLowerCase() != 'other' &&
            storedGender.toLowerCase() != 'self-describe'
        ? storedGender
        : _repository.state.customGender;
    _cityController.text = ProfileFormOptions.normalizeCity(
      _repository.state.city,
    );
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
        ProfileFormOptions.normalizeGender(state.gender).isNotEmpty &&
            (ProfileFormOptions.normalizeGender(state.gender) != 'Other' ||
                _customGenderController.text.trim().isNotEmpty),
      2 => state.interestedIn.any(
        (value) => ProfileFormOptions.normalizeGender(value).isNotEmpty,
      ),
      3 => state.primaryRelationshipGoal != null,
      4 => ProfileFormOptions.cities.contains(_cityController.text.trim()),
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
          gender: ProfileFormOptions.normalizeGender(_repository.state.gender),
          customGender: _customGenderController.text.trim(),
        ),
      );
    }
    if (_page == 3) {
      final selected = _repository.state.primaryRelationshipGoal;
      if (selected != null) {
        _repository.update(
          _repository.state.copyWith(
            relationshipGoals: <String>{selected},
            relationshipGoal: selected,
          ),
        );
      }
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
        gender: ProfileFormOptions.storedGenderValue(
          onboarding.gender,
          customValue: onboarding.customGender,
        ),
        location: onboarding.city,
        datingIntention: onboarding.primaryRelationshipGoal,
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
    final normalizedGender = ProfileFormOptions.normalizeGender(state.gender);
    return _QuestionFrame(
      icon: Icons.person_rounded,
      title: 'How do you identify?',
      supporting: 'Choose the language that feels right for you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Gender', style: AmoraTextStyles.titleMedium),
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            'Select how you identify',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Column(
            key: const ValueKey('onboarding-gender-cards'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (
                var index = 0;
                index < ProfileFormOptions.genderOptions.length;
                index++
              ) ...[
                _GenderOptionCard(
                  key: ValueKey(
                    'onboarding-gender-option-${ProfileFormOptions.genderOptions[index]}',
                  ),
                  label: ProfileFormOptions.genderOptions[index],
                  selected:
                      normalizedGender ==
                      ProfileFormOptions.genderOptions[index],
                  onTap: () => onChanged(
                    state.copyWith(
                      gender: ProfileFormOptions.genderOptions[index],
                    ),
                  ),
                ),
                if (index < ProfileFormOptions.genderOptions.length - 1)
                  const SizedBox(height: AmoraSpacing.space12),
              ],
            ],
          ),
          if (normalizedGender == 'Other') ...[
            const SizedBox(height: AmoraSpacing.space12),
            TextField(
              key: const ValueKey('onboarding-custom-gender'),
              controller: customController,
              decoration: const InputDecoration(
                labelText: 'Describe your gender',
              ),
              onChanged: (_) => onChanged(
                state.copyWith(customGender: customController.text),
              ),
            ),
          ],
          SwitchListTile(
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

class _GenderOptionCard extends StatelessWidget {
  const _GenderOptionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(AmoraRadius.large));
    return Semantics(
      container: true,
      button: true,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      label: '$label, ${selected ? 'selected' : 'unselected'}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: .08)
                : AppColors.surface,
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : AppColors.tertiary.withValues(alpha: .72),
              width: selected ? 2 : 1,
            ),
          ),
          child: Material(
            color: AppColors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              focusColor: AppColors.secondary.withValues(alpha: .14),
              hoverColor: AppColors.secondary.withValues(alpha: .08),
              splashColor: AppColors.tertiary.withValues(alpha: .32),
              highlightColor: AppColors.tertiary.withValues(alpha: .18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AmoraSpacing.space20,
                  vertical: AmoraSpacing.space16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: AmoraTextStyles.titleMedium),
                    ),
                    const SizedBox(width: AmoraSpacing.space16),
                    _GenderRadioIndicator(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderRadioIndicator extends StatelessWidget {
  const _GenderRadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: ValueKey(selected ? 'selected-radio' : 'unselected-radio'),
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.secondary : AppColors.surface,
        border: Border.all(
          color: selected ? AppColors.secondary : AppColors.textMuted,
          width: 2,
        ),
      ),
      child: selected
          ? const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
              ),
            )
          : null,
    );
  }
}

class _InterestedQuestion extends StatelessWidget {
  const _InterestedQuestion({required this.state, required this.onChanged});
  final LocalOnboardingState state;
  final ValueChanged<LocalOnboardingState> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedOptions = state.interestedIn
        .map(ProfileFormOptions.normalizeGender)
        .where(ProfileFormOptions.genderOptions.contains)
        .toSet();
    return _QuestionFrame(
      icon: Icons.people_alt_rounded,
      title: 'Who would you like to meet?',
      supporting: 'You can update this later in Dating Preferences.',
      child: Column(
        children: [
          for (final option in ProfileFormOptions.genderOptions)
            _ChoiceCard(
              label: option,
              selected: selectedOptions.contains(option),
              onTap: () {
                final selected = Set<String>.of(selectedOptions);
                selected.contains(option)
                    ? selected.remove(option)
                    : selected.add(option);
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

  @override
  Widget build(BuildContext context) {
    final selected = state.primaryRelationshipGoal;
    return _QuestionFrame(
      icon: Icons.favorite_rounded,
      title: 'What are you looking for?',
      supporting: 'This helps people understand your intention from the start.',
      child: Column(
        key: const ValueKey('onboarding-relationship-cards'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dating Intention',
                  style: AmoraTextStyles.titleMedium,
                ),
              ),
              if (selected != null)
                Text(
                  '1 selected',
                  key: const ValueKey('onboarding-relationship-count'),
                  style: AmoraTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space12),
          for (
            var index = 0;
            index < ProfileFormOptions.datingIntentions.length;
            index++
          ) ...[
            _DatingIntentionCard(
              key: ValueKey(
                'onboarding-relationship-option-${ProfileFormOptions.datingIntentions[index]}',
              ),
              label: ProfileFormOptions.datingIntentions[index],
              description:
                  ProfileFormOptions
                      .datingIntentionDescriptions[ProfileFormOptions
                      .datingIntentions[index]] ??
                  '',
              selected: selected == ProfileFormOptions.datingIntentions[index],
              onTap: () {
                final option = ProfileFormOptions.datingIntentions[index];
                onChanged(
                  state.copyWith(
                    relationshipGoals: <String>{option},
                    relationshipGoal: option,
                  ),
                );
              },
            ),
            if (index < ProfileFormOptions.datingIntentions.length - 1)
              const SizedBox(height: AmoraSpacing.space12),
          ],
        ],
      ),
    );
  }
}

class _DatingIntentionCard extends StatelessWidget {
  const _DatingIntentionCard({
    super.key,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(AmoraRadius.large));
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '$label, ${selected ? 'selected' : 'unselected'}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: .08)
                : AppColors.surface,
            borderRadius: borderRadius,
            border: Border.all(
              color: selected
                  ? AppColors.secondary
                  : AppColors.tertiary.withValues(alpha: .72),
              width: selected ? 2 : 1,
            ),
          ),
          child: Material(
            color: AppColors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              focusColor: AppColors.secondary.withValues(alpha: .14),
              hoverColor: AppColors.secondary.withValues(alpha: .08),
              splashColor: AppColors.tertiary.withValues(alpha: .32),
              highlightColor: AppColors.tertiary.withValues(alpha: .18),
              child: Padding(
                padding: const EdgeInsets.all(AmoraSpacing.space16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AmoraTextStyles.titleMedium),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: AmoraSpacing.space4),
                            Text(
                              description,
                              style: AmoraTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.secondary
                              : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                key: const ValueKey('selected-intention-radio'),
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
            AmoraaSearchableSelect<String>(
              key: const Key('onboarding-city'),
              label: 'Your city',
              value: ProfileFormOptions.cities.contains(cityController.text)
                  ? cityController.text
                  : null,
              hintText: 'Search or select a city',
              searchHint: 'Search or select a city',
              supportingText: 'Choose the city where you currently live.',
              prefixIcon: Icons.location_on_rounded,
              isRequired: true,
              allowClear: true,
              options: [
                for (final city in ProfileFormOptions.cities)
                  AmoraaSelectOption(value: city, label: city),
              ],
              onChanged: (value) {
                cityController.text = value ?? '';
                onChanged(state.copyWith(city: value ?? ''));
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
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
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
                  child: Text(label, style: AmoraTextStyles.titleMedium),
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
