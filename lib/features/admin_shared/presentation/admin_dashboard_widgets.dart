import 'package:amora_ai/core/data/amora_image_data.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_badge.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:flutter/material.dart';

void showDashboardSnack(BuildContext context, String message) {
  showAmoraSnackBar(context, message: message);
}

String _dateSpotImageFor(String name) {
  return ImageRepository.venueByName(name).imageUrl;
}

String _dateSpotAssetFor(String name) {
  return ImageRepository.venueByName(name).fallbackAsset;
}

String _profileImageFor(String name) {
  return ImageRepository.profileByName(name).imageUrl;
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? badge;

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
        Container(
          width: AmoraSpacing.controlHeight,
          height: AmoraSpacing.controlHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: AmoraRadius.card,
          ),
          child: Icon(icon, color: AppColors.surface),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.title.copyWith(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.caption.copyWith(
                  color: AppColors.textGray,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: AmoraBadge.status(
                label: badge!,
                tone: AmoraBadgeTone.success,
              ),
            ),
          ),
      ],
    );
  }
}

class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primaryPurple,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: AmoraSpacing.compactCard,
      radius: AmoraRadius.extraLarge,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.deepWine,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space4),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space8,
        vertical: AmoraSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AmoraTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AmoraTextStyles.titleLarge.copyWith(
            color: AppColors.deepWine,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            subtitle!,
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class EventPerformanceCard extends StatelessWidget {
  const EventPerformanceCard({
    super.key,
    required this.title,
    required this.date,
    required this.city,
    required this.sold,
    required this.capacity,
    required this.revenue,
    required this.status,
    required this.onAttendees,
    required this.onPromote,
    required this.onReport,
  });

  final String title;
  final String date;
  final String city;
  final int sold;
  final int capacity;
  final String revenue;
  final String status;
  final VoidCallback onAttendees;
  final VoidCallback onPromote;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final ratio = sold / capacity;
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumAssetImage(
                imageUrl: ImageRepository.eventByName(title).imageUrl,
                fallbackAsset: ImageRepository.eventByName(title).fallbackAsset,
                initials: title.characters.first.toUpperCase(),
                width: 72,
                height: 62,
                borderRadius: BorderRadius.circular(22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.deepWine,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$date - $city',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StatusChip(label: status, color: _statusColor(status)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('$sold/$capacity tickets sold')),
              Text(
                revenue,
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio.clamp(0, 1),
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
            color: AppColors.primaryRose,
            backgroundColor: AppColors.lavenderBackground,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallAction(label: 'View Attendees', onPressed: onAttendees),
              _SmallAction(label: 'Promote Event', onPressed: onPromote),
              _SmallAction(label: 'Revenue Report', onPressed: onReport),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendeeTile extends StatelessWidget {
  const AttendeeTile({
    super.key,
    required this.name,
    required this.ticket,
    required this.checkedIn,
    required this.onCheckIn,
  });

  final String name;
  final String ticket;
  final bool checkedIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: PremiumAvatar(
        imageUrl: _profileImageFor(name),
        fallbackAsset: AmoraImageData.profileAssetForName(name),
        initials: AmoraImageData.initialsForName(name),
        radius: 22,
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(ticket),
      trailing: checkedIn
          ? const StatusChip(label: 'Checked in', color: AppColors.successGreen)
          : TextButton(
              onPressed: onCheckIn,
              child: const Text('Mark Checked In'),
            ),
    );
  }
}

class AdminActionCard extends StatelessWidget {
  const AdminActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.lavenderBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationQueueCard extends StatelessWidget {
  const VerificationQueueCard({
    super.key,
    required this.name,
    required this.city,
    required this.idType,
    required this.status,
    required this.onApprove,
    required this.onReject,
    required this.onDetails,
  });

  final String name;
  final String city;
  final String idType;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              PremiumAvatar(
                imageUrl: _profileImageFor(name),
                fallbackAsset: AmoraImageData.profileAssetForName(name),
                initials: AmoraImageData.initialsForName(name),
                radius: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.deepWine,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('$city - $idType - Selfie matched'),
                  ],
                ),
              ),
              StatusChip(label: status, color: _statusColor(status)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallAction(label: 'Approve', onPressed: onApprove),
              _SmallAction(label: 'Reject', onPressed: onReject),
              _SmallAction(label: 'View Details', onPressed: onDetails),
            ],
          ),
        ],
      ),
    );
  }
}

