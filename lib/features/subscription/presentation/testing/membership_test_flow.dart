import 'package:flutter/material.dart';

const bool membershipTestMode = bool.fromEnvironment('AMORA_MEMBERSHIP_TEST');

enum TestPaymentOutcome { success, failure, cancelled, pending }

class MembershipTestPlan {
  const MembershipTestPlan({
    required this.id,
    required this.title,
    required this.durationLabel,
    required this.amount,
    required this.intervalLabel,
    required this.monthlyEquivalent,
    required this.bestValue,
  });

  final String id;
  final String title;
  final String durationLabel;
  final int amount;
  final String intervalLabel;
  final int monthlyEquivalent;
  final bool bestValue;
}

class MembershipPaymentArgs {
  const MembershipPaymentArgs({required this.plan});

  final MembershipTestPlan plan;
}

class MembershipTestPaymentMethod {
  const MembershipTestPaymentMethod({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}

const membershipTestPlans = [
  MembershipTestPlan(
    id: 'test_monthly',
    title: 'Monthly',
    durationLabel: '1 month',
    amount: 1999,
    intervalLabel: 'billed monthly',
    monthlyEquivalent: 1999,
    bestValue: false,
  ),
  MembershipTestPlan(
    id: 'test_quarterly',
    title: 'Quarterly',
    durationLabel: '3 months',
    amount: 5397,
    intervalLabel: 'billed every 3 months',
    monthlyEquivalent: 1799,
    bestValue: false,
  ),
  MembershipTestPlan(
    id: 'test_annual',
    title: 'Annual',
    durationLabel: '12 months',
    amount: 19188,
    intervalLabel: 'billed annually',
    monthlyEquivalent: 1599,
    bestValue: true,
  ),
];

const membershipTestPaymentMethods = [
  MembershipTestPaymentMethod(
    id: 'test_card',
    label: 'Test Card',
    subtitle: 'Simulated secure card payment',
    icon: Icons.credit_card_rounded,
  ),
  MembershipTestPaymentMethod(
    id: 'test_upi',
    label: 'Test UPI',
    subtitle: 'Simulated UPI approval',
    icon: Icons.account_balance_wallet_rounded,
  ),
];

class MembershipTestFlowController extends ChangeNotifier {
  MembershipTestFlowController._();

  static final instance = MembershipTestFlowController._();

  bool _membershipActive = false;
  bool _processing = false;
  TestPaymentOutcome _nextOutcome = TestPaymentOutcome.success;
  MembershipTestPlan _selectedPlan = membershipTestPlans.first;
  final Set<String> _joinedEventIds = <String>{};

  bool get membershipActive => membershipTestMode && _membershipActive;
  bool get processing => membershipTestMode && _processing;
  TestPaymentOutcome get nextOutcome => _nextOutcome;
  MembershipTestPlan get selectedPlan => _selectedPlan;
  Set<String> get joinedEventIds => Set.unmodifiable(_joinedEventIds);

  void selectPlan(MembershipTestPlan plan) {
    if (!membershipTestMode || plan.id == _selectedPlan.id) return;
    _selectedPlan = plan;
    notifyListeners();
  }

  void selectOutcome(TestPaymentOutcome outcome) {
    if (!membershipTestMode || outcome == _nextOutcome) return;
    _nextOutcome = outcome;
    notifyListeners();
  }

  void setProcessing(bool value) {
    if (!membershipTestMode || value == _processing) return;
    _processing = value;
    notifyListeners();
  }

  void activateMembership() {
    if (!membershipTestMode) return;
    _processing = false;
    _membershipActive = true;
    notifyListeners();
  }

  void joinEvent(String eventId) {
    if (!membershipActive || !_joinedEventIds.add(eventId)) return;
    notifyListeners();
  }

  void leaveEvent(String eventId) {
    if (!membershipTestMode || !_joinedEventIds.remove(eventId)) return;
    notifyListeners();
  }

  bool isJoined(String eventId) =>
      membershipActive && _joinedEventIds.contains(eventId);

  void reset() {
    if (!membershipTestMode) return;
    _membershipActive = false;
    _processing = false;
    _nextOutcome = TestPaymentOutcome.success;
    _selectedPlan = membershipTestPlans.first;
    _joinedEventIds.clear();
    notifyListeners();
  }
}

String formatMembershipAmount(int amount) {
  final digits = amount.toString();
  if (digits.length <= 3) return '₹$digits';
  final lastThree = digits.substring(digits.length - 3);
  final leading = digits.substring(0, digits.length - 3);
  return '₹$leading,$lastThree';
}
