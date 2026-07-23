import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/settings/presentation/widgets/settings_support_widgets.dart';
import 'package:flutter/material.dart';

class SafetyPrivacyScreen extends StatefulWidget {
  const SafetyPrivacyScreen({super.key});

  static const routeName = '/safety-privacy';

  @override
  State<SafetyPrivacyScreen> createState() => _SafetyPrivacyScreenState();
}

class _SafetyPrivacyScreenState extends State<SafetyPrivacyScreen> {
  final List<String> _blockedUsers = ['Rahul, 29', 'Unknown User'];
  var _blurImages = true;
  var _verifiedOnly = false;
  var _autoBlock = true;
  var _hideOnline = false;
  var _incognito = false;
  var _marketingConsent = false;
  var _analyticsConsent = true;
  var _personalizationConsent = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsHeader(
                  title: 'Safety & Privacy',
                  subtitle: 'Your safety comes first at AMORA AI.',
                  icon: Icons.verified_user_rounded,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 18),
                const _TrustBanner(),
                const SizedBox(height: 16),
                const _VerificationCenter(),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  title: 'Safety Center',
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final textScale =
                            MediaQuery.textScalerOf(context).scale(14) / 14;
                        final columns = constraints.maxWidth < 330 ? 1 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: columns,
                          mainAxisExtent: textScale > 1.2 ? 126 : 104,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: [
                            AmoraSafetyCard(
                              icon: Icons.verified_user_rounded,
                              title: 'Verified Profile',
                              subtitle: 'Identity signals',
                              onTap: () => showSettingsSnack(
                                context,
                                'Verified profile controls opened',
                              ),
                            ),
                            AmoraSafetyCard(
                              icon: Icons.photo_camera_rounded,
                              title: 'Photo Verification',
                              subtitle: 'Image checks',
                              onTap: () => showSettingsSnack(
                                context,
                                'Photo verification opened',
                              ),
                            ),
                            AmoraSafetyCard(
                              icon: Icons.face_retouching_natural_rounded,
                              title: 'Face Verification',
                              subtitle: 'Selfie check',
                              onTap: () => showSettingsSnack(
                                context,
                                'Face verification opened',
                              ),
                            ),
                            AmoraSafetyCard(
                              icon: Icons.tips_and_updates_rounded,
                              title: 'Safety Tips',
                              subtitle: 'Dating confidence',
                              onTap: () => showSettingsSnack(
                                context,
                                'Meet in public and keep financial details private',
                              ),
                            ),
                            AmoraSafetyCard(
                              icon: Icons.contact_emergency_rounded,
                              title: 'Emergency Contact',
                              subtitle: 'Trusted person',
                              onTap: () => showSettingsSnack(
                                context,
                                'Emergency contact setup opened',
                              ),
                            ),
                            AmoraSafetyCard(
                              icon: Icons.flag_rounded,
                              title: 'Report User',
                              subtitle: 'Respectful review',
                              onTap: () => showSettingsSnack(
                                context,
                                'Report flow opened',
                              ),
                            ),
                            AmoraSafetyCard(
                              icon: Icons.block_rounded,
                              title: 'Block User',
                              subtitle: '${_blockedUsers.length} blocked',
                              onTap: () => showSettingsSnack(
                                context,
                                'Blocked users list shown below',
                              ),
                            ),
                            AmoraSafetyCard(
                              icon: Icons.groups_rounded,
                              title: 'Community Guidelines',
                              subtitle: 'Shared standards',
                              onTap: () => showSettingsSnack(
                                context,
                                'Community guidelines opened',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  title: 'Blocked Users',
                  children: [
                    if (_blockedUsers.isEmpty)
                      const Text(
                        'No blocked users.',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      for (final user in _blockedUsers)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.lavenderBackground,
                            child: Icon(
                              Icons.person_off_rounded,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                          title: Text(
                            user,
                            style: const TextStyle(
                              color: AppColors.deepWine,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          trailing: AppPrimaryButton(
                            label: 'Unblock',
                            size: AmoraButtonSize.compact,
                            fullWidth: false,
                            variant: AppPrimaryButtonVariant.text,
                            onPressed: () {
                              setState(() => _blockedUsers.remove(user));
                              showSettingsSnack(context, '$user unblocked');
                            },
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 16),
                const SettingsSectionCard(
                  title: 'Report History',
                  subtitle: '2 reports submitted',
                  children: [
                    _ReportRow('Harassment report', 'Reviewed'),
                    _ReportRow('Fake profile report', 'Pending'),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  title: 'Privacy Toggles',
                  children: [
                    PrivacyToggleTile(
                      title: 'Blur sensitive images',
                      subtitle: 'Protect yourself from unexpected media.',
                      value: _blurImages,
                      icon: Icons.blur_on_rounded,
                      onChanged: (value) => setState(() => _blurImages = value),
                    ),
                    PrivacyToggleTile(
                      title: 'Require verified profiles only',
                      subtitle: 'Prioritize verified people in discovery.',
                      value: _verifiedOnly,
                      icon: Icons.verified_rounded,
                      onChanged: (value) =>
                          setState(() => _verifiedOnly = value),
                    ),
                    PrivacyToggleTile(
                      title: 'Hide online status',
                      subtitle: 'Appear offline while browsing.',
                      value: _hideOnline,
                      icon: Icons.visibility_off_rounded,
                      onChanged: (value) => setState(() => _hideOnline = value),
                    ),
                    PrivacyToggleTile(
                      title: 'Incognito',
                      subtitle: 'Only profiles you like can see you.',
                      value: _incognito,
                      icon: Icons.lock_person_rounded,
                      onChanged: (value) => setState(() => _incognito = value),
                    ),
                    PrivacyToggleTile(
                      title: 'Auto-block suspicious messages',
                      subtitle:
                          'Filter risky chat behavior before it reaches you.',
                      value: _autoBlock,
                      icon: Icons.security_rounded,
                      onChanged: (value) => setState(() => _autoBlock = value),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  title: 'Privacy & Data Controls',
                  children: [
                    for (final action in _privacyActions)
                      SettingsTile(
                        icon: action.icon,
                        title: action.title,
                        subtitle: action.subtitle,
                        onTap: () => showSettingsSnack(
                          context,
                          '${action.title} requested',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  title: 'DPDP Act Controls',
                  subtitle: 'Consent and data rights controls.',
                  children: [
                    PrivacyToggleTile(
                      title: 'Personalization consent',
                      subtitle: 'Use profile signals for recommendations.',
                      value: _personalizationConsent,
                      icon: Icons.tune_rounded,
                      onChanged: (value) =>
                          setState(() => _personalizationConsent = value),
                    ),
                    PrivacyToggleTile(
                      title: 'Analytics consent',
                      subtitle: 'Help improve product quality.',
                      value: _analyticsConsent,
                      icon: Icons.analytics_rounded,
                      onChanged: (value) =>
                          setState(() => _analyticsConsent = value),
                    ),
                    PrivacyToggleTile(
                      title: 'Marketing consent',
                      subtitle: 'Receive offers and event promotions.',
                      value: _marketingConsent,
                      icon: Icons.campaign_rounded,
                      onChanged: (value) =>
                          setState(() => _marketingConsent = value),
                    ),
                    for (final action in _dpdpActions)
                      SettingsTile(
                        icon: action.icon,
                        title: action.title,
                        subtitle: action.subtitle,
                        onTap: () => showSettingsSnack(
                          context,
                          '${action.title} opened',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsSectionCard(
                  title: 'Dangerous Zone',
                  subtitle: 'Permanent actions require confirmation.',
                  children: [
                    PremiumDangerButton(
                      label: 'Delete Account',
                      onPressed: _showDeleteDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = controller.text.trim() == 'DELETE';
            return AlertDialog(
              shape: const RoundedRectangleBorder(
                borderRadius: AmoraRadius.dialog,
              ),
              title: const Text('Delete account?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Type DELETE to confirm this permanent request.'),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: controller,
                    label: 'Confirmation',
                    hint: 'DELETE',
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ],
              ),
              actions: [
                AppPrimaryButton(
                  label: 'Cancel',
                  size: AmoraButtonSize.compact,
                  fullWidth: false,
                  variant: AppPrimaryButtonVariant.text,
                  onPressed: () => Navigator.pop(context),
                ),
                AppPrimaryButton(
                  label: 'Delete',
                  size: AmoraButtonSize.compact,
                  fullWidth: false,
                  variant: AppPrimaryButtonVariant.destructive,
                  onPressed: canDelete
                      ? () {
                          Navigator.pop(context);
                          showSettingsSnack(
                            context,
                            'Account deletion request submitted',
                          );
                        }
                      : null,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.lavenderBackground,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: AppColors.successGreen, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verified profiles. Respectful chats. User-controlled privacy.',
              style: TextStyle(
                color: AppColors.deepWine,
                height: 1.35,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCenter extends StatelessWidget {
  const _VerificationCenter();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trust at a glance',
            style: TextStyle(
              color: AppColors.deepWine,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 360
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 20) / 3;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: AmoraSafetyCard(
                      icon: Icons.verified_rounded,
                      title: 'Verified Profile',
                      subtitle: 'Identity signals',
                      onTap: null,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AmoraSafetyCard(
                      icon: Icons.check_circle_rounded,
                      title: 'Checked Photos',
                      subtitle: 'Local trust preview',
                      onTap: null,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: AmoraSafetyCard(
                      icon: Icons.groups_rounded,
                      title: 'Guided Meeting',
                      subtitle: 'Safety guidance',
                      onTap: null,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow(this.title, this.status);

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final reviewed = status == 'Reviewed';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        reviewed ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
        color: reviewed ? AppColors.successGreen : AppColors.warningAmber,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w900,
        ),
      ),
      trailing: Text(
        status,
        style: TextStyle(
          color: reviewed ? AppColors.successGreen : AppColors.warningAmber,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SafetyAction {
  const _SafetyAction(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

const _privacyActions = [
  _SafetyAction(
    'Delete Chat History',
    'Clear all local conversation history.',
    Icons.delete_sweep_rounded,
  ),
  _SafetyAction(
    'Clear Search History',
    'Reset recent discovery searches.',
    Icons.manage_search_rounded,
  ),
  _SafetyAction(
    'Manage Location Access',
    'Control city and distance permissions.',
    Icons.location_on_rounded,
  ),
  _SafetyAction(
    'Hide Profile Temporarily',
    'Pause visibility without deleting.',
    Icons.visibility_off_rounded,
  ),
];

const _dpdpActions = [
  _SafetyAction(
    'Consent Management',
    'Review active data consent choices.',
    Icons.fact_check_rounded,
  ),
  _SafetyAction(
    'Data Correction Request',
    'Ask AMORA to correct account data.',
    Icons.edit_note_rounded,
  ),
  _SafetyAction(
    'Data Portability',
    'Request portable personal data.',
    Icons.drive_file_move_rounded,
  ),
  _SafetyAction(
    'Account Deletion Request',
    'Submit a deletion rights request.',
    Icons.person_remove_rounded,
  ),
];
