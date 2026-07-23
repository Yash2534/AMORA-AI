import 'dart:math' as math;

import 'package:amora_ai/core/data/amora_image_data.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:flutter/material.dart';

String formatRupees(num value) => 'Rs ${value.toStringAsFixed(0)}';

void showEventSnack(BuildContext context, String message) {
  showAmoraSnackBar(context, message: message);
}

Route<T> premiumEventRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionDuration: AmoraMotion.standard,
    reverseTransitionDuration: AmoraMotion.fast,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AmoraMotion.curve,
        reverseCurve: AmoraMotion.curve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

String _profileUrlForName(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('yash')) return AmoraImageData.profileYash;
  if (lower.contains('aadhya') || lower.contains('amora')) {
    return AmoraImageData.profileAadhya;
  }
  if (lower.contains('kavya') || lower.contains('velvet')) {
    return AmoraImageData.profileKavya;
  }
  if (lower.contains('aarav') || lower.contains('founder')) {
    return AmoraImageData.profileAarav;
  }
  if (lower.contains('riya') ||
      lower.contains('meera') ||
      lower.contains('sangam')) {
    return AmoraImageData.profileRiya;
  }
  return AmoraImageData.profileAnanya;
}

class PremiumEventButton extends StatelessWidget {
  const PremiumEventButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool compact;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact
          ? AmoraSpacing.compactControlHeight
          : AmoraSpacing.controlHeight,
      child: AppPrimaryButton(
        label: label,
        icon: icon,
        fullWidth: false,
        size: compact ? AmoraButtonSize.compact : AmoraButtonSize.standard,
        variant: outlined
            ? AppPrimaryButtonVariant.outlined
            : AppPrimaryButtonVariant.primary,
        onPressed: onPressed,
      ),
    );
  }
}

class EventImagePanel extends StatelessWidget {
  const EventImagePanel({
    super.key,
    required this.event,
    this.height,
    this.hero = false,
    this.child,
  });

  final EventModel event;
  final double? height;
  final bool hero;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final panel = SizedBox(
      height: height ?? (hero ? null : 178),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: AmoraRadius.card,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumAssetImage(
              imageUrl: event.image.imageUrl,
              fallbackAsset: event.image.assetPath,
              initials: event.image.label.substring(0, 1),
              borderRadius: AmoraRadius.card,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.transparent,
                    AppColors.text.withValues(alpha: .66),
                  ],
                ),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );

    if (!hero) return panel;
    return Hero(tag: 'event-hero-${event.id}', child: panel);
  }
}

class CityChip extends StatelessWidget {
  const CityChip({
    super.key,
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final String city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AmoraSpacing.space8),
      child: AmoraFilterChip(
        label: city,
        selected: selected,
        icon: AmoraIcons.location,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
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
      padding: const EdgeInsets.only(
        right: AmoraSpacing.space8,
        bottom: AmoraSpacing.space8,
      ),
      child: AmoraFilterChip(
        label: label,
        selected: selected,
        onSelected: (_) => onTap(),
        icon: selected ? AmoraIcons.heartFill : null,
      ),
    );
  }
}

class EventBanner extends StatelessWidget {
  const EventBanner({super.key, required this.event, required this.onBook});

