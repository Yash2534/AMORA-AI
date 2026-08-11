import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/features/legal/presentation/community_guidelines_screen.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';

/// The existing Safety Center route.
///
/// Only state with a live project source is rendered as account data. Features
/// without shared state are presented as unavailable and never as configured,
/// active, or complete.
class SafetyPrivacyScreen extends StatelessWidget {
  const SafetyPrivacyScreen({super.key, this.relationshipController});

  static const routeName = '/safety-center';
  static const legacyRouteName = '/safety-privacy';

  final ProfileRelationshipController? relationshipController;

  @override
  Widget build(BuildContext context) {
    final relationships =
        relationshipController ?? ProfileRelationshipController.instance;

    return AnimatedBuilder(
      animation: relationships,
      builder: (context, _) {
        final blockedCount = relationships.blockedProfileIds.length;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ResponsiveMobileFrame(
              maxWidth: 760,
              child: CustomScrollView(
                slivers: [
                  AmoraSliverAppBar(
                    title: 'Safety Center',
                    subtitle: 'Tools and guidance for dating with confidence',
                    onBack: () => Navigator.of(context).maybePop(),
                    maxContentWidth: 760,
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      AmoraSpacing.space20,
                      AmoraSpacing.space16,
                      AmoraSpacing.space20,
                      AmoraSpacing.space40 +
                          MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _SafetyOverview(blockedCount: blockedCount),
                        const SizedBox(height: AmoraSpacing.space24),
                        const _SafetySection(
                          title: 'Privacy & visibility',
                          child: _UnavailableStateCard(
                            key: ValueKey('safety-privacy-unavailable'),
                            icon: Icons.visibility_off_outlined,
                            title: 'Privacy controls unavailable',
                            message:
                                'No account-level visibility settings are connected to this page, so no privacy state is shown.',
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space24),
                        _SafetySection(
                          title: 'Block & report',
                          supportingText:
                              'Blocked profiles are private and reflect actions from this session.',
                          child: _SafetyActionGroup(
                            children: [
                              _SafetyActionRow(
                                key: const ValueKey('safety-blocked-profiles'),
                                icon: Icons.block_rounded,
                                title: 'Blocked Profiles',
                                description: 'Manage people you have blocked.',
                                status: '$blockedCount blocked',
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(BlockedProfilesScreen.routeName),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space24),
                        const _SafetySection(
                          title: 'Emergency & check-in',
                          child: _UnavailableStateCard(
                            key: ValueKey('safety-emergency-unavailable'),
                            icon: Icons.emergency_outlined,
                            title: 'Emergency tools unavailable',
                            message:
                                'No working emergency-contact or check-in service is connected. If you are in immediate danger, contact local emergency services.',
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space24),
                        const _SafetySection(
                          title: 'Dating safety guidance',
                          supportingText:
                              'Practical guidance from AMORAA community standards.',
                          child: _SafetyGuidanceCard(),
                        ),
                        const SizedBox(height: AmoraSpacing.space24),
                        _SafetySection(
                          title: 'Support',
                          child: _SafetyActionGroup(
                            children: [
                              _SafetyActionRow(
                                key: const ValueKey(
                                  'safety-community-guidelines',
                                ),
                                icon: Icons.gavel_rounded,
                                title: 'Community Guidelines',
                                description:
                                    'Review AMORAA standards for respectful and safe behavior.',
                                onTap: () => Navigator.of(context).pushNamed(
                                  CommunityGuidelinesScreen.routeName,
                                ),
                              ),
                              _SafetyActionRow(
                                key: const ValueKey('safety-support'),
                                icon: Icons.support_agent_rounded,
                                title: 'Safety Help',
                                description:
                                    'Open help topics or contact AMORAA support by email.',
                                onTap: () => Navigator.of(
                                  context,
                                ).pushNamed(FaqSupportScreen.routeName),
                              ),
                            ],
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
      },
    );
  }
}

class _SafetyOverview extends StatelessWidget {
  const _SafetyOverview({required this.blockedCount});

  final int blockedCount;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      key: const ValueKey('safety-overview'),
      radius: AmoraRadius.hero,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SafetyIcon(
                icon: Icons.health_and_safety_rounded,
                size: 56,
              ),
              const SizedBox(width: AmoraSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your safety, clearly presented',
                      style: AmoraTextStyles.titleLarge,
                    ),
                    const SizedBox(height: AmoraSpacing.space4),
                    Text(
                      'Only current account data and working destinations appear here.',
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space20),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 520
                  ? (constraints.maxWidth - AmoraSpacing.space12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AmoraSpacing.space12,
                runSpacing: AmoraSpacing.space12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: const _OverviewStatus(
                      icon: Icons.verified_user_outlined,
                      label: 'Identity status',
                      value: 'Unavailable',
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _OverviewStatus(
                      key: const ValueKey('safety-blocked-count'),
                      icon: Icons.block_rounded,
                      label: 'Blocked profiles',
                      value: '$blockedCount',
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

class _OverviewStatus extends StatelessWidget {
  const _OverviewStatus({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(AmoraSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AmoraRadius.large),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AmoraTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AmoraTextStyles.titleSmall.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetySection extends StatelessWidget {
  const _SafetySection({
    required this.title,
    required this.child,
    this.supportingText,
  });

  final String title;
  final String? supportingText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AmoraTextStyles.sectionTitle),
        if (supportingText != null) ...[
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            supportingText!,
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AmoraSpacing.space12),
        child,
      ],
    );
  }
}

class _SafetyActionGroup extends StatelessWidget {
  const _SafetyActionGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      shadowOpacity: .04,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(height: 1, color: AppColors.tertiary),
          ],
        ],
      ),
    );
  }
}

class _SafetyActionRow extends StatelessWidget {
  const _SafetyActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.status,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = [title, ?status, description].join('. ');
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: Padding(
            padding: const EdgeInsets.all(AmoraSpacing.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SafetyIcon(icon: icon),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AmoraTextStyles.titleMedium),
                      if (status != null) ...[
                        const SizedBox(height: AmoraSpacing.space8),
                        _StatusChip(label: status!),
                      ],
                      const SizedBox(height: AmoraSpacing.space4),
                      Text(
                        description,
                        style: AmoraTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AmoraSpacing.space8),
                const Padding(
                  padding: EdgeInsets.only(top: AmoraSpacing.space12),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.text,
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

class _UnavailableStateCard extends StatelessWidget {
  const _UnavailableStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. Unavailable. $message',
      child: PremiumCard(
        shadowOpacity: .03,
        padding: const EdgeInsets.all(AmoraSpacing.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SafetyIcon(icon: icon),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AmoraTextStyles.titleMedium),
                  const SizedBox(height: AmoraSpacing.space8),
                  const _StatusChip(label: 'Unavailable'),
                  const SizedBox(height: AmoraSpacing.space8),
                  Text(
                    message,
                    style: AmoraTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyGuidanceCard extends StatelessWidget {
  const _SafetyGuidanceCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      shadowOpacity: .03,
      child: Column(
        children: [
          for (var index = 0; index < _guidance.length; index++) ...[
            _GuidanceTile(item: _guidance[index]),
            if (index != _guidance.length - 1)
              const Divider(height: 1, color: AppColors.tertiary),
          ],
          const Divider(height: 1, color: AppColors.tertiary),
          Padding(
            padding: const EdgeInsets.all(AmoraSpacing.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Text(
                    'AMORAA provides safety tools and guidance, but users should always use their own judgment when meeting someone.',
                    style: AmoraTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _GuidanceTile extends StatelessWidget {
  const _GuidanceTile({required this.item});

  final _GuidanceItem item;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        key: ValueKey('safety-guidance-${item.id}'),
        leading: Icon(item.icon, color: AppColors.primary),
        title: Text(item.title, style: AmoraTextStyles.titleSmall),
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.text,
        childrenPadding: const EdgeInsets.fromLTRB(
          AmoraSpacing.space16,
          0,
          AmoraSpacing.space16,
          AmoraSpacing.space16,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(item.description, style: AmoraTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SafetyIcon extends StatelessWidget {
  const _SafetyIcon({required this.icon, this.size = 48});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AmoraRadius.large),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Icon(icon, color: AppColors.primary, size: size * .46),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space8,
        vertical: AmoraSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: .45),
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Text(
        label,
        style: AmoraTextStyles.badge.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _GuidanceItem {
  const _GuidanceItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
  });

  final String id;
  final IconData icon;
  final String title;
  final String description;
}

const _guidance = <_GuidanceItem>[
  _GuidanceItem(
    id: 'privacy',
    icon: Icons.lock_outline_rounded,
    title: 'Protect personal information',
    description:
        'Do not share account credentials, financial details, or intimate content under pressure.',
  ),
  _GuidanceItem(
    id: 'boundaries',
    icon: Icons.front_hand_outlined,
    title: 'Respect boundaries',
    description:
        'Move at a pace that feels comfortable and stop contact when another member asks you to.',
  ),
  _GuidanceItem(
    id: 'concerns',
    icon: Icons.report_outlined,
    title: 'Respond to safety concerns',
    description:
        'Block a profile when needed. For urgent danger, contact local emergency services.',
  ),
];
