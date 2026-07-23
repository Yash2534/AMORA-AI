import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.inputBackground,
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
          horizontal: AmoraSpacing.x5,
          vertical: AmoraSpacing.x4,
        ),
      ),
    );
  }
}
