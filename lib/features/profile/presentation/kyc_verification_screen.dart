import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/amoraa_adaptive_image.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:flutter/material.dart';

enum _KycStage { aadhaar, selfie, processing, complete }

typedef KycVerificationSubmitter =
    Future<bool> Function({
      required AmoraPickedMedia aadhaar,
      required AmoraPickedMedia selfie,
    });

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({
    super.key,
    this.mediaPicker = const DeviceAmoraMediaPicker(),
    this.verifyIdentity,
  });

  static const routeName = '/kyc';

  final AmoraMediaPicker mediaPicker;
  final KycVerificationSubmitter? verifyIdentity;

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  _KycStage _stage = _KycStage.aadhaar;
  bool _busy = false;
  AmoraPickedMedia? _aadhaar;
  AmoraPickedMedia? _selfie;
  String? _verificationError;

  double get _progress => switch (_stage) {
    _KycStage.aadhaar => .25,
    _KycStage.selfie => .5,
    _KycStage.processing => .75,
    _KycStage.complete => 1,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space12,
                  AmoraSpacing.space20,
                  AmoraSpacing.space32 +
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
                sliver: SliverList.list(
                  children: [
                    _KycHeader(
                      onBack: () => Navigator.of(context).maybePop(),
                      onSkip: _goHome,
                    ),
                    const SizedBox(height: AmoraSpacing.space20),
                    _KycHero(progress: _progress, stage: _stage),
                    const SizedBox(height: AmoraSpacing.space16),
                    _VerificationTimeline(stage: _stage),
                    const SizedBox(height: AmoraSpacing.space16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _buildStageCard(),
                    ),
                    if (_stage != _KycStage.complete) ...[
                      const SizedBox(height: AmoraSpacing.space16),
                      const _PrivacyNotice(),
                    ],
                    const SizedBox(height: AmoraSpacing.space12),
                    if (_stage != _KycStage.complete)
                      AppPrimaryButton(
                        label: 'Skip for now',
                        variant: AppPrimaryButtonVariant.text,
                        onPressed: _busy ? null : _goHome,
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

  Widget _buildStageCard() {
    return switch (_stage) {
      _KycStage.aadhaar => _KycActionCard(
        key: const ValueKey('kyc-aadhaar'),
        step: 'Step 1',
        icon: Icons.badge_outlined,
        title: 'Upload Aadhaar',
        description:
            'Choose a clear image with all four corners visible. Your details '
            'are used only for this identity check.',
        illustration: const _DocumentIllustration(),
        buttonLabel: _busy ? 'Opening gallery…' : 'Choose Aadhaar image',
        buttonIcon: Icons.upload_file_rounded,
        busy: _busy,
        onPressed: _pickAadhaar,
      ),
      _KycStage.selfie => _KycActionCard(
        key: const ValueKey('kyc-selfie'),
        step: 'Step 2',
        icon: Icons.face_rounded,
        title: 'Take a selfie',
        description:
            'Use even lighting, remove face coverings, and look directly at '
            'the camera for a quick liveness match.',
        illustration: const _SelfieIllustration(),
        buttonLabel: _busy ? 'Opening camera…' : 'Take verification selfie',
        buttonIcon: Icons.camera_alt_rounded,
        busy: _busy,
        onPressed: _captureSelfie,
        supportingContent: _aadhaar == null
            ? null
            : _KycMediaPreview(
                media: _aadhaar!,
                label: 'Aadhaar selected',
                actionLabel: 'Replace',
                onAction: _busy ? null : _replaceAadhaar,
              ),
      ),
      _KycStage.processing => _ProcessingCard(
        key: const ValueKey('kyc-processing'),
        busy: _busy,
        aadhaar: _aadhaar!,
        selfie: _selfie!,
        error: _verificationError,
        onReplaceAadhaar: _busy ? null : _replaceAadhaar,
        onRetakeSelfie: _busy ? null : _retakeSelfie,
        onVerify: _runVerification,
      ),
      _KycStage.complete => _CompletionCard(
        key: const ValueKey('kyc-complete'),
        onContinue: _complete,
      ),
    };
  }

  Future<void> _pickAadhaar() async {
    setState(() => _busy = true);
    final result = await widget.mediaPicker.pickImage(
      source: AmoraMediaSource.gallery,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.succeeded) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: widget.mediaPicker,
        onRetry: _pickAadhaar,
      );
      return;
    }
    setState(() {
      _aadhaar = result.media;
      _verificationError = null;
      _stage = _KycStage.selfie;
    });
  }

  Future<void> _captureSelfie() async {
    setState(() => _busy = true);
    final result = await widget.mediaPicker.pickImage(
      source: AmoraMediaSource.camera,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.succeeded) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: widget.mediaPicker,
        onRetry: _captureSelfie,
      );
      return;
    }
    setState(() {
      _selfie = result.media;
      _verificationError = null;
      _stage = _KycStage.processing;
    });
  }

  Future<void> _runVerification() async {
    final verify = widget.verifyIdentity;
    final aadhaar = _aadhaar;
    final selfie = _selfie;
    if (verify == null || aadhaar == null || selfie == null) {
      setState(() {
        _verificationError =
            'Secure verification is temporarily unavailable. Your images '
            'remain on this device and have not been submitted.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _verificationError = null;
    });
    try {
      final verified = await verify(aadhaar: aadhaar, selfie: selfie);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (verified) {
          _stage = _KycStage.complete;
        } else {
          _verificationError =
              'We could not verify these images. Replace either image and '
              'try again.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _verificationError =
            'Verification could not be completed. Check your connection and '
            'try again.';
      });
    }
  }

  void _replaceAadhaar() {
    setState(() {
      _aadhaar = null;
      _selfie = null;
      _verificationError = null;
      _stage = _KycStage.aadhaar;
    });
  }

  void _retakeSelfie() {
    setState(() {
      _selfie = null;
      _verificationError = null;
      _stage = _KycStage.selfie;
    });
  }

  void _complete() {
    AmoraSession.completeProfileStep(100);
    _goHome();
  }

  void _goHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false);
  }
}

