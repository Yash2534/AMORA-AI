import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/permissions/amoraa_permission_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';
import 'package:amora_ai/features/settings/data/notification_preferences_repository.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({
    super.key,
    this.permissionService,
    this.repository,
  });

  final AmoraaPermissionService? permissionService;
  final NotificationPreferencesRepository? repository;

  static const routeName = '/notification-preferences';

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late final AmoraaPermissionService _permissionService;
  late final NotificationPreferencesRepository _repository;
  final Map<String, bool> _categories = {
    'New matches': true,
    'Messages': true,
    'Event reminders': true,
    'Payments & membership': true,
    'Offers from AMORAA': false,
    'Safety updates': true,
  };
  final Map<String, bool> _channels = {
    'Push notifications': false,
    'Email': true,
    'SMS': false,
  };
  bool _quiet = true;
  TimeOfDay _from = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 7, minute: 0);
  bool _loading = false;
  bool _saving = false;
  String? _error;

  static const _categoryMeta = {
    'New matches': (
      Icons.favorite_rounded,
      'When a new compatible connection is ready.',
    ),
    'Messages': (
      Icons.chat_bubble_rounded,
      'Replies and new conversations from your matches.',
    ),
    'Event reminders': (
      Icons.event_rounded,
      'Booking updates and reminders before an event.',
    ),
    'Payments & membership': (
      Icons.receipt_long_rounded,
      'Receipts, renewals, and important plan updates.',
    ),
    'Offers from AMORAA': (
      Icons.local_offer_rounded,
      'Occasional membership and event offers.',
    ),
    'Safety updates': (
      Icons.shield_rounded,
      'Critical account and community safety notices.',
    ),
  };

  static const _channelMeta = {
    'Push notifications': (
      Icons.notifications_active_rounded,
      'Fast updates on this device.',
    ),
    'Email': (Icons.alternate_email_rounded, 'A useful record in your inbox.'),
    'SMS': (Icons.sms_rounded, 'Only essential updates by text message.'),
  };

  @override
  void initState() {
    super.initState();
    _permissionService =
        widget.permissionService ?? AmoraaPermissionService.instance;
    _repository =
        widget.repository ?? NotificationPreferencesRepository.instance;
    if (widget.repository != null || AuthService.instance.currentUser != null) {
      _load();
    } else {
      _syncNotificationPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space12,
                  AmoraSpacing.space20,
                  AmoraSpacing.space32 +
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
                sliver: SliverList.list(
                  children: [
                    _Header(onBack: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: AmoraSpacing.space20),
                    const _NotificationHero(),
                    const SizedBox(height: AmoraSpacing.space16),
                    _PreferenceGroup(
                      title: 'What you hear about',
                      subtitle:
                          'Choose the updates that deserve your attention.',
                      children: [
                        for (final entry in _categories.entries)
                          _PreferenceToggle(
                            icon: _categoryMeta[entry.key]!.$1,
                            title: entry.key,
                            description: _categoryMeta[entry.key]!.$2,
                            value: entry.value,
                            locked: entry.key == 'Safety updates',
                            onChanged: (value) =>
                                setState(() => _categories[entry.key] = value),
                          ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    _PreferenceGroup(
                      title: 'Delivery channels',
                      subtitle:
                          'Control where each enabled update can reach you.',
                      children: [
                        for (final entry in _channels.entries)
                          _PreferenceToggle(
                            key: ValueKey(
                              'notification-channel-${entry.key.toLowerCase().replaceAll(' ', '-')}',
                            ),
                            icon: _channelMeta[entry.key]!.$1,
                            title: entry.key,
                            description: _channelMeta[entry.key]!.$2,
                            value: entry.value,
                            onChanged: (value) =>
                                _changeChannel(entry.key, value),
                          ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    _QuietHoursCard(
                      enabled: _quiet,
                      from: _from,
                      to: _to,
                      onEnabled: (value) => setState(() => _quiet = value),
                      onFrom: () => _pickTime(true),
                      onTo: () => _pickTime(false),
                    ),
                    const SizedBox(height: AmoraSpacing.space20),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                    ],
                    AppPrimaryButton(
                      label: 'Save preferences',
                      icon: Icons.check_rounded,
                      isLoading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(bool from) async {
    final next = await showTimePicker(
      context: context,
      initialTime: from ? _from : _to,
    );
    if (next == null) return;
    setState(() => from ? _from = next : _to = next);
  }

  Future<void> _syncNotificationPermission() async {
    final result = await _permissionService.notificationPermissionStatus();
    if (!mounted) return;
    if (!result.allowsFeature) {
      setState(() => _channels['Push notifications'] = false);
    }
  }

  Future<void> _changeChannel(String channel, bool value) async {
    if (channel != 'Push notifications' || !value) {
      setState(() => _channels[channel] = value);
      return;
    }
    final result = await _permissionService.requestNotificationPermission();
    if (!mounted) return;
    if (result.allowsFeature) {
      setState(() => _channels[channel] = true);
      return;
    }
    setState(() => _channels[channel] = false);
    await showAmoraaPermissionFeedback(
      context,
      category: AmoraaPermissionCategory.notifications,
      result: result,
      service: _permissionService,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _apply(await _repository.get());
      await _syncNotificationPermission();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(NotificationPreferences value) {
    if (!mounted) return;
    TimeOfDay parse(String value, TimeOfDay fallback) {
      final parts = value.split(':');
      if (parts.length != 2) return fallback;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      return hour == null || minute == null
          ? fallback
          : TimeOfDay(hour: hour, minute: minute);
    }

    setState(() {
      _categories
        ..['New matches'] = value.newMatches
        ..['Messages'] = value.messages
        ..['Event reminders'] = value.eventReminders
        ..['Payments & membership'] = value.paymentsAndMembership
        ..['Offers from AMORAA'] = value.offers
        ..['Safety updates'] = value.safetyUpdates;
      _channels
        ..['Push notifications'] = value.pushEnabled
        ..['Email'] = value.emailEnabled
        ..['SMS'] = value.smsEnabled;
      _quiet = value.quietHoursEnabled;
      _from = parse(value.quietStart, _from);
      _to = parse(value.quietEnd, _to);
    });
  }

  String _time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final canonical = await _repository.update(<String, dynamic>{
        'newMatches': _categories['New matches'],
        'messages': _categories['Messages'],
        'eventReminders': _categories['Event reminders'],
        'paymentsAndMembership': _categories['Payments & membership'],
        'offers': _categories['Offers from AMORAA'],
        'pushEnabled': _channels['Push notifications'],
        'emailEnabled': _channels['Email'],
        'smsEnabled': _channels['SMS'],
        'quietHoursEnabled': _quiet,
        'quietStart': _time(_from),
        'quietEnd': _time(_to),
      });
      _apply(canonical);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AmoraHeaderBackButton(onPressed: onBack),
        const SizedBox(width: AmoraSpacing.space8),
        const Expanded(
          child: AmoraScreenTitle(
            title: 'Notification Preferences',
            subtitle: 'Stay informed without the noise.',
          ),
        ),
      ],
    );
  }
}

class _NotificationHero extends StatelessWidget {
  const _NotificationHero();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .22),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.surface,
              size: 32,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your attention, your rules',
                  style: AmoraTextStyles.titleLarge,
                ),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  'Safety-critical alerts always remain enabled.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
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

class _PreferenceGroup extends StatelessWidget {
  const _PreferenceGroup({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space4,
              vertical: AmoraSpacing.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AmoraTextStyles.titleLarge),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  subtitle,
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(height: 1, indent: 60),
          ],
        ],
      ),
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  const _PreferenceToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: !locked,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 80),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AmoraSpacing.space8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: value ? AppColors.tertiary : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: value ? AppColors.primary : AppColors.textMuted,
                ),
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
                            title,
                            style: AmoraTextStyles.titleMedium,
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: AmoraSpacing.space8),
                          const Icon(
                            Icons.lock_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
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
              Switch(value: value, onChanged: locked ? null : onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietHoursCard extends StatelessWidget {
  const _QuietHoursCard({
    required this.enabled,
    required this.from,
    required this.to,
    required this.onEnabled,
    required this.onFrom,
    required this.onTo,
  });

  final bool enabled;
  final TimeOfDay from;
  final TimeOfDay to;
  final ValueChanged<bool> onEnabled;
  final VoidCallback onFrom;
  final VoidCallback onTo;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      child: Column(
        children: [
          _PreferenceToggle(
            icon: Icons.bedtime_rounded,
            title: 'Quiet hours',
            description: 'Pause non-critical notifications while you rest.',
            value: enabled,
            onChanged: onEnabled,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: enabled
                ? Padding(
                    padding: const EdgeInsets.only(top: AmoraSpacing.space12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TimeButton(
                            label: 'From',
                            value: from.format(context),
                            onTap: onFrom,
                          ),
                        ),
                        const SizedBox(width: AmoraSpacing.space12),
                        Expanded(
                          child: _TimeButton(
                            label: 'Until',
                            value: to.format(context),
                            onTap: onTo,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        children: [
          Text(label, style: AmoraTextStyles.labelSmall),
          Text(value, style: AmoraTextStyles.titleMedium),
        ],
      ),
    );
  }
}
