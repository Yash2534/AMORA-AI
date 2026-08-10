import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

abstract final class AmoraTheme {
  static const ColorScheme colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surfaceBright,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    onSurfaceVariant: AppColors.text,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
    inverseSurface: AppColors.primary,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppColors.secondary,
    surfaceTint: AppColors.primary,
  );

  static ThemeData light() {
    final inputTheme = _inputDecorationTheme();
    final textTheme = AmoraTextStyles.textTheme.apply(
      fontFamily: AmoraTextStyles.fontFamily,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.primary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.surface,
      disabledColor: AppColors.text.withValues(alpha: .48),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AmoraPageTransitionsBuilder(),
          TargetPlatform.iOS: AmoraPageTransitionsBuilder(),
          TargetPlatform.macOS: AmoraPageTransitionsBuilder(),
          TargetPlatform.windows: AmoraPageTransitionsBuilder(),
          TargetPlatform.linux: AmoraPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: AmoraSpacing.appBarHeight,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        surfaceTintColor: AppColors.transparent,
        titleSpacing: AmoraSpacing.space20,
        titleTextStyle: AmoraTextStyles.pageHeaderTitle,
        iconTheme: IconThemeData(
          color: AppColors.primary,
          size: AmoraIconSizes.medium,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.primary,
          size: AmoraIconSizes.medium,
        ),
      ),
      dividerColor: AppColors.divider,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: AmoraIconSizes.standard,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: AmoraIconSizes.standard,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.focus,
        selectionColor: AppColors.activeContainer,
        selectionHandleColor: AppColors.focus,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.active,
        circularTrackColor: AppColors.surfaceContainerHighest,
        linearTrackColor: AppColors.surfaceContainerHighest,
        linearMinHeight: AmoraSpacing.space4,
      ),
      filledButtonTheme: FilledButtonThemeData(style: _filledButtonStyle()),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(elevation: 1),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(),
      ),
      textButtonTheme: TextButtonThemeData(style: _textButtonStyle()),
      iconButtonTheme: IconButtonThemeData(style: _iconButtonStyle()),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.active,
        foregroundColor: AppColors.onActive,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AmoraRadius.button),
      ),
      inputDecorationTheme: inputTheme,
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmoraRadius.small / 2),
        ),
        side: const BorderSide(color: AppColors.outline, width: 1.5),
        fillColor: _selectionFillColor(),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
      ),
      radioTheme: RadioThemeData(
        fillColor: _selectionForegroundColor(),
        visualDensity: VisualDensity.standard,
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith<Icon>((states) {
          final disabled = states.contains(WidgetState.disabled);
          final selected = states.contains(WidgetState.selected);
          return Icon(
            selected ? Icons.check_rounded : Icons.remove_rounded,
            size: 16,
            color: (selected ? AppColors.secondary : AppColors.primary)
                .withValues(alpha: disabled ? .42 : .72),
          );
        }),
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surface.withValues(alpha: .62);
          }
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          final selected = states.contains(WidgetState.selected);
          if (states.contains(WidgetState.disabled)) {
            return selected
                ? AppColors.secondary.withValues(alpha: .36)
                : AppColors.tertiary.withValues(alpha: .34);
          }
          return selected
              ? AppColors.active
              : AppColors.tertiary.withValues(alpha: .72);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((states) {
          final selected = states.contains(WidgetState.selected);
          if (states.contains(WidgetState.disabled)) {
            return selected
                ? AppColors.secondary.withValues(alpha: .28)
                : AppColors.primary.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.focused)) {
            return AppColors.primary.withValues(alpha: .42);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primary.withValues(alpha: .30);
          }
          return selected
              ? AppColors.secondary
              : AppColors.primary.withValues(alpha: .22);
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith<double>((states) {
          return states.contains(WidgetState.focused) ? 2 : 1;
        }),
        overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.secondary.withValues(alpha: .12);
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return AppColors.primary.withValues(alpha: .08);
          }
          return AppColors.transparent;
        }),
        mouseCursor: WidgetStateProperty.resolveWith<MouseCursor>((states) {
          return states.contains(WidgetState.disabled)
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click;
        }),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        splashRadius: 24,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.active,
        inactiveTrackColor: AppColors.surfaceContainerHighest,
        thumbColor: AppColors.active,
        overlayColor: AppColors.active.withValues(alpha: .12),
        trackHeight: AmoraSpacing.space4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipBackground,
        selectedColor: AppColors.activeContainer,
        disabledColor: AppColors.surfaceContainer,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: AmoraTextStyles.labelMedium,
        secondaryLabelStyle: AmoraTextStyles.labelMedium.copyWith(
          color: AppColors.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space12,
          vertical: AmoraSpacing.space8,
        ),
        checkmarkColor: AppColors.onPrimaryContainer,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AmoraRadius.card,
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: AppColors.transparent,
        elevation: 6,
        insetPadding: EdgeInsets.all(AmoraSpacing.space24),
        shape: RoundedRectangleBorder(borderRadius: AmoraRadius.dialog),
        titleTextStyle: AmoraTextStyles.dialogTitle,
        contentTextStyle: AmoraTextStyles.dialogBody,
        actionsPadding: EdgeInsets.fromLTRB(
          AmoraSpacing.space24,
          AmoraSpacing.space8,
          AmoraSpacing.space24,
          AmoraSpacing.space24,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        modalBackgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: AppColors.transparent,
        elevation: 4,
        modalElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AmoraRadius.sheet),
        showDragHandle: false,
        dragHandleColor: AppColors.outlineVariant,
        dragHandleSize: Size(AmoraSpacing.space32, AmoraSpacing.space4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AmoraSpacing.navigationBarHeight,
        elevation: 0,
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: AppColors.activeContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return AmoraTextStyles.navigation.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.active
                : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.active
                : AppColors.textSecondary,
            size: AmoraIconSizes.standard,
          );
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.activeContainer,
        selectedIconTheme: IconThemeData(color: AppColors.active),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: AmoraTextStyles.navigation,
        unselectedLabelTextStyle: AmoraTextStyles.navigation,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.active,
        unselectedItemColor: AppColors.text.withValues(alpha: .60),
        selectedLabelStyle: AmoraTextStyles.navigation,
        unselectedLabelStyle: AmoraTextStyles.navigation,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.active,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AmoraTextStyles.labelLarge,
        unselectedLabelStyle: AmoraTextStyles.labelLarge,
        indicatorColor: AppColors.active,
        dividerColor: AppColors.divider,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return AppColors.pressed;
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return AppColors.hover;
          }
          return null;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        backgroundColor: AppColors.onSurface,
        actionTextColor: AppColors.primaryContainer,
        disabledActionTextColor: AppColors.textDisabled,
        contentTextStyle: AmoraTextStyles.bodyMedium.copyWith(
          color: AppColors.surface,
        ),
        insetPadding: const EdgeInsets.all(AmoraSpacing.space16),
        shape: const RoundedRectangleBorder(borderRadius: AmoraRadius.button),
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: AmoraSpacing.minimumTouchTarget,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space16,
          vertical: AmoraSpacing.space4,
        ),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: AmoraTextStyles.bodyLarge,
        subtitleTextStyle: AmoraTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: AmoraRadius.button),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(
            AppColors.surfaceContainerLowest,
          ),
          elevation: WidgetStatePropertyAll(3),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: AmoraSpacing.space8),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AmoraRadius.button),
          ),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceContainerLowest,
        surfaceTintColor: AppColors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AmoraRadius.button),
        textStyle: AmoraTextStyles.bodyMedium,
      ),
      searchBarTheme: const SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
        elevation: WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide(color: AppColors.border)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AmoraRadius.input),
        ),
        textStyle: WidgetStatePropertyAll(AmoraTextStyles.bodyLarge),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(color: AppColors.textMuted),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(milliseconds: 1500),
        decoration: BoxDecoration(
          color: AppColors.onSurface,
          borderRadius: BorderRadius.circular(AmoraRadius.small),
        ),
        textStyle: AmoraTextStyles.labelMedium.copyWith(
          color: AppColors.surface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space12,
          vertical: AmoraSpacing.space8,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.surface,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? AppColors.text.withValues(alpha: .48)
              : AppColors.text;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.secondary
              : AppColors.transparent;
        }),
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.primary),
        todayBorder: const BorderSide(color: AppColors.secondary),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.surface
              : AppColors.text;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.transparent;
        }),
        dividerColor: AppColors.tertiary,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surface,
        hourMinuteColor: AppColors.tertiary,
        hourMinuteTextColor: AppColors.primary,
        dayPeriodColor: AppColors.tertiary,
        dayPeriodTextColor: AppColors.primary,
        dialBackgroundColor: AppColors.background,
        dialHandColor: AppColors.secondary,
        dialTextColor: AppColors.text,
        entryModeIconColor: AppColors.primary,
        helpTextStyle: AmoraTextStyles.labelLarge.copyWith(
          color: AppColors.primary,
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: AppColors.surface,
        collapsedBackgroundColor: AppColors.surface,
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.text,
        textColor: AppColors.primary,
        collapsedTextColor: AppColors.text,
        shape: Border(bottom: BorderSide(color: AppColors.tertiary)),
        collapsedShape: Border(bottom: BorderSide(color: AppColors.tertiary)),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.tertiary,
        textColor: AppColors.primary,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
      ),
    );
  }

  /// Compatibility entry point that intentionally returns the approved light
  /// palette until a separate dark brand palette is approved.
  static ThemeData dark() => light();

  static ButtonStyle _filledButtonStyle({double elevation = 0}) {
    return FilledButton.styleFrom(
      minimumSize: const Size(
        AmoraSpacing.minimumTouchTarget,
        AmoraSpacing.controlHeight,
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      disabledBackgroundColor: AppColors.tertiary,
      disabledForegroundColor: AppColors.primary.withValues(alpha: .55),
      elevation: elevation,
      padding: AmoraSpacing.button,
      textStyle: AmoraTextStyles.button,
      shape: const RoundedRectangleBorder(borderRadius: AmoraRadius.button),
    ).copyWith(overlayColor: _buttonOverlay(AppColors.onPrimary));
  }

  static ButtonStyle _outlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(
        AmoraSpacing.minimumTouchTarget,
        AmoraSpacing.controlHeight,
      ),
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.text.withValues(alpha: .48),
      side: const BorderSide(color: AppColors.primary),
      padding: AmoraSpacing.button,
      textStyle: AmoraTextStyles.button,
      shape: const RoundedRectangleBorder(borderRadius: AmoraRadius.button),
    ).copyWith(overlayColor: _buttonOverlay(AppColors.primary));
  }

  static ButtonStyle _textButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.text.withValues(alpha: .48),
      textStyle: AmoraTextStyles.button,
      shape: const RoundedRectangleBorder(borderRadius: AmoraRadius.button),
    ).copyWith(overlayColor: _buttonOverlay(AppColors.primary));
  }

  static ButtonStyle _iconButtonStyle() {
    return IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      disabledForegroundColor: AppColors.text.withValues(alpha: .48),
      minimumSize: const Size.square(AmoraSpacing.minimumTouchTarget),
      iconSize: AmoraIconSizes.standard,
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: const CircleBorder(),
    ).copyWith(overlayColor: _buttonOverlay(AppColors.primary));
  }

  static InputDecorationTheme _inputDecorationTheme() {
    const border = OutlineInputBorder(
      borderRadius: AmoraRadius.input,
      borderSide: BorderSide(color: AppColors.border),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: AmoraSpacing.field,
      floatingLabelStyle: AmoraTextStyles.labelMedium.copyWith(
        color: AppColors.primary,
      ),
      labelStyle: AmoraTextStyles.bodyMedium.copyWith(color: AppColors.primary),
      hintStyle: AmoraTextStyles.bodyLarge.copyWith(
        color: AppColors.text.withValues(alpha: .60),
      ),
      helperStyle: AmoraTextStyles.bodySmall,
      errorStyle: AmoraTextStyles.bodySmall.copyWith(color: AppColors.error),
      prefixIconColor: AppColors.primary,
      suffixIconColor: AppColors.text,
      border: border,
      enabledBorder: border,
      focusedBorder: const OutlineInputBorder(
        borderRadius: AmoraRadius.input,
        borderSide: BorderSide(color: AppColors.focus, width: 2),
      ),
      disabledBorder: const OutlineInputBorder(
        borderRadius: AmoraRadius.input,
        borderSide: BorderSide(color: AppColors.divider),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AmoraRadius.input,
        borderSide: BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AmoraRadius.input,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  static WidgetStateProperty<Color?> _buttonOverlay(Color color) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: .12);
      }
      if (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered)) {
        return color.withValues(alpha: .08);
      }
      return null;
    });
  }

  static WidgetStateProperty<Color?> _selectionFillColor() {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.surfaceContainerHighest;
      }
      return states.contains(WidgetState.selected)
          ? AppColors.active
          : AppColors.transparent;
    });
  }

  static WidgetStateProperty<Color?> _selectionForegroundColor() {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return AppColors.textDisabled;
      }
      return states.contains(WidgetState.selected)
          ? AppColors.active
          : AppColors.outline;
    });
  }
}
