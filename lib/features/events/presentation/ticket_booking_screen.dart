import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:flutter/material.dart';

class TicketBookingScreen extends StatefulWidget {
  const TicketBookingScreen({super.key, this.event});

  static const routeName = '/ticket-booking';

  final EventModel? event;

  @override
  State<TicketBookingScreen> createState() => _TicketBookingScreenState();
}

class _TicketBookingScreenState extends State<TicketBookingScreen> {
  final _couponController = TextEditingController();
  var _ticketType = 'VIP';
  var _quantity = 1;
  var _addCompanion = false;
  var _couponApplied = false;
  var _paymentMethod = 'UPI';
  var _acceptedTerms = false;
  var _confirmed = false;

  EventModel _selectedEvent(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return widget.event ?? (args is EventModel ? args : events.first);
  }

  int _ticketPrice(EventModel event) {
    return switch (_ticketType) {
      'Standard' => event.price,
      'VIP' => (event.price * 1.65).round(),
      'Gold' => (event.price * 2.2).round(),
      _ => event.price,
    };
  }

  int _ticketTotal(EventModel event) => _ticketPrice(event) * _quantity;
  int _tax(EventModel event) => (_ticketTotal(event) * .18).round();
  int get _fee => 79 * _quantity;
  int get _discount => _couponApplied ? 300 : 0;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = _selectedEvent(context);
    if (_confirmed) return _SuccessView(event: event);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.space32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(AmoraIcons.back),
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    Expanded(
                      child: Text(
                        'Ticket Booking',
                        style: AmoraTextStyles.headlineSmall.copyWith(
                          color: AppColors.deepWine,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AmoraSpacing.space20),
                EventImagePanel(
                  event: event,
                  height: 148,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${event.date} - ${event.time} - ${event.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const BookingStepper(
                  currentStep: 3,
                  labels: ['Ticket', 'Quantity', 'Companion', 'Coupon'],
                ),
                const SizedBox(height: 24),
                _StepBlock(
                  step: 'Step 1',
                  title: 'Select Ticket',
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Standard', label: Text('Standard')),
                      ButtonSegment(value: 'VIP', label: Text('VIP')),
                      ButtonSegment(value: 'Gold', label: Text('Gold')),
                    ],
                    selected: {_ticketType},
                    onSelectionChanged: (selection) =>
                        setState(() => _ticketType = selection.first),
                  ),
                ),
                const SizedBox(height: 14),
                _StepBlock(
                  step: 'Step 2',
                  title: 'Quantity',
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Decrease quantity',
                        onPressed: _quantity == 1
                            ? null
                            : () => setState(() => _quantity--),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$_quantity',
                            style: const TextStyle(
                              color: AppColors.deepWine,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Increase quantity',
                        onPressed: _quantity == 6
                            ? null
                            : () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _StepBlock(
                  step: 'Step 3',
                  title: 'Add Companion',
                  child: Material(
                    color: AppColors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Optional companion pass'),
                      subtitle: const Text('Seat them with your booking group'),
                      value: _addCompanion,
                      onChanged: (value) =>
                          setState(() => _addCompanion = value),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _StepBlock(
                  step: 'Step 4',
                  title: 'Coupon',
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _couponController,
                          label: 'Coupon code',
                          hint: 'AMORA300',
                          icon: AmoraIcons.ticket,
                        ),
                      ),
                      const SizedBox(width: 10),
                      PremiumEventButton(
                        label: 'Apply',
                        compact: true,
                        onPressed: () {
                          setState(() => _couponApplied = true);
                          showEventSnack(context, 'Coupon applied');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TicketSummaryCard(
                  ticket: _ticketTotal(event),
                  tax: _tax(event),
                  fee: _fee,
                  discount: _discount,
                ),
                const SizedBox(height: 18),
                const SectionTitle(title: 'Payment Methods'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final method in const [
                      'UPI',
                      'Credit Card',
                      'Debit Card',
                      'Net Banking',
                      'Cashless',
                    ])
                      ChoiceChip(
                        label: Text(method),
                        selected: _paymentMethod == method,
                        showCheckmark: false,
                        selectedColor: AppColors.primaryPurple,
                        labelStyle: TextStyle(
                          color: _paymentMethod == method
                              ? AppColors.surface
                              : AppColors.deepWine,
                          fontWeight: FontWeight.w800,
                        ),
                        onSelected: (_) =>
                            setState(() => _paymentMethod = method),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Material(
                  color: AppColors.transparent,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _acceptedTerms,
                    onChanged: (value) =>
                        setState(() => _acceptedTerms = value ?? false),
                    title: const Text(
                      'I agree to event terms, safety guidelines, and cashless entry.',
                      style: TextStyle(
                        color: AppColors.deepWine,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PremiumEventButton(
                  label: 'Continue to Payment',
                  icon: Icons.lock_rounded,
                  onPressed: _confirmBooking,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmBooking() {
    if (!_acceptedTerms) {
      showEventSnack(context, 'Please accept the terms to continue');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(
          Icons.confirmation_number_rounded,
          color: AppColors.primaryPurple,
          size: 42,
        ),
        title: const Text('Ticket held'),
        content: const Text(
          'Your pass is reserved locally. Complete payment to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _confirmed = true);
            },
            child: const Text('Preview QR'),
          ),
          FilledButton(
            onPressed: () {
              final selectedEvent = _selectedEvent(context);
              Navigator.pop(context);
              Navigator.of(context).pushNamed(
                PaymentScreen.routeName,
                arguments: PaymentArgs(
                  title: '$_ticketType event ticket',
                  subtitle: 'AMORA Events',
                  billingCycle: '$_quantity pass for ${selectedEvent.title}',
                  amount:
                      _ticketTotal(selectedEvent) +
                      _tax(selectedEvent) +
                      _fee -
                      _discount,
                ),
              );
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }
}

class _StepBlock extends StatelessWidget {
  const _StepBlock({
    required this.step,
    required this.title,
    required this.child,
  });

  final String step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step,
            style: const TextStyle(
              color: AppColors.primaryRose,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.deepWine,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .8, end: 1),
                duration: AmoraMotion.slow,
                curve: AmoraMotion.curve,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: .16),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryRose,
                              AppColors.primaryPurple,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.surface,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ticket Confirmed',
                        style: TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your digital pass for ${event.title} is ready.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 22),
                      PremiumEventButton(
                        label: 'Generate Digital Pass',
                        icon: Icons.qr_code_2_rounded,
                        onPressed: () => Navigator.of(context).pushReplacement(
                          premiumEventRoute(const MyEventsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
