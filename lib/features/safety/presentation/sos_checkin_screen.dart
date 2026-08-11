import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/permissions/amoraa_permission_service.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class SosCheckinScreen extends StatefulWidget {
  const SosCheckinScreen({super.key, this.permissionService});

  final AmoraaPermissionService? permissionService;

  static const routeName = '/sos-checkin';

  @override
  State<SosCheckinScreen> createState() => _SosCheckinScreenState();
}

class _SosCheckinScreenState extends State<SosCheckinScreen>
    with SingleTickerProviderStateMixin {
  late final AmoraaPermissionService _permissionService;
  late final AnimationController _pulse;
  String _timer = '1 hour';
  bool _location = false;
  final Set<String> _notified = {};

  @override
  void initState() {
    super.initState();
    _permissionService =
        widget.permissionService ?? AmoraaPermissionService.instance;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
      lowerBound: .92,
      upperBound: 1.06,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Date Check-in',
        subtitle: 'Share safety status with people you trust.',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space16,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScaleTransition(
                      scale: _pulse,
                      child: PremiumCard(
                        color: AppColors.errorRed.withValues(alpha: .08),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.sos_rounded,
                              color: AppColors.errorRed,
                              size: 42,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Use check-in tools if a date feels uncomfortable. Permissions are prepared for future contacts and location.',
                                style: TextStyle(
                                  color: AppColors.deepWine,
                                  height: 1.35,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle('Trusted contacts'),
                    const SizedBox(height: 12),
                    for (final contact in _contacts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContactCard(
                          name: contact.$1,
                          relation: contact.$2,
                          notified: _notified.contains(contact.$1),
                          onNotify: () {
                            setState(() => _notified.add(contact.$1));
                            _snack('${contact.$1} notification prepared');
                          },
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _snack('Choose a trusted contact'),
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Add trusted contact'),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle('Safety timer'),
                    const SizedBox(height: 12),
                    AmoraaCompactSelect<String>(
                      label: 'Safety timer',
                      value: _timer,
                      prefixIcon: Icons.timer_outlined,
                      options: [
                        for (final value in const [
                          '30 min',
                          '1 hour',
                          '2 hours',
                        ])
                          AmoraaSelectOption(value: value, label: value),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _timer = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      key: const ValueKey('live-location-permission-toggle'),
                      contentPadding: EdgeInsets.zero,
                      value: _location,
                      onChanged: _changeLocationSharing,
                      title: const Text('Live location sharing'),
                      subtitle: const Text(
                        'Share your location during an active safety check-in.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AppPrimaryButton(
                            label: "I'm Safe",
                            icon: Icons.check_circle_rounded,
                            onPressed: () => _snack('Safe check-in sent'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppPrimaryButton(
                            label: 'Need Help',
                            icon: Icons.warning_rounded,
                            variant: AppPrimaryButtonVariant.dark,
                            onPressed: _needHelp,
                          ),
                        ),
                      ],
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

  void _needHelp() {
    setState(() {
      for (final contact in _contacts) {
        _notified.add(contact.$1);
      }
    });
    _snack('SOS alert prepared for trusted contacts');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeLocationSharing(bool value) async {
    if (!value) {
      setState(() => _location = false);
      return;
    }
    final result = await _permissionService.requestLocationPermission();
    if (!mounted) return;
    if (result.allowsFeature) {
      setState(() => _location = true);
      return;
    }
    setState(() => _location = false);
    await showAmoraaPermissionFeedback(
      context,
      category: AmoraaPermissionCategory.location,
      result: result,
      service: _permissionService,
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.name,
    required this.relation,
    required this.notified,
    required this.onNotify,
  });

  final String name;
  final String relation;
  final bool notified;
  final VoidCallback onNotify;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.lavenderBackground,
            child: Icon(
              Icons.contact_phone_rounded,
              color: AppColors.primaryPurple,
            ),
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
                Text(relation),
              ],
            ),
          ),
          AppPrimaryButton(
            label: notified ? 'Notified' : 'Notify',
            size: AmoraButtonSize.compact,
            fullWidth: false,
            variant: AppPrimaryButtonVariant.text,
            onPressed: onNotify,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.deepWine,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

const _contacts = [
  ('Nisha', 'Best friend'),
  ('Rohan', 'Brother'),
  ('Maa', 'Family contact'),
];