class _KycHeader extends StatelessWidget {
  const _KycHeader({required this.onBack, required this.onSkip});

  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AmoraHeaderBackButton(onPressed: onBack),
        const SizedBox(width: AmoraSpacing.space8),
        const Expanded(
          child: AmoraScreenTitle(
            title: 'Identity Verification',
            subtitle: 'Secure, guided, and private',
          ),
        ),
        AppPrimaryButton(
          label: 'Skip',
          variant: AppPrimaryButtonVariant.text,
          size: AmoraButtonSize.compact,
          fullWidth: false,
          onPressed: onSkip,
        ),
      ],
    );
  }
}

class _KycHero extends StatelessWidget {
  const _KycHero({required this.progress, required this.stage});

  final double progress;
  final _KycStage stage;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space24),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 80,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.tertiary,
                      color: stage == _KycStage.complete
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                  Icon(
                    stage == _KycStage.complete
                        ? Icons.verified_rounded
                        : Icons.shield_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: AmoraSpacing.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$percent% complete',
                  style: AmoraTextStyles.headlineSmall,
                ),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  stage == _KycStage.complete
                      ? 'Your identity check is complete.'
                      : 'Complete each secure check in order.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationTimeline extends StatelessWidget {
  const _VerificationTimeline({required this.stage});

  final _KycStage stage;

  @override
  Widget build(BuildContext context) {
    final current = _KycStage.values.indexOf(stage);
    const items = [
      ('Aadhaar', Icons.badge_outlined),
      ('Selfie', Icons.face_rounded),
      ('Processing', Icons.security_rounded),
      ('Verified', Icons.verified_rounded),
    ];
    return PremiumCard(
      radius: AmoraRadius.large,
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Stack(
        children: [
          const Positioned(
            left: 29,
            top: 28,
            bottom: 28,
            child: VerticalDivider(
              width: 2,
              thickness: 2,
              color: AppColors.divider,
            ),
          ),
          Positioned(
            left: 29,
            top: 28,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 2,
              height: 56.0 * current.clamp(0, items.length - 1),
              color: AppColors.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < items.length; index++)
                _TimelineItem(
                  title: items[index].$1,
                  icon: items[index].$2,
                  active: index == current,
                  complete: index < current || stage == _KycStage.complete,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.icon,
    required this.active,
    required this.complete,
  });

  final String title;
  final IconData icon;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space12),
      decoration: BoxDecoration(
        color: active ? AppColors.tertiary : AppColors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: complete || active
                ? AppColors.primary
                : AppColors.background,
            child: Icon(
              complete ? Icons.check_rounded : icon,
              color: complete || active
                  ? AppColors.surface
                  : AppColors.textMuted,
              size: 19,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.titleMedium.copyWith(
                color: active || complete
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ),
          Text(
            complete
                ? 'Complete'
                : active
                ? 'Current'
                : 'Upcoming',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelSmall.copyWith(
              color: active || complete
                  ? AppColors.primary
                  : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _KycActionCard extends StatelessWidget {
  const _KycActionCard({
    super.key,
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
    required this.illustration,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.busy,
    required this.onPressed,
    this.supportingContent,
  });

  final String step;
  final IconData icon;
  final String title;
  final String description;
  final Widget illustration;
  final String buttonLabel;
  final IconData buttonIcon;
  final bool busy;
  final VoidCallback onPressed;
  final Widget? supportingContent;

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
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AmoraSpacing.space8),
              Text(
                step,
                style: AmoraTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space16),
          illustration,
          if (supportingContent case final content?) ...[
            const SizedBox(height: AmoraSpacing.space16),
            content,
          ],
          const SizedBox(height: AmoraSpacing.space16),
          Text(title, style: AmoraTextStyles.headlineSmall),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            description,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          AppPrimaryButton(
            label: buttonLabel,
            icon: buttonIcon,
            isLoading: busy,
            onPressed: busy ? null : onPressed,
          ),
        ],
      ),
    );
  }
}

class _DocumentIllustration extends StatelessWidget {
  const _DocumentIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.background, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 178,
        height: 100,
        padding: const EdgeInsets.all(AmoraSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.tertiary,
              child: Icon(Icons.person_rounded, color: AppColors.primary),
            ),
            SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IllustrationLine(width: 88),
                  SizedBox(height: 8),
                  _IllustrationLine(width: 62),
                  SizedBox(height: 8),
                  _IllustrationLine(width: 74),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelfieIllustration extends StatelessWidget {
  const _SelfieIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 92,
            height: 112,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(42),
            ),
          ),
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.face_rounded, size: 44, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _IllustrationLine extends StatelessWidget {
  const _IllustrationLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard({
    super.key,
    required this.busy,
    required this.aadhaar,
    required this.selfie,
    required this.error,
    required this.onReplaceAadhaar,
    required this.onRetakeSelfie,
    required this.onVerify,
  });

  final bool busy;
  final AmoraPickedMedia aadhaar;
  final AmoraPickedMedia selfie;
  final String? error;
  final VoidCallback? onReplaceAadhaar;
  final VoidCallback? onRetakeSelfie;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space24),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 84,
            child: busy
                ? const CircularProgressIndicator(
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                  )
                : const Icon(
                    Icons.security_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          Text(
            busy ? 'Verification processing' : 'Ready for secure verification',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.headlineSmall,
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Row(
            children: [
              Expanded(
                child: _KycMediaPreview(
                  media: aadhaar,
                  label: 'Aadhaar',
                  actionLabel: 'Replace',
                  onAction: onReplaceAadhaar,
                ),
              ),
              const SizedBox(width: AmoraSpacing.space12),
              Expanded(
                child: _KycMediaPreview(
                  media: selfie,
                  label: 'Selfie',
                  actionLabel: 'Retake',
                  onAction: onRetakeSelfie,
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: AmoraSpacing.space16),
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AmoraSpacing.space12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: .28),
                  ),
                ),
                child: Text(
                  error!,
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            busy
                ? 'Matching your selfie with the uploaded identity document.'
                : 'Your Aadhaar image and selfie are ready for the final check.',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          AppPrimaryButton(
            label: busy ? 'Checking identity…' : 'Start verification',
            icon: Icons.verified_user_outlined,
            isLoading: busy,
            onPressed: busy ? null : onVerify,
          ),
        ],
      ),
    );
  }
}

class _KycMediaPreview extends StatelessWidget {
  const _KycMediaPreview({
    required this.media,
    required this.label,
    required this.actionLabel,
    required this.onAction,
  });

  final AmoraPickedMedia media;
  final String label;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label preview',
      child: Container(
        padding: const EdgeInsets.all(AmoraSpacing.space8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmoraaAdaptiveImage(
              source: media.dataUri,
              aspectMode: AmoraaImageAspectMode.adaptive,
              originalAspectRatio: 4 / 3,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(12),
              semanticLabel: '$label preview image',
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelMedium,
            ),
            AppPrimaryButton(
              label: actionLabel,
              variant: AppPrimaryButtonVariant.text,
              size: AmoraButtonSize.compact,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space24),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .75, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: .28),
                    blurRadius: 28,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.surface,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          Text('Verification complete', style: AmoraTextStyles.headlineMedium),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            'Your identity check is complete and your verified trust signal is '
            'ready to appear across AMORAA.',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          AppPrimaryButton(
            label: 'Continue to AMORAA',
            icon: Icons.arrow_forward_rounded,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.large,
      color: AppColors.premiumGold.withValues(alpha: .12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.primary),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Text(
              'Your document and selfie are handled only for identity '
              'verification and are never displayed on your profile.',
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
