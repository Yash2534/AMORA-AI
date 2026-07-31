import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class SosCheckinScreen extends StatefulWidget {
  const SosCheckinScreen({super.key});

  static const routeName = '/sos-checkin';

  @override
  State<SosCheckinScreen> createState() => _SosCheckinScreenState();
}

class _SosCheckinScreenState extends State<SosCheckinScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  String _timer = '1 hour';
  bool _location = false;
  final Set<String> _notified = {};

  @override
  void initState() {
    super.initState();
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
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(onBack: () => Navigator.of(context).maybePop()),
                    const SizedBox(height: 18),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final value in ['30 min', '1 hour', '2 hours'])
                          ChoiceChip(
                            label: Text(value),
                            selected: _timer == value,
                            onSelected: (_) => setState(() => _timer = value),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _location,
                      onChanged: (value) => setState(() => _location = value),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: AppColors.surface,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date Check-in',
                style: TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Share safety status with people you trust.',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
