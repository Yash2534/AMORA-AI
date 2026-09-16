import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/widgets/glass_container.dart';
import 'package:flutter/material.dart';

class AmoraSearchBar extends StatelessWidget {
  const AmoraSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.onClear,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      level: AmoraGlassLevel.subtle,
      borderRadius: 99,
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText,
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          prefixIcon: const Icon(
            AmoraIcons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: onClear != null
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(AmoraIcons.close),
                )
              : onFilterTap == null
              ? null
              : IconButton(
                  tooltip: 'Filters',
                  onPressed: onFilterTap,
                  icon: const Icon(AmoraIcons.filter),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
