import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/admin_shared/presentation/admin_dashboard_widgets.dart';
import 'package:flutter/material.dart';

const _demoRole = 'host';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  static const routeName = '/host-dashboard';

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  final List<bool> _checkedIn = [false, true, false, false];

  @override
  Widget build(BuildContext context) {
    if (_demoRole != 'host' && _demoRole != 'admin') {
      return const _RoleGate();
    }
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.lavenderBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(
                    title: 'Host Dashboard',
                    subtitle: 'Welcome back, Cafe Mocha Ahmedabad',
                    icon: Icons.analytics_rounded,
                    badge: 'Verified Host',
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: const [
                      DashboardKpiCard(
                        label: 'Today Bookings',
                        value: '42',
                        icon: Icons.confirmation_number_rounded,
                      ),
                      DashboardKpiCard(
                        label: 'Ticket Revenue',
                        value: 'Rs 38,400',
                        icon: Icons.currency_rupee_rounded,
                      ),
                      DashboardKpiCard(
                        label: 'Sponsorship Revenue',
                        value: 'Rs 1.2L',
                        icon: Icons.handshake_rounded,
                        color: AppColors.premiumGold,
                      ),
                      DashboardKpiCard(
                        label: 'Attendees',
                        value: '186',
                        icon: Icons.groups_rounded,
                      ),
                      DashboardKpiCard(
                        label: 'Payout Pending',
                        value: 'Rs 24,800',
                        icon: Icons.account_balance_rounded,
                        color: AppColors.warningAmber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Event Performance'),
                  const SizedBox(height: 12),
                  for (final event in _events)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: EventPerformanceCard(
                        title: event.title,
                        date: event.date,
                        city: event.city,
                        sold: event.sold,
                        capacity: event.capacity,
                        revenue: event.revenue,
                        status: event.status,
                        onAttendees: () => showDashboardSnack(
                          context,
                          '${event.title} attendees opened',
                        ),
                        onPromote: () => showDashboardSnack(
                          context,
                          '${event.title} promoted',
                        ),
                        onReport: () => showDashboardSnack(
                          context,
                          '${event.title} revenue report generated',
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const SectionLabel('Attendee Management'),
                  const SizedBox(height: 12),
                  PremiumCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < _attendees.length; i++)
                          AttendeeTile(
                            name: _attendees[i].name,
                            ticket: _attendees[i].ticket,
                            checkedIn: _checkedIn[i],
                            onCheckIn: () {
                              setState(() => _checkedIn[i] = true);
                              showDashboardSnack(
                                context,
                                '${_attendees[i].name} checked in',
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Sponsorship'),
                  const SizedBox(height: 12),
                  for (final sponsor in _sponsors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PremiumCard(
                        padding: const EdgeInsets.all(16),
                        radius: 24,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.premiumGold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sponsor.$1,
                                    style: const TextStyle(
                                      color: AppColors.deepWine,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text('${sponsor.$2} package'),
                                ],
                              ),
                            ),
                            StatusChip(
                              label: sponsor.$3,
                              color: AppColors.successGreen,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: AppColors.successGreen,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bank verified',
                                style: TextStyle(
                                  color: AppColors.deepWine,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Next payout date: 15 Jul 2026'),
                        const SizedBox(height: 14),
                        AppPrimaryButton(
                          label: 'Request payout',
                          icon: Icons.account_balance_wallet_rounded,
                          onPressed: () => showDashboardSnack(
                            context,
                            'Payout request submitted',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleGate extends StatelessWidget {
  const _RoleGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: PremiumCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: AppColors.primaryPurple,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Host access required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.deepWine,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This dashboard is visible only for demoRole host or admin.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      label: 'Go Back',
                      onPressed: () => Navigator.of(context).maybePop(),
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

class _HostEvent {
  const _HostEvent(
    this.title,
    this.date,
    this.city,
    this.sold,
    this.capacity,
    this.revenue,
    this.status,
  );

  final String title;
  final String date;
  final String city;
  final int sold;
  final int capacity;
  final String revenue;
  final String status;
}

class _Attendee {
  const _Attendee(this.name, this.ticket);

  final String name;
  final String ticket;
}

const _events = [
  _HostEvent(
    'Coffee Match Meetup',
    '18 Jul',
    'Ahmedabad',
    42,
    60,
    'Rs 38,400',
    'Live',
  ),
  _HostEvent(
    'Premium Singles Night',
    '24 Jul',
    'Mumbai',
    86,
    100,
    'Rs 1.8L',
    'Approved',
  ),
  _HostEvent(
    'Garba Social Evening',
    '26 Jul',
    'Vadodara',
    58,
    80,
    'Rs 74,200',
    'Completed',
  ),
];

const _attendees = [
  _Attendee('Aadhya Shah', 'VIP Ticket'),
  _Attendee('Kavya Mehta', 'Gold Ticket'),
  _Attendee('Aarav Patel', 'Standard Ticket'),
  _Attendee('Riya Desai', 'VIP Ticket'),
];

const _sponsors = [
  ('Brew Culture', 'Rs 45,000', 'Active'),
  ('Urban Singles Club', 'Rs 75,000', 'Active'),
];
