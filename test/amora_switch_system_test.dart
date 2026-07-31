import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('global switch theme defines every production interaction state', () {
    final switchTheme = AmoraTheme.light().switchTheme;
    final thumb = switchTheme.thumbColor!;
    final track = switchTheme.trackColor!;
    final outline = switchTheme.trackOutlineColor!;
    final overlay = switchTheme.overlayColor!;
    final thumbIcon = switchTheme.thumbIcon!;

    expect(thumb.resolve({}), AppColors.surface);
    expect(thumb.resolve({WidgetState.selected}), AppColors.surface);
    expect(
      thumb.resolve({WidgetState.disabled}),
      AppColors.surface.withValues(alpha: .62),
    );
    expect(
      thumb.resolve({WidgetState.disabled, WidgetState.selected}),
      AppColors.surface.withValues(alpha: .62),
    );

    expect(track.resolve({}), AppColors.tertiary.withValues(alpha: .72));
    expect(track.resolve({WidgetState.selected}), AppColors.secondary);
    expect(
      track.resolve({WidgetState.disabled}),
      AppColors.tertiary.withValues(alpha: .34),
    );
    expect(
      track.resolve({WidgetState.disabled, WidgetState.selected}),
      AppColors.secondary.withValues(alpha: .36),
    );

    expect(outline.resolve({}), AppColors.primary.withValues(alpha: .22));
    expect(outline.resolve({WidgetState.selected}), AppColors.secondary);
    expect(
      outline.resolve({WidgetState.focused}),
      AppColors.primary.withValues(alpha: .42),
    );
    expect(
      outline.resolve({WidgetState.hovered}),
      AppColors.primary.withValues(alpha: .30),
    );
    expect(
      overlay.resolve({WidgetState.pressed}),
      AppColors.secondary.withValues(alpha: .12),
    );
    expect(
      overlay.resolve({WidgetState.focused}),
      AppColors.primary.withValues(alpha: .08),
    );
    expect(
      overlay.resolve({WidgetState.hovered}),
      AppColors.primary.withValues(alpha: .08),
    );
    expect(switchTheme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(switchTheme.splashRadius, 24);
    expect(thumbIcon.resolve({})?.icon, Icons.remove_rounded);
    expect(
      thumbIcon.resolve({WidgetState.selected})?.icon,
      Icons.check_rounded,
    );
  });

  testWidgets('OFF and ON switches retain visible thumbs on opposite sides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          body: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  key: ValueKey('off-switch'),
                  value: false,
                  onChanged: _ignoreSwitch,
                ),
                Switch(
                  key: ValueKey('on-switch'),
                  value: true,
                  onChanged: _ignoreSwitch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final offSwitch = find.byKey(const ValueKey('off-switch'));
    final onSwitch = find.byKey(const ValueKey('on-switch'));
    expect(tester.widget<Switch>(offSwitch).value, isFalse);
    expect(tester.widget<Switch>(onSwitch).value, isTrue);
    expect(tester.getSize(offSwitch).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(onSwitch).height, greaterThanOrEqualTo(48));
    expect(
      tester.getSemantics(offSwitch),
      matchesSemantics(
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: false,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(onSwitch),
      matchesSemantics(
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: true,
        isFocusable: true,
        hasFocusAction: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('disabled ON and OFF switches keep contrasting thumbs', (
    tester,
  ) async {
    final theme = AmoraTheme.light().switchTheme;
    final disabledThumb = theme.thumbColor!.resolve({WidgetState.disabled})!;
    final disabledOffTrack = theme.trackColor!.resolve({WidgetState.disabled})!;
    final disabledOnTrack = theme.trackColor!.resolve({
      WidgetState.disabled,
      WidgetState.selected,
    })!;

    expect(
      Color.alphaBlend(disabledThumb, disabledOffTrack),
      isNot(disabledOffTrack),
    );
    expect(
      Color.alphaBlend(disabledThumb, disabledOnTrack),
      isNot(disabledOnTrack),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          body: Row(
            children: [
              Switch(value: false, onChanged: null),
              Switch(value: true, onChanged: null),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches.every((control) => control.onChanged == null), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch callback and semantics preserve boolean behavior', (
    tester,
  ) async {
    var value = false;
    var callbackCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            void update(bool next) {
              callbackCount++;
              setState(() => value = next);
            }

            return Scaffold(
              body: Center(
                child: Semantics(
                  key: const ValueKey('labeled-switch-semantics'),
                  label: 'Enable message notifications',
                  toggled: value,
                  enabled: true,
                  onTap: () => update(!value),
                  excludeSemantics: true,
                  child: Switch(value: value, onChanged: update),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('labeled-switch-semantics')),
      ),
      matchesSemantics(
        label: 'Enable message notifications',
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(value, isTrue);
    expect(callbackCount, 1);
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('labeled-switch-semantics')),
      ),
      matchesSemantics(
        label: 'Enable message notifications',
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('active switch rows and settings hub remain responsive', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
      await tester.binding.setSurfaceSize(
        Size(width, width >= 600 ? 900 : 760),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: const NotificationPreferencesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Notifications at $width');

      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: const ProfileSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Profile Settings'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Profile at $width');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}

void _ignoreSwitch(bool _) {}
