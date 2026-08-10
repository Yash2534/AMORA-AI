import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/admin_shared/presentation/admin_dashboard_widgets.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:flutter/material.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key, this.repository});

  static const routeName = '/host-dashboard';
  final EventRepository? repository;

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  List<EventModel> _events = const [];
  bool _loading = true;
  Object? _error;

  EventRepository get _repository =>
      widget.repository ?? EventRepository.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _repository.hostDashboard();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _RoleGate(onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AmoraSpacing.space20,
                      AmoraSpacing.space20,
                      AmoraSpacing.space20,
                      AmoraSpacing.navigationContentInset,
                    ),
                    children: [
                      const DashboardHeader(
                        title: 'Host Dashboard',
                        subtitle: 'Your AMORAA event operations',
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
                        children: [
                          DashboardKpiCard(
                            label: 'Events',
                            value: '${_events.length}',
                            icon: Icons.event_rounded,
                          ),
                          DashboardKpiCard(
                            label: 'Registrations',
                            value:
                                '${_events.fold<int>(0, (sum, event) => sum + event.registeredCount)}',
                            icon: Icons.confirmation_number_rounded,
                          ),
                          DashboardKpiCard(
                            label: 'Waitlisted',
                            value:
                                '${_events.fold<int>(0, (sum, event) => sum + event.waitlistCount)}',
                            icon: Icons.hourglass_top_rounded,
                          ),
                          DashboardKpiCard(
                            label: 'Checked in',
                            value:
                                '${_events.fold<int>(0, (sum, event) => sum + event.checkInCount)}',
                            icon: Icons.how_to_reg_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const SectionLabel('Event Performance'),
                      const SizedBox(height: 12),
                      if (_events.isEmpty)
                        const PremiumCard(
                          child: Text('No host events are available yet.'),
                        )
                      else
                        for (final event in _events)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: EventPerformanceCard(
                              title: event.title,
                              date: event.date,
                              city: event.city,
                              sold: event.registeredCount,
                              capacity: event.capacity,
                              revenue: '—',
                              status: event.eventStatus,
                              onAttendees: () => showDashboardSnack(
                                context,
                                '${event.registeredCount} registrations',
                              ),
                              onPromote: () => showDashboardSnack(
                                context,
                                'Promotion tools are outside Events Phase 4.',
                              ),
                              onReport: () => showDashboardSnack(
                                context,
                                'Revenue reporting is not enabled.',
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
}

class _RoleGate extends StatelessWidget {
  const _RoleGate({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: PremiumCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Host access required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'The server could not load an authorized host dashboard.',
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    ),
  );
}