class DateSpotCard extends StatelessWidget {
  const DateSpotCard({
    super.key,
    required this.name,
    required this.rating,
    required this.distance,
    required this.price,
    required this.bestFor,
    required this.score,
    required this.packagePrice,
    required this.saved,
    required this.onDetails,
    required this.onBuy,
    required this.onSave,
  });

  final String name;
  final String rating;
  final String distance;
  final String price;
  final String bestFor;
  final int score;
  final String packagePrice;
  final bool saved;
  final VoidCallback onDetails;
  final VoidCallback onBuy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDetails,
      borderRadius: BorderRadius.circular(30),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        radius: 30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.72,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PremiumAssetImage(
                      imageUrl: _dateSpotImageFor(name),
                      fallbackAsset: _dateSpotAssetFor(name),
                      initials: name.substring(0, 1),
                      borderRadius: BorderRadius.zero,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .40),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: StatusChip(
                        label: 'AMORA $score',
                        color: AppColors.premiumGold,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        tooltip: saved ? 'Saved' : 'Save',
                        onPressed: onSave,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primaryRose,
                        ),
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 24,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$rating star - $distance - $price',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best for $bestFor',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const StatusChip(
                        label: 'Safety checked',
                        color: AppColors.successGreen,
                      ),
                      StatusChip(
                        label: packagePrice,
                        color: AppColors.premiumGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Details',
                          icon: Icons.info_outline_rounded,
                          size: AmoraButtonSize.compact,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: onDetails,
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space8),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Reserve',
                          icon: AmoraIcons.events,
                          size: AmoraButtonSize.compact,
                          onPressed: onBuy,
                        ),
                      ),
                    ],
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

class VenueMapPreviewCard extends StatelessWidget {
  const VenueMapPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final venue = ImageRepository.venues[4];
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.surface),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumAssetImage(
              imageUrl: venue.imageUrl,
              fallbackAsset: venue.fallbackAsset,
              initials: 'V',
              borderRadius: BorderRadius.zero,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .38),
              ),
            ),
            const _MapPin(left: 42, top: 52, label: 'Mocha'),
            const _MapPin(left: 210, top: 70, label: 'Makeba'),
            const _MapPin(left: 132, top: 142, label: 'Zen'),
            const Positioned(
              right: 16,
              bottom: 14,
              child: StatusChip(
                label: 'Venue heatmap',
                color: AppColors.premiumGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.category,
    required this.unread,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String message;
  final String category;
  final bool unread;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      color: unread ? AppColors.surface : AppColors.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: unread
                ? AppColors.primaryRose.withValues(alpha: .12)
                : AppColors.borderGray,
            child: Icon(
              _notificationIcon(category),
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.deepWine,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRose,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AppPrimaryButton(
                      label: 'Open',
                      size: AmoraButtonSize.compact,
                      fullWidth: false,
                      variant: AppPrimaryButtonVariant.tonal,
                      onPressed: onTap,
                    ),
                    const SizedBox(width: AmoraSpacing.space8),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: AmoraIconSizes.medium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip({
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
    return Padding(
      padding: const EdgeInsets.only(right: AmoraSpacing.space8),
      child: AmoraFilterChip(
        label: label,
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: label,
      size: AmoraButtonSize.compact,
      fullWidth: false,
      variant: AppPrimaryButtonVariant.tonal,
      onPressed: onPressed,
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.left, required this.top, required this.label});

  final double left;
  final double top;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.primaryRose,
            size: 36,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'Live' || 'Approved' || 'Success' || 'Completed' => AppColors.successGreen,
    'Rejected' || 'Failed' || 'High' => AppColors.errorRed,
    'Pending' || 'Refunded' || 'Medium' => AppColors.warningAmber,
    _ => AppColors.primaryPurple,
  };
}

IconData _notificationIcon(String category) {
  return switch (category) {
    'Matches' => Icons.favorite_rounded,
    'Chats' => Icons.chat_rounded,
    'Events' => Icons.event_rounded,
    'Payments' => Icons.payment_rounded,
    'AI Coach' => Icons.auto_awesome_rounded,
    'Offers' => Icons.local_offer_rounded,
    'Safety' => Icons.verified_user_rounded,
    _ => Icons.notifications_rounded,
  };
}
