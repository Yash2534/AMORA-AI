import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AmoraAuthShell extends StatelessWidget {
  const AmoraAuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.footer,
    this.stepLabel,
    this.alignStepLabelRight = false,
    this.stepLabelKey,
    this.statement,
    this.showComposition = false,
    this.compactLayout = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final String? stepLabel;
  final bool alignStepLabelRight;
  final Key? stepLabelKey;
  final bool compactLayout;

  // Retained for source compatibility with existing auth routes.
  final String? statement;
  final bool showComposition;

  @override
  Widget build(BuildContext context) {
    final view = MediaQuery.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthAmbientBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, viewport) {
                final horizontalPadding = compactLayout &&
                        viewport.maxWidth < 320
                    ? AmoraSpacing.space12
                    : viewport.maxWidth < 360
                    ? AmoraSpacing.space16
                    : viewport.maxWidth < 600
                    ? AmoraSpacing.space20
                    : AmoraSpacing.space32;
                final compactHeight = viewport.maxHeight < 700;
                final contentMaxWidth = compactLayout ? 440.0 : 520.0;
                return SingleChildScrollView(
                  key: PageStorageKey<String>(
                    'auth-scroll-${ModalRoute.of(context)?.settings.name ?? title}',
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compactHeight ? AmoraSpacing.space8 : AmoraSpacing.space16,
                    horizontalPadding,
                    AmoraSpacing.space24 + view.viewInsets.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: contentMaxWidth,
                        minHeight:
                            viewport.maxHeight -
                            view.padding.vertical -
                            (compactHeight ? 40 : 56),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthReveal(
                            child: AuthBrandHeader(
                              onBack: onBack,
                              stepLabel: stepLabel,
                              alignStepLabelRight: alignStepLabelRight,
                              stepLabelKey: stepLabelKey,
                              compact: compactLayout,
                            ),
                          ),
                          SizedBox(
                            height: compactHeight
                                ? AmoraSpacing.space20
                                : compactLayout
                                ? 28
                                : AmoraSpacing.space32,
                          ),
                          AuthReveal(
                            delay: const Duration(milliseconds: 90),
                            child: AuthPageHeader(
                              title: title,
                              subtitle: subtitle,
                              compact: compactLayout,
                            ),
                          ),
                          SizedBox(
                            height: compactLayout
                                ? AmoraSpacing.space16
                                : AmoraSpacing.space20,
                          ),
                          AuthReveal(
                            delay: const Duration(milliseconds: 180),
                            child: AuthFormSurface(
                              compact: compactLayout,
                              child: child,
                            ),
                          ),
                          if (footer != null) ...[
                            const SizedBox(height: AmoraSpacing.space20),
                            AuthReveal(
                              delay: const Duration(milliseconds: 260),
                              child: footer!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthAmbientBackground extends StatelessWidget {
  const _AuthAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            const ColoredBox(color: AppColors.background),
            Positioned(
              right: -170,
              top: -210,
              child: Opacity(
                opacity: .12,
                child: Container(
                  width: 430,
                  height: 430,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary,
                        AppColors.tertiary,
                        AppColors.primary,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -220,
              bottom: -300,
              child: Opacity(
                opacity: .72,
                child: Container(
                  width: 480,
                  height: 480,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [AppColors.background, AppColors.surface],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    this.onBack,
    this.stepLabel,
    this.alignStepLabelRight = false,
    this.stepLabelKey,
    this.compact = false,
  });

  final VoidCallback? onBack;
  final String? stepLabel;
  final bool alignStepLabelRight;
  final Key? stepLabelKey;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final stepBadge = stepLabel == null
        ? null
        : Container(
            key: stepLabelKey,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : AmoraSpacing.space12,
              vertical: compact ? 7 : AmoraSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: .88),
              borderRadius: AmoraRadius.pillBorder,
              border: Border.all(color: AppColors.tertiary),
            ),
            child: compact
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      stepLabel!,
                      maxLines: 1,
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontSize: 11.5,
                        letterSpacing: .15,
                      ),
                    ),
                  )
                : Text(
                    stepLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
          );
    if (compact && onBack == null && stepBadge != null) {
      return Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Image.asset(
                  AmoraBrandAssets.icon,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  semanticLabel: 'AMORAA icon',
                ),
                const SizedBox(width: AmoraSpacing.space8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      AmoraBrandAssets.wordmark,
                      height: 16.5,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      semanticLabel: 'AMORAA',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AmoraSpacing.space8),
          Flexible(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: stepBadge,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        if (onBack != null) ...[
          Semantics(
            button: true,
            label: 'Go back',
            child: SizedBox.square(
              dimension: AmoraSpacing.minimumTouchTarget,
              child: IconButton.outlined(
                tooltip: 'Back',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface.withValues(alpha: .82),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.tertiary),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
          const SizedBox(width: AmoraSpacing.space12),
        ],
        Image.asset(
          AmoraBrandAssets.icon,
          width: compact ? 32 : 34,
          height: compact ? 32 : 34,
          fit: BoxFit.contain,
          semanticLabel: 'AMORAA icon',
        ),
        const SizedBox(width: AmoraSpacing.space8),
        if (alignStepLabelRight && stepLabel != null) ...[
          Image.asset(
            AmoraBrandAssets.wordmark,
            height: compact ? 16.5 : 19,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            semanticLabel: 'AMORAA',
          ),
          const Spacer(),
        ] else
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                AmoraBrandAssets.wordmark,
                height: compact ? 16.5 : 19,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                semanticLabel: 'AMORAA',
              ),
            ),
          ),
        if (stepBadge != null) ...[
          const SizedBox(width: AmoraSpacing.space8),
          if (alignStepLabelRight && compact)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: stepBadge,
            )
          else
            Flexible(child: stepBadge),
        ],
      ],
    );
  }
}

class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final veryNarrow = screenWidth < 320;
    final narrow = screenWidth < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compact
              ? (narrow
                        ? AmoraTextStyles.headlineSmall
                        : AmoraTextStyles.headlineMedium)
                    .copyWith(
                      fontSize: narrow ? 24 : 26,
                      height: 1.18,
                      letterSpacing: -.45,
                    )
              : (narrow
                        ? AmoraTextStyles.headlineSmall
                        : AmoraTextStyles.headlineMedium)
                    .copyWith(letterSpacing: -.35),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          subtitle,
          style: AmoraTextStyles.bodyLarge.copyWith(
            color: AppColors.text.withValues(alpha: compact ? .68 : .72),
            fontSize: compact ? 15 : null,
            height: compact ? 1.45 : null,
            letterSpacing: compact ? .05 : null,
          ),
        ),
      ],
    );
  }
}

class AuthFormSurface extends StatelessWidget {
  const AuthFormSurface({super.key, required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(
          compact
              ? (veryNarrow ? 18 : narrow ? 20 : 24)
              : (narrow ? 22 : 26),
        ),
        border: Border.all(
          color: AppColors.tertiary.withValues(alpha: compact ? .64 : .78),
        ),
        boxShadow: compact ? AmoraShadows.level1 : AmoraShadows.level2,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          compact && veryNarrow
              ? AmoraSpacing.space12
              : narrow
              ? AmoraSpacing.space16
              : compact
              ? AmoraSpacing.space20
              : AmoraSpacing.space24,
        ),
        child: child,
      ),
    );
  }
}

class AuthReveal extends StatelessWidget {
  const AuthReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    const duration = Duration(milliseconds: 360);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      builder: (context, value, staticChild) {
        final milliseconds = duration.inMilliseconds.toDouble();
        final progress =
            ((value * (duration + delay).inMilliseconds -
                        delay.inMilliseconds) /
                    milliseconds)
                .clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progress)),
            child: staticChild,
          ),
        );
      },
      child: child,
    );
  }
}
