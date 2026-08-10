import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/foundation.dart';

/// Read-only adapter over the server-authoritative membership state.
abstract final class AmoraaMembershipStatus {
  static bool get isPremiumActive =>
      (membershipTestMode &&
          MembershipTestFlowController.instance.membershipActive) ||
      MonetizationRepository.instance.membership.premium;

  static Listenable get listenable => membershipTestMode
      ? MembershipTestFlowController.instance
      : MonetizationRepository.instance;
}
