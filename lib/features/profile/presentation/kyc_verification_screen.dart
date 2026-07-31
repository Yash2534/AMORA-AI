import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:flutter/material.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({
    super.key,
    this.mediaPicker = const DeviceAmoraMediaPicker(),
  });

  static const routeName = '/kyc';

  final AmoraMediaPicker mediaPicker;

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  String _document = 'Aadhaar';
  String _docStatus = 'Pending';
  String _selfieStatus = 'Pending';
  bool _showResult = false;
  bool _failed = false;
  bool _pickingDocument = false;
  bool _pickingSelfie = false;

  double get _progress {
    var score = 0.0;
    if (_docStatus == 'Selected') score += .38;
    if (_selfieStatus == 'Captured') score += .38;
    if (_showResult && !_failed) score += .24;
    return score.clamp(0, 1);
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

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
                    AmoraSpacing.space32 +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onSkip: _goHome),
                      const SizedBox(height: AmoraSpacing.space20),
                      _Hero(progress: _progress, pulse: _pulse),
                      const SizedBox(height: AmoraSpacing.space16),
                      if (_showResult)
                        _ResultCard(failed: _failed, onRetry: _retry)
                      else ...[
                        _DocumentPicker(
                          selected: _document,
                          onSelected: (value) =>
                              setState(() => _document = value),
                        ),
                        const SizedBox(height: AmoraSpacing.space16),
                        _StatusGrid(
                          document: _document,
                          docStatus: _docStatus,
                          selfieStatus: _selfieStatus,
                          verificationStatus: _progress >= .76
                              ? 'Ready'
                              : 'In Progress',
                        ),
                        const SizedBox(height: AmoraSpacing.space16),
                        _PrivacyNotice(document: _document),
                        const SizedBox(height: AmoraSpacing.space20),
                        AppPrimaryButton(
                          label: _pickingDocument
                              ? 'Loading…'
                              : 'Choose $_document image',
                          icon: Icons.upload_file_rounded,
                          onPressed: _pickingDocument ? null : _pickDocument,
                        ),
                        const SizedBox(height: AmoraSpacing.space12),
                        AppPrimaryButton(
                          label: _pickingSelfie ? 'Loading…' : 'Take a selfie',
                          icon: Icons.camera_alt_rounded,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: _pickingSelfie ? null : _captureSelfie,
                        ),
                        const SizedBox(height: AmoraSpacing.space12),
                        AppPrimaryButton(
                          label: 'Run Face Verification',
                          icon: Icons.face_retouching_natural_rounded,
                          onPressed: _progress >= .76 ? _verify : null,
                        ),
                      ],
                      const SizedBox(height: AmoraSpacing.space12),
                      AppPrimaryButton(
                        label: 'Skip for now',
                        variant: AppPrimaryButtonVariant.text,
                        onPressed: _goHome,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _verify() {
    setState(() {
      _showResult = true;
      _failed = false;
    });
  }

  Future<void> _pickDocument() async {
    setState(() => _pickingDocument = true);
    final result = await widget.mediaPicker.pickImage(
      source: AmoraMediaSource.gallery,
    );
    if (!mounted) return;
    setState(() => _pickingDocument = false);
    if (!result.succeeded) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: widget.mediaPicker,
        onRetry: _pickDocument,
      );
      return;
    }
    setState(() => _docStatus = 'Selected');
  }

  Future<void> _captureSelfie() async {
    setState(() => _pickingSelfie = true);
    final result = await widget.mediaPicker.pickImage(
      source: AmoraMediaSource.camera,
    );
    if (!mounted) return;
    setState(() => _pickingSelfie = false);
    if (!result.succeeded) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: widget.mediaPicker,
        onRetry: _captureSelfie,
      );
      return;
    }
    setState(() => _selfieStatus = 'Captured');
  }

  void _retry() {
    setState(() {
      _showResult = false;
      _failed = false;
      _selfieStatus = 'Pending';
    });
  }

  void _goHome() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(AmoraIcons.back),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Text(
            'Blue Tick Verification',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.deepWine,
            ),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.progress, required this.pulse});

  final double progress;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space24),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + pulse.value * .05,
                child: child,
              );
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.face_retouching_natural_rounded,
                color: AppColors.surface,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Text(
            '${(progress * 100).round()}% verified',
            style: AmoraTextStyles.headlineMedium,
          ),
          const SizedBox(height: AmoraSpacing.space12),
          ClipRRect(
            borderRadius: AmoraRadius.pillBorder,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: AppColors.lavenderBackground,
              color: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPicker extends StatelessWidget {
  const _DocumentPicker({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a document',
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.deepWine,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            children: [
              for (final doc in const [
                'Aadhaar',
                'Driving License',
                'Passport',
              ])
                ChoiceChip(
                  label: Text(doc),
                  selected: selected == doc,
                  onSelected: (_) => onSelected(doc),
                  avatar: Icon(
                    doc == 'Passport'
                        ? Icons.airplane_ticket_rounded
                        : doc == 'Driving License'
                        ? Icons.directions_car_rounded
                        : Icons.badge_rounded,
                    size: 18,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.document,
    required this.docStatus,
    required this.selfieStatus,
    required this.verificationStatus,
  });

  final String document;
  final String docStatus;
  final String selfieStatus;
  final String verificationStatus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            title: document,
            status: docStatus,
            icon: Icons.badge_rounded,
          ),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: _StatusCard(
            title: 'Selfie',
            status: selfieStatus,
            icon: Icons.camera_alt_rounded,
          ),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: _StatusCard(
            title: 'Face AI',
            status: verificationStatus,
            icon: AmoraIcons.verified,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.status,
    required this.icon,
  });

  final String title;
  final String status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.large,
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space8,
        vertical: AmoraSpacing.space16,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryPurple),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.deepWine,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelSmall.copyWith(
              color: AppColors.textGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.document});

  final String document;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      color: AppColors.premiumGold.withValues(alpha: .13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.deepWine),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Text(
              'Your $document image and selfie remain on this device during this verification step.',
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.deepWine,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: failed
                ? AppColors.errorRed
                : AppColors.successGreen,
            child: Icon(
              failed ? Icons.close_rounded : Icons.check_rounded,
              color: AppColors.surface,
              size: 40,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Text(
            failed ? 'Verification needs another try' : 'Verification complete',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.headlineMedium.copyWith(
              color: AppColors.deepWine,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            failed
                ? 'Face clarity was too low. Use even lighting and keep your full face in frame.'
                : 'Your document and selfie checks are complete.',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          AppPrimaryButton(
            label: failed ? 'Try Again' : 'Enter AMORA',
            icon: failed ? Icons.refresh_rounded : Icons.arrow_forward_rounded,
            onPressed: failed
                ? onRetry
                : () {
                    AmoraSession.completeProfileStep(100);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      BrowseGridScreen.routeName,
                      (route) => false,
                    );
                  },
          ),
        ],
      ),
    );
  }
}
