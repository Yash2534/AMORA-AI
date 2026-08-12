import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class ReportFlowScreen extends StatefulWidget {
  const ReportFlowScreen({super.key, this.api, this.arguments});

  static const routeName = '/report-flow';

  final PhaseTwoApiService? api;
  final ReportFlowArgs? arguments;

  @override
  State<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class ReportFlowArgs {
  const ReportFlowArgs({
    required this.targetType,
    required this.targetId,
    required this.title,
    this.imageUrl = '',
    this.fallbackAsset = '',
  });

  factory ReportFlowArgs.profile(DummyProfile profile) => ReportFlowArgs(
    targetType: 'profile',
    targetId: profile.id,
    title: '${profile.name}, ${profile.age}',
    imageUrl: profile.imageUrl,
    fallbackAsset: profile.fallbackAsset,
  );

  final String targetType;
  final String targetId;
  final String title;
  final String imageUrl;
  final String fallbackAsset;
}

class _ReportFlowScreenState extends State<ReportFlowScreen> {
  final _notes = TextEditingController();
  String _reason = 'Fake profile';
  bool _submitted = false;
  bool _submitting = false;
  String? _error;
  ReportFlowArgs? _arguments;
  bool _argumentsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    _argumentsRead = true;
    _arguments = widget.arguments;
    final value = ModalRoute.of(context)?.settings.arguments;
    if (value is ReportFlowArgs) _arguments = value;
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Report a Concern',
        subtitle: 'AMORAA reviews every report with safety-first moderation.',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AmoraSpacing.space16,
                  AmoraSpacing.space20,
                  AmoraSpacing.space20,
                  AmoraSpacing.navigationContentInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_arguments != null)
                        _ProfileSummary(data: _arguments!),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Reason',
                        child: AmoraaSelectField<String>(
                          label: 'Report reason',
                          value: _reason,
                          prefixIcon: Icons.flag_rounded,
                          isRequired: true,
                          options: [
                            for (final reason in _reasons)
                              AmoraaSelectOption(value: reason, label: reason),
                          ],
                          onChanged: (reason) {
                            if (reason != null) {
                              setState(() => _reason = reason);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(
                                color: AppColors.deepWine,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notes,
                              minLines: 4,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText:
                                    'Add context for the safety moderation team',
                                prefixIcon: Icon(Icons.edit_note_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                      ],
                      AppPrimaryButton(
                        label: _submitted
                            ? 'Report Submitted'
                            : 'Submit Report',
                        icon: Icons.shield_rounded,
                        isLoading: _submitting,
                        onPressed: _submitted || _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final target = _arguments;
    final api = widget.api;
    if (target == null || api == null) {
      setState(() => _error = 'Choose a profile or item to report first.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await api.report(
        targetType: target.targetType,
        targetUserId: target.targetType == 'profile' ? target.targetId : null,
        targetId: target.targetType == 'profile' ? null : target.targetId,
        reason: _reasonCodes[_reason]!,
        notes: _notes.text,
      );
      if (!mounted) return;
      setState(() => _submitted = true);
      showAmoraDialog<void>(
        context: context,
        title: 'Report submitted',
        message: 'Thanks for helping keep AMORAA respectful.',
        icon: AmoraIcons.check,
        primaryLabel: 'Done',
        onPrimary: () => Navigator.pop(context),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn\'t submit the report.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.data});

  final ReportFlowArgs data;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: data.imageUrl,
            fallbackAsset: data.fallbackAsset,
            initials: data.title.isEmpty ? '?' : data.title[0],
            radius: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Safety team context preview',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w700,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.deepWine,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

const _reasons = [
  'Fake profile',
  'Harassment',
  'Inappropriate photo',
  'Scam',
  'Spam',
  'Other',
];

const _reasonCodes = <String, String>{
  'Fake profile': 'fake_profile',
  'Harassment': 'harassment',
  'Inappropriate photo': 'inappropriate_photo',
  'Scam': 'scam',
  'Spam': 'spam',
  'Other': 'other',
};
