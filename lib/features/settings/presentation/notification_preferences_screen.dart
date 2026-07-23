import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  static const routeName = '/notification-preferences';

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final Map<String, bool> _categories = {
    'New Match': true,
    'New Message': true,
    'Event Reminder': true,
    'Payment Alerts': true,
    'Offers': false,
    'Safety': true,
  };
  bool _push = true;
  bool _email = true;
  bool _sms = false;
  bool _quiet = true;
  TimeOfDay _from = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 7, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Notification Preferences',
                        style: TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                for (final entry in _categories.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PremiumCard(
                      padding: const EdgeInsets.all(4),
                      child: SwitchListTile(
                        value: entry.value,
                        onChanged: (value) =>
                            setState(() => _categories[entry.key] = value),
                        title: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _push,
                        onChanged: (value) => setState(() => _push = value),
                        title: const Text('Push'),
                      ),
                      SwitchListTile(
                        value: _email,
                        onChanged: (value) => setState(() => _email = value),
                        title: const Text('Email'),
                      ),
                      SwitchListTile(
                        value: _sms,
                        onChanged: (value) => setState(() => _sms = value),
                        title: const Text('SMS'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _quiet,
                        onChanged: (value) => setState(() => _quiet = value),
                        title: const Text('Quiet hours'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'From ${_from.format(context)}',
                              size: AmoraButtonSize.compact,
                              variant: AppPrimaryButtonVariant.outlined,
                              onPressed: () => _pickTime(true),
                            ),
                          ),
                          const SizedBox(width: AmoraSpacing.space8),
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'To ${_to.format(context)}',
                              size: AmoraButtonSize.compact,
                              variant: AppPrimaryButtonVariant.outlined,
                              onPressed: () => _pickTime(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Save Preferences',
                  icon: Icons.check_rounded,
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Notification preferences saved'),
                      ),
                    ),
                ),
              ],
            ),
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
    setState(() {
      if (from) {
        _from = next;
      } else {
        _to = next;
      }
    });
  }
}