  final EventModel event;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return EventImagePanel(
      event: event,
      hero: true,
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SolidEventBadge(
                      icon: AmoraIcons.calendar,
                      text: event.date,
                    ),
                  ),
                ),
                const SizedBox(width: AmoraSpacing.space8),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _SolidEventBadge(
                      text: '${event.seatsLeft} seats left',
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 24,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(16) / 16 > 1.2;
                final details = Text(
                  '${event.city} - ${event.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                );
                final button = PremiumEventButton(
                  label: 'Book Now',
                  icon: Icons.confirmation_number_rounded,
                  compact: true,
                  onPressed: onBook,
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      details,
                      const SizedBox(height: 6),
                      Align(alignment: Alignment.centerRight, child: button),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 12),
                    button,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onOpen,
    required this.onBook,
    this.compact = false,
    this.fillHeight = false,
  });

  final EventModel event;
  final VoidCallback onOpen;
  final VoidCallback onBook;
  final bool compact;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onOpen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: fillHeight ? double.infinity : (compact ? 188 : 268),
        height: fillHeight ? double.infinity : null,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.borderGray),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepWine.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            EventImagePanel(
              event: event,
              height: compact ? 108 : 132,
              child: Padding(
                padding: const EdgeInsets.all(AmoraSpacing.space8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: _SolidEventBadge(text: event.category)),
                        const SizedBox(width: 4),
                        const Spacer(),
                        const Icon(
                          AmoraIcons.verified,
                          color: AppColors.surface,
                          size: AmoraIconSizes.medium,
                        ),
                      ],
                    ),
                    const Spacer(),
                    _SolidEventBadge(
                      icon: AmoraIcons.heartFill,
                      text: '${event.compatibility}%',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            Flexible(
              child: Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.titleMedium.copyWith(
                  color: AppColors.deepWine,
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            _MetaLine(icon: AmoraIcons.location, text: event.city),
            _MetaLine(
              icon: Icons.schedule_rounded,
              text: '${event.date}, ${event.time}',
            ),
            if (fillHeight) const Spacer(),
            const SizedBox(height: AmoraSpacing.space8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRupees(event.price),
                    style: AmoraTextStyles.titleMedium.copyWith(
                      color: AppColors.deepWine,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${event.seatsLeft} left',
                  style: AmoraTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryRose,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmoraSpacing.space8),
            SizedBox(
              width: double.infinity,
              child: PremiumEventButton(
                label: 'Book',
                compact: true,
                icon: AmoraIcons.forward,
                onPressed: onBook,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostCard extends StatelessWidget {
  const HostCard({super.key, required this.host});

  final EventHost host;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: _profileUrlForName(host.name),
            fallbackAsset: host.photoAsset,
            initials: AmoraImageData.initialsForName(host.name),
            radius: 28,
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        host.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.titleMedium.copyWith(
                          color: AppColors.deepWine,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AmoraSpacing.space4),
                    const Icon(
                      AmoraIcons.verified,
                      color: AppColors.primaryPurple,
                      size: AmoraIconSizes.medium,
                    ),
                  ],
                ),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  '${host.rating} rating - ${host.followers} followers',
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Follow host',
            onPressed: () => showEventSnack(context, 'Host followed'),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
    );
  }
}

class AttendeeAvatar extends StatelessWidget {
  const AttendeeAvatar({super.key, required this.attendee});

  final EventAttendee attendee;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PremiumAvatar(
                imageUrl: _profileUrlForName(attendee.name),
                fallbackAsset: attendee.photoAsset,
                initials: AmoraImageData.initialsForName(attendee.name),
                radius: 30,
              ),
              if (attendee.verified)
                const Positioned(
                  right: -1,
                  bottom: -1,
                  child: Icon(
                    Icons.verified_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            attendee.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.deepWine,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            attendee.intent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AgendaTimeline extends StatelessWidget {
  const AgendaTimeline({super.key, required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  items[i].$1,
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRose,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i != items.length - 1)
                    Container(
                      width: 2,
                      height: 34,
                      color: AppColors.lavenderBackground,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    items[i].$2,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class TicketSummaryCard extends StatelessWidget {
  const TicketSummaryCard({
    super.key,
    required this.ticket,
    required this.tax,
    required this.fee,
    required this.discount,
  });

  final int ticket;
  final int tax;
  final int fee;
  final int discount;

  int get grandTotal => math.max(0, ticket + tax + fee - discount);

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price Summary',
            style: TextStyle(
              color: AppColors.deepWine,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          PriceCard(label: 'Ticket', amount: ticket),
          PriceCard(label: 'Tax', amount: tax),
          PriceCard(label: 'Convenience Fee', amount: fee),
          PriceCard(label: 'Discount', amount: -discount),
          const Divider(height: 24),
          PriceCard(label: 'Grand Total', amount: grandTotal, strong: true),
        ],
      ),
    );
  }
}

class PriceCard extends StatelessWidget {
  const PriceCard({
    super.key,
    required this.label,
    required this.amount,
    this.strong = false,
  });

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? AppColors.deepWine : AppColors.textGray,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}${formatRupees(amount.abs())}',
            style: TextStyle(
              color: amount < 0 ? AppColors.successGreen : AppColors.deepWine,
              fontWeight: FontWeight.w900,
              fontSize: strong ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingStepper extends StatelessWidget {
  const BookingStepper({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  final int currentStep;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: i <= currentStep
                        ? AppColors.primaryPurple
                        : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryPurple),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i <= currentStep
                            ? AppColors.surface
                            : AppColors.primaryPurple,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (i != labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 28),
                color: i < currentStep
                    ? AppColors.primaryPurple
                    : AppColors.borderGray,
              ),
            ),
        ],
      ],
    );
  }
}

class QRPassCard extends StatelessWidget {
  const QRPassCard({super.key, required this.ticket});

  final MyEventTicket ticket;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: AppColors.deepWine,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.premiumGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticket.event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PassInfo(label: 'Ticket', value: ticket.ticketNumber),
              ),
              Expanded(
                child: _PassInfo(label: 'Seat', value: ticket.seat),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${ticket.event.date} - ${ticket.event.venue}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: CustomPaint(painter: _QrPassPatternPainter()),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PremiumEventButton(
                  label: 'Download Pass',
                  icon: Icons.download_rounded,
                  compact: true,
                  onPressed: () =>
                      showEventSnack(context, 'Pass download queued'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PremiumEventButton(
                  label: 'Share Pass',
                  icon: Icons.ios_share_rounded,
                  compact: true,
                  outlined: true,
                  onPressed: () => showEventSnack(context, 'Share pass ready'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class EventInfoTile extends StatelessWidget {
  const EventInfoTile({
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
    return _SoftCard(
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Row(
        children: [
          Container(
            width: AmoraSpacing.minimumTouchTarget,
            height: AmoraSpacing.minimumTouchTarget,
            decoration: BoxDecoration(
              color: AppColors.lavenderBackground,
              borderRadius: AmoraRadius.button,
            ),
            child: Icon(icon, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AmoraTextStyles.labelMedium.copyWith(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.titleSmall.copyWith(
                    color: AppColors.deepWine,
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

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = AmoraSpacing.card,
    this.color = AppColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AmoraRadius.card,
        border: Border.all(
          color: color == AppColors.surface ? AppColors.borderGray : color,
        ),
        boxShadow: AmoraShadows.level1,
      ),
      child: child,
    );
  }
}

class _SolidEventBadge extends StatelessWidget {
  const _SolidEventBadge({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space12,
        vertical: AmoraSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.deepWine,
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: AppColors.deepWine),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.surface, size: AmoraIconSizes.small),
            const SizedBox(width: AmoraSpacing.space4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AmoraSpacing.space4),
      child: Row(
        children: [
          Icon(icon, size: AmoraIconSizes.small, color: AppColors.textGray),
          const SizedBox(width: AmoraSpacing.space4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassInfo extends StatelessWidget {
  const _PassInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.surface,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.surface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _QrPassPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.deepWine;
    const cells = 9;
    final cell = size.width / cells;
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final isFinder =
            (x < 3 && y < 3) || (x > 5 && y < 3) || (x < 3 && y > 5);
        final fill = isFinder || ((x * 7 + y * 3) % 5 == 0);
        if (fill) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x * cell + 5, y * cell + 5, cell - 7, cell - 7),
              const Radius.circular(3),
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
