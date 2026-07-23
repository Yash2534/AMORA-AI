import 'dart:math' as math;

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraAuthShell extends StatelessWidget {
  const AmoraAuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
    this.statement = 'Meaningful connections begin here.',
    this.showComposition = true,
    this.footer,
    this.stepLabel,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBack;
  final String statement;
  final bool showComposition;
  final Widget? footer;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final desktop = viewport.maxWidth >= 820;
              final horizontalPadding = viewport.maxWidth < 360
                  ? AmoraSpacing.space12
                  : viewport.maxWidth < 600
                  ? AmoraSpacing.space16
                  : AmoraSpacing.space32;
              final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AmoraSpacing.space12,
                  horizontalPadding,
                  AmoraSpacing.space24 + keyboardInset,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: desktop
                        ? _DesktopAuthLayout(
                            title: title,
                            subtitle: subtitle,
                            statement: statement,
                            onBack: onBack,
                            stepLabel: stepLabel,
                            footer: footer,
                            child: child,
                          )
                        : _MobileAuthLayout(
                            title: title,
                            subtitle: subtitle,
                            statement: statement,
                            onBack: onBack,
                            stepLabel: stepLabel,
                            showComposition: showComposition,
                            footer: footer,
                            child: child,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileAuthLayout extends StatelessWidget {
  const _MobileAuthLayout({
    required this.title,
    required this.subtitle,
    required this.statement,
    required this.onBack,
    required this.stepLabel,
    required this.showComposition,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final String statement;
  final VoidCallback onBack;
  final String? stepLabel;
  final bool showComposition;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthBrandHeader(onBack: onBack, stepLabel: stepLabel),
          if (showComposition) ...[
            const SizedBox(height: AmoraSpacing.space16),
            AuthConnectionComposition(statement: statement),
          ],
          const SizedBox(height: AmoraSpacing.space20),
          AuthPageHeader(title: title, subtitle: subtitle),
          const SizedBox(height: AmoraSpacing.space20),
          FadeUp(child: AuthFormSurface(child: child)),
          if (footer != null) ...[
            const SizedBox(height: AmoraSpacing.space16),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _DesktopAuthLayout extends StatelessWidget {
  const _DesktopAuthLayout({
    required this.title,
    required this.subtitle,
    required this.statement,
    required this.onBack,
    required this.stepLabel,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final String statement;
  final VoidCallback onBack;
  final String? stepLabel;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 72, 40, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthConnectionComposition(statement: statement, expanded: true),
                const SizedBox(height: AmoraSpacing.space24),
                Text(
                  'A private space for intentional connection.',
                  style: AmoraTextStyles.headlineSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                Text(
                  'Thoughtful profiles, clear choices, and a focused path into Amora.',
                  style: AmoraTextStyles.bodyLarge.copyWith(
                    color: AppColors.textNeutral.withValues(alpha: .72),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthBrandHeader(onBack: onBack, stepLabel: stepLabel),
              const SizedBox(height: AmoraSpacing.space24),
              AuthPageHeader(title: title, subtitle: subtitle),
              const SizedBox(height: AmoraSpacing.space20),
              FadeUp(child: AuthFormSurface(child: child)),
              if (footer != null) ...[
                const SizedBox(height: AmoraSpacing.space16),
                footer!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key, required this.onBack, this.stepLabel});

  final VoidCallback onBack;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Row(
          children: [
            IconButton.outlined(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            SizedBox(
              width: compact ? AmoraSpacing.space8 : AmoraSpacing.space12,
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.favorite_rounded,
                size: 18,
                color: AppColors.surface,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: AmoraSpacing.space8),
              Text(
                'AMORA',
                style: AmoraTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
            const Spacer(),
            if (stepLabel != null)
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact
                        ? AmoraSpacing.space8
                        : AmoraSpacing.space12,
                    vertical: AmoraSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AmoraRadius.pillBorder,
                    border: Border.all(color: AppColors.tertiary),
                  ),
                  child: Text(
                    stepLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AmoraTextStyles.headlineMedium),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          subtitle,
          style: AmoraTextStyles.bodyLarge.copyWith(
            color: AppColors.textNeutral.withValues(alpha: .7),
          ),
        ),
      ],
    );
  }
}

class AuthFormSurface extends StatelessWidget {
  const AuthFormSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .7)),
        boxShadow: AmoraShadows.level2,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 360
              ? AmoraSpacing.space16
              : AmoraSpacing.space20,
        ),
        child: child,
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: isLoading ? '$label, loading' : label,
      child: SizedBox(
        height: AmoraSpacing.controlHeight,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            disabledBackgroundColor: AppColors.tertiary.withValues(alpha: .62),
            disabledForegroundColor: AppColors.primary.withValues(alpha: .48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: AnimatedSwitcher(
            duration: AmoraMotion.fast,
            child: Row(
              key: ValueKey(isLoading),
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, size: 20),
                if (isLoading || icon != null)
                  const SizedBox(width: AmoraSpacing.space8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthConnectionComposition extends StatelessWidget {
  const AuthConnectionComposition({
    super.key,
    required this.statement,
    this.expanded = false,
  });

  final String statement;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final height = expanded ? 236.0 : 148.0;
    return Semantics(
      image: true,
      label: 'A small collage representing meaningful connections',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: .72)),
          boxShadow: AmoraShadows.level1,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = expanded ? 1.28 : 1.0;
              return Stack(
                children: [
                  Positioned(
                    left: -18,
                    top: -22,
                    child: _AccentRing(size: 86 * scale),
                  ),
                  Positioned(
                    right: -22,
                    bottom: -28,
                    child: _AccentRing(size: 104 * scale),
                  ),
                  Positioned(
                    left: constraints.maxWidth * .08,
                    top: expanded ? 38 : 23,
                    child: _ProfileFragment(
                      asset: AppImages.profileAadhya,
                      size: 76 * scale,
                      tilt: -.06,
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * .26,
                    top: expanded ? 74 : 46,
                    child: _ProfileFragment(
                      asset: AppImages.profileAarav,
                      size: 82 * scale,
                      tilt: .05,
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * .48,
                    right: AmoraSpacing.space16,
                    top: expanded ? 46 : 29,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.surface,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space8),
                        Text(
                          statement,
                          maxLines: expanded ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (expanded
                                      ? AmoraTextStyles.titleLarge
                                      : AmoraTextStyles.titleMedium)
                                  .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileFragment extends StatelessWidget {
  const _ProfileFragment({
    required this.asset,
    required this.size,
    required this.tilt,
  });

  final String asset;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: size,
        height: size * 1.12,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AmoraShadows.level2,
        ),
        child: PremiumAssetImage(
          imageUrl: asset,
          fallbackAsset: AppImages.fallbackProfile,
          initials: 'AM',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          borderRadius: BorderRadius.circular(19),
        ),
      ),
    );
  }
}

class _AccentRing extends StatelessWidget {
  const _AccentRing({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: .2),
          width: 14,
        ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'or continue with'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space12),
          child: Text(
            label,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.textNeutral.withValues(alpha: .62),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class AuthTrustNote extends StatelessWidget {
  const AuthTrustNote({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.all(AmoraSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: .7)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AmoraSpacing.space8),
            Expanded(
              child: Text(
                text,
                style: AmoraTextStyles.bodySmall.copyWith(
                  color: AppColors.textNeutral.withValues(alpha: .72),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthInlineAlert extends StatelessWidget {
  const AuthInlineAlert({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AmoraSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.secondary),
            const SizedBox(width: AmoraSpacing.space8),
            Expanded(
              child: Text(
                message,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One native text input powers the visible OTP cells. The existing page-owned
/// controllers remain synchronized so verification callbacks do not change.
class ResponsiveOtpInput extends StatefulWidget {
  const ResponsiveOtpInput({
    super.key,
    required this.controllers,
    required this.nodes,
    required this.onChanged,
    required this.onPaste,
    this.hasError = false,
    this.enabled = true,
  }) : assert(controllers.length > 0),
       assert(controllers.length == nodes.length);

  final List<TextEditingController> controllers;
  final List<FocusNode> nodes;
  final VoidCallback onChanged;
  final ValueChanged<String> onPaste;
  final bool hasError;
  final bool enabled;

  @override
  State<ResponsiveOtpInput> createState() => _ResponsiveOtpInputState();
}

class _ResponsiveOtpInputState extends State<ResponsiveOtpInput> {
  late final TextEditingController _inputController;
  String _previousValue = '';

  int get _length => widget.controllers.length;
  FocusNode get _focusNode => widget.nodes.first;

  @override
  void initState() {
    super.initState();
    final initial = _externalValue();
    _previousValue = initial;
    _inputController = TextEditingController(text: initial);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant ResponsiveOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes.first != widget.nodes.first) {
      oldWidget.nodes.first.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
    final external = _externalValue();
    if (external != _inputController.text) {
      _inputController.value = TextEditingValue(
        text: external,
        selection: TextSelection.collapsed(offset: external.length),
      );
      _previousValue = external;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _inputController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  String _externalValue() {
    return widget.controllers.map((controller) => controller.text).join();
  }

  void _handleChanged(String value) {
    for (var i = 0; i < _length; i++) {
      final next = i < value.length ? value[i] : '';
      if (widget.controllers[i].text != next) {
        widget.controllers[i].value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    }
    final wasPaste = value.length - _previousValue.length > 1;
    _previousValue = value;
    if (wasPaste) widget.onPaste(value);
    widget.onChanged();
    if (mounted) setState(() {});
  }

  void _focusAt(int index) {
    if (!widget.enabled) return;
    _focusNode.requestFocus();
    final valueLength = _inputController.text.length;
    final offset = math.min(index, valueLength);
    _inputController.selection = index < valueLength
        ? TextSelection(baseOffset: index, extentOffset: index + 1)
        : TextSelection.collapsed(offset: offset);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = _inputController.text;
    final selectionOffset = _inputController.selection.isValid
        ? _inputController.selection.baseOffset
        : value.length;
    final activeIndex = math.min(math.max(selectionOffset, 0), _length - 1);
    return Semantics(
      textField: true,
      label: '$_length digit verification code',
      value: value.isEmpty ? 'Empty' : '${value.length} digits entered',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = constraints.maxWidth < 300 ? 4.0 : 8.0;
          final available = constraints.maxWidth - gap * (_length - 1);
          final cellSize = math.min(56.0, available / _length);
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      key: const ValueKey('otp-native-input'),
                      controller: _inputController,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableSuggestions: false,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_length),
                      ],
                      onChanged: _handleChanged,
                    ),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < _length; index++) ...[
                      _OtpCell(
                        key: ValueKey('otp-cell-$index'),
                        size: cellSize,
                        digit: index < value.length ? value[index] : '',
                        focused: _focusNode.hasFocus && index == activeIndex,
                        hasError: widget.hasError,
                        onTap: () => _focusAt(index),
                      ),
                      if (index != _length - 1) SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    super.key,
    required this.size,
    required this.digit,
    required this.focused,
    required this.hasError,
    required this.onTap,
  });

  final double size;
  final String digit;
  final bool focused;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.secondary
        : focused || digit.isNotEmpty
        ? AppColors.primary
        : AppColors.tertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: AmoraMotion.fast,
        curve: AmoraMotion.curve,
        width: size,
        height: math.max(48, size),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: focused ? 2 : 1.25),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: .14),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          digit,
          style: AmoraTextStyles.titleLarge.copyWith(
            color: AppColors.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
