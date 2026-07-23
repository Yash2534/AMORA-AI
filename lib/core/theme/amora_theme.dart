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
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    shadow: AppColors.shadow,
    scrim: AppColors.scrim,
  );

  static ThemeData light() {
    final inputTheme = _inputDecorationTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.surface,
      disabledColor: AppColors.textDisabled,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: AmoraTextStyles.textTheme,
      primaryTextTheme: AmoraTextStyles.textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AmoraPageTransitionsBuilder(),
          TargetPlatform.iOS: AmoraPageTransitionsBuilder(),
          TargetPlatform.macOS: AmoraPageTransitionsBuilder(),
          TargetPlatform.windows: AmoraPageTransitionsBuilder(),
          TargetPlatform.linux: AmoraPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: AmoraSpacing.appBarHeight,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.transparent,
        titleSpacing: AmoraSpacing.space20,
        titleTextStyle: AmoraTextStyles.titleLarge,
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: AmoraIconSizes.standard,
        ),
        actionsIconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: AmoraIconSizes.standard,
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
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: AmoraTextStyles.bodyLarge,
        inputDecorationTheme: inputTheme,
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(
            AppColors.surfaceContainerLowest,
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AmoraRadius.card),
          ),
        ),
      ),
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
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textDisabled;
          }
          return states.contains(WidgetState.selected)
              ? AppColors.onPrimary
              : AppColors.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceContainerHighest;
          }
          return states.contains(WidgetState.selected)
              ? AppColors.active
              : AppColors.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.transparent
              : AppColors.outline;
        }),
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
        showDragHandle: true,
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.active,
        unselectedItemColor: AppColors.primary,
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
    );
  }

  static ButtonStyle _filledButtonStyle({double elevation = 0}) {
    return FilledButton.styleFrom(
      minimumSize: const Size(
        AmoraSpacing.minimumTouchTarget,
        AmoraSpacing.controlHeight,
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      disabledBackgroundColor: AppColors.surfaceContainerHighest,
      disabledForegroundColor: AppColors.textDisabled,
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
      disabledForegroundColor: AppColors.textDisabled,
      side: const BorderSide(color: AppColors.primary),
      padding: AmoraSpacing.button,
      textStyle: AmoraTextStyles.button,
      shape: const RoundedRectangleBorder(borderRadius: AmoraRadius.button),
    ).copyWith(overlayColor: _buttonOverlay(AppColors.primary));
  }

  static ButtonStyle _textButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.textDisabled,
      textStyle: AmoraTextStyles.button,
      shape: const RoundedRectangleBorder(borderRadius: AmoraRadius.button),
    ).copyWith(overlayColor: _buttonOverlay(AppColors.primary));
  }

  static ButtonStyle _iconButtonStyle() {
    return IconButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      disabledForegroundColor: AppColors.textDisabled,
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
        color: AppColors.focus,
      ),
      labelStyle: AmoraTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      hintStyle: AmoraTextStyles.bodyLarge.copyWith(
        color: AppColors.textDisabled,
      ),
      helperStyle: AmoraTextStyles.bodySmall,
      errorStyle: AmoraTextStyles.bodySmall.copyWith(color: AppColors.error),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
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
