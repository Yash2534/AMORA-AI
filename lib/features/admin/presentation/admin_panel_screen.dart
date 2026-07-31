import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/admin_shared/presentation/admin_dashboard_widgets.dart';
import 'package:flutter/material.dart';

const _demoRole = 'admin';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  static const routeName = '/admin-panel';

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  var _verificationStatus = 'Pending';
  var _eventStatus = 'Pending';

  @override
  Widget build(BuildContext context) {
    if (_demoRole != 'admin') {
      return const _RoleGate();
    }
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.background, AppColors.surface],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ResponsiveMobileFrame(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: DashboardHeader(
                      title: 'Admin Panel',
                      subtitle: 'Platform operations overview',
                      icon: Icons.admin_panel_settings_rounded,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AmoraSpacing.space20,
                        AmoraSpacing.space0,
                        AmoraSpacing.space20,
                        AmoraSpacing.navigationContentInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                            children: const [
                              DashboardKpiCard(
                                label: 'Active Users',
                                value: '12,840',
                                icon: Icons.people_rounded,
                              ),
                              DashboardKpiCard(
                                label: 'Pending Verifications',
                                value: '128',
                                icon: Icons.verified_rounded,
                              ),
                              DashboardKpiCard(
                                label: 'Pending Events',
                                value: '14',
                                icon: Icons.event_rounded,
                              ),
                              DashboardKpiCard(
                                label: 'Monthly Revenue',
                                value: 'Rs 18.6L',
                                icon: Icons.trending_up_rounded,
                                color: AppColors.successGreen,
                              ),
                              DashboardKpiCard(
                                label: 'Reports Open',
                                value: '23',
                                icon: Icons.report_rounded,
                                color: AppColors.errorRed,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const TabBar(
                            isScrollable: true,
                            tabs: [
                              Tab(text: 'Verification'),
                              Tab(text: 'Events'),
                              Tab(text: 'Transactions'),
                              Tab(text: 'Reports'),
                              Tab(text: 'Analytics'),
                            ],
                          ),
                          SizedBox(
                            height: 760,
                            child: TabBarView(
                              children: [
                                _VerificationTab(
                                  status: _verificationStatus,
                                  onApprove: () => setState(
                                    () => _verificationStatus = 'Approved',
                                  ),
                                  onReject: () => setState(
                                    () => _verificationStatus = 'Rejected',
                                  ),
                                ),
                                _EventApprovalsTab(
                                  status: _eventStatus,
                                  onApprove: () =>
                                      setState(() => _eventStatus = 'Approved'),
                                  onReject: () =>
                                      setState(() => _eventStatus = 'Rejected'),
                                ),
                                const _TransactionsTab(),
                                const _ReportsTab(),
                                const _AnalyticsTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _VerificationTab extends StatelessWidget {
  const _VerificationTab({
    required this.status,
    required this.onApprove,
    required this.onReject,
  });

  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: VerificationQueueCard(
        name: 'Nisha Shah, 27',
        city: 'Ahmedabad',
        idType: 'Aadhaar',
        status: status,
        onApprove: () {
          onApprove();
          showDashboardSnack(context, 'Verification approved');
        },
        onReject: () {
          onReject();
          showDashboardSnack(context, 'Verification rejected');
        },
        onDetails: () =>
            showDashboardSnack(context, 'Verification details opened'),
      ),
    );
  }
}

class _EventApprovalsTab extends StatelessWidget {
  const _EventApprovalsTab({
    required this.status,
    required this.onApprove,
    required this.onReject,
  });

  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sunset Rooftop Dating',
                      style: TextStyle(
                        color: AppColors.deepWine,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  StatusChip(label: status, color: AppColors.warningAmber),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Venue safety checklist'),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(label: 'KYC Host', color: AppColors.successGreen),
                  StatusChip(label: 'Fire Exit', color: AppColors.successGreen),
                  StatusChip(label: 'Security', color: AppColors.successGreen),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Approve Event',
                      size: AmoraButtonSize.compact,
                      onPressed: () {
                        onApprove();
                        showDashboardSnack(context, 'Event approved');
                      },
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space8),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Reject Event',
                      size: AmoraButtonSize.compact,
                      variant: AppPrimaryButtonVariant.outlined,
                      onPressed: () {
                        onReject();
                        showDashboardSnack(context, 'Event rejected');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _TransactionRow('Gold subscription', 'Rs 1,999', 'Success'),
        _TransactionRow('Event ticket', 'Rs 699', 'Success'),
        _TransactionRow('Rose gift', 'Rs 99', 'Failed'),
        _TransactionRow('Boost pack', 'Rs 299', 'Refunded'),
      ],
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final report in const [
          ('Reported Rahul', 'Harassment', 'High'),
          ('Profile QA', 'Fake photos', 'Medium'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.$1,
                          style: const TextStyle(
                            color: AppColors.deepWine,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      StatusChip(label: report.$3, color: AppColors.errorRed),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Reason: ${report.$2}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () =>
                            showDashboardSnack(context, 'Warning sent'),
                        child: const Text('Warn'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            showDashboardSnack(context, 'User suspended'),
                        child: const Text('Suspend'),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            showDashboardSnack(context, 'Report dismissed'),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revenue Overview',
                style: TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 130,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final h in const [72, 96, 60, 124, 110, 132])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            height: h.toDouble(),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  AppColors.primary,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DashboardKpiCard(
          label: 'Match conversion rate',
          value: '38%',
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(height: 12),
        const DashboardKpiCard(
          label: 'Subscription conversion',
          value: '11.4%',
          icon: Icons.workspace_premium_rounded,
          color: AppColors.premiumGold,
        ),
        const SizedBox(height: 12),
        const SectionLabel('City growth'),
        const SizedBox(height: 10),
        for (final city in [
          ('Ahmedabad', '+18%'),
          ('Surat', '+12%'),
          ('Vadodara', '+9%'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PremiumCard(
              padding: const EdgeInsets.all(14),
              radius: 22,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_city_rounded,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      city.$1,
                      style: const TextStyle(
                        color: AppColors.deepWine,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  StatusChip(label: city.$2, color: AppColors.successGreen),
                ],
              ),
            ),
          ),
      ],
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
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.errorRed,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Admin access required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.deepWine,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This panel is visible only when demoRole is admin.',
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

class _TransactionRow extends StatelessWidget {
  const _TransactionRow(this.title, this.amount, this.status);

  final String title;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(amount),
            const SizedBox(width: 8),
            StatusChip(
              label: status,
              color: status == 'Success'
                  ? AppColors.successGreen
                  : status == 'Failed'
                  ? AppColors.errorRed
                  : AppColors.warningAmber,
            ),
          ],
        ),
      ),
    );
  }
}
