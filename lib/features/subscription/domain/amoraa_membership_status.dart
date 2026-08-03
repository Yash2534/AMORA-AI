import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/foundation.dart';

/// Read-only adapter over the membership values already used by checkout and
/// the Subscription screen. It does not add or persist subscription state.
abstract final class AmoraaMembershipStatus {
  static bool get isPremiumActive =>
      MembershipTestFlowController.instance.membershipActive ||
      subscriptionPlans.any((plan) => plan.current);

  static Listenable get listenable => MembershipTestFlowController.instance;
}
