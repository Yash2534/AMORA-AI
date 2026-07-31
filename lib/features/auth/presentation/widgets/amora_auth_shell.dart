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
    this.statement,
    this.showComposition = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? footer;
  final String? stepLabel;

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
                final horizontalPadding = viewport.maxWidth < 360
                    ? AmoraSpacing.space16
                    : viewport.maxWidth < 600
                    ? AmoraSpacing.space20
                    : AmoraSpacing.space32;
                final compactHeight = viewport.maxHeight < 700;
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
                        maxWidth: 520,
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
                            ),
                          ),
                          SizedBox(
                            height: compactHeight
                                ? AmoraSpacing.space20
                                : AmoraSpacing.space32,
                          ),
                          AuthReveal(
                            delay: const Duration(milliseconds: 90),
                            child: AuthPageHeader(
                              title: title,
                              subtitle: subtitle,
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space20),
                          AuthReveal(
                            delay: const Duration(milliseconds: 180),
                            child: AuthFormSurface(child: child),
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
  const AuthBrandHeader({super.key, this.onBack, this.stepLabel});

  final VoidCallback? onBack;
  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
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
          width: 34,
          height: 34,
          fit: BoxFit.contain,
          semanticLabel: 'AMORAA icon',
        ),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              AmoraBrandAssets.wordmark,
              height: 19,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              semanticLabel: 'AMORAA',
            ),
          ),
        ),
        if (stepLabel != null) ...[
          const SizedBox(width: AmoraSpacing.space8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space12,
                vertical: AmoraSpacing.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: .88),
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
      ],
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
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              (narrow
                      ? AmoraTextStyles.headlineSmall
                      : AmoraTextStyles.headlineMedium)
                  .copyWith(letterSpacing: -.35),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          subtitle,
          style: AmoraTextStyles.bodyLarge.copyWith(
            color: AppColors.text.withValues(alpha: .72),
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
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(narrow ? 22 : 26),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .78)),
        boxShadow: AmoraShadows.level2,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          narrow ? AmoraSpacing.space16 : AmoraSpacing.space24,
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
