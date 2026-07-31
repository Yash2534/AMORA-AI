import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileSettingsGroup extends StatelessWidget {
  const ProfileSettingsGroup({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AmoraSpacing.space4),
          child: Text(
            label.toUpperCase(),
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.1,
            ),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Material(
          color: AppColors.surface,
          borderRadius: AmoraRadius.card,
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AmoraRadius.card,
              border: Border.all(
                color: AppColors.tertiary.withValues(alpha: .58),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .055),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(
                        left:
                            AmoraSpacing.space16 +
                            AmoraSpacing.minimumTouchTarget +
                            AmoraSpacing.space12,
                      ),
                      child: Divider(
                        height: 1,
                        color: AppColors.tertiary.withValues(alpha: .38),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileSettingsHubRow extends StatefulWidget {
  const ProfileSettingsHubRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.trailingLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  final String? trailingLabel;

  @override
  State<ProfileSettingsHubRow> createState() => _ProfileSettingsHubRowState();
}

class _ProfileSettingsHubRowState extends State<ProfileSettingsHubRow> {
  var _pressed = false;
  var _focused = false;
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.danger ? AppColors.error : AppColors.primary;
    final highlighted = _pressed || _focused || _hovered;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      label: widget.title,
      hint: widget.subtitle,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? .992 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: highlighted
              ? AppColors.tertiary.withValues(alpha: .13)
              : AppColors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => _pressed = value),
            onFocusChange: (value) => setState(() => _focused = value),
            onHover: (value) => setState(() => _hovered = value),
            splashColor: AppColors.secondary.withValues(alpha: .10),
            highlightColor: AppColors.secondary.withValues(alpha: .04),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AmoraSpacing.space16,
                  vertical: AmoraSpacing.space12,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: AmoraSpacing.minimumTouchTarget,
                      height: AmoraSpacing.minimumTouchTarget,
                      decoration: BoxDecoration(
                        color: widget.danger
                            ? AppColors.error.withValues(alpha: .08)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: highlighted
                              ? foreground.withValues(alpha: .36)
                              : AppColors.tertiary.withValues(alpha: .62),
                        ),
                      ),
                      child: Icon(widget.icon, color: foreground, size: 23),
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AmoraTextStyles.titleMedium.copyWith(
                              color: widget.danger
                                  ? AppColors.error
                                  : AppColors.text,
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space4),
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AmoraTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AmoraSpacing.space8),
                    if (widget.trailingLabel != null) ...[
                      Text(
                        widget.trailingLabel!,
                        style: AmoraTextStyles.labelLarge.copyWith(
                          color: foreground,
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space4),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: foreground.withValues(alpha: .72),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
