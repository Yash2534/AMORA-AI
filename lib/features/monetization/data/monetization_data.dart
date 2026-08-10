import 'package:flutter/material.dart';

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.monthlyPrice,
    required this.tagline,
    required this.features,
    this.highlight = false,
    this.current = false,
  });

  final String name;
  final int monthlyPrice;
  final String tagline;
  final List<String> features;
  final bool highlight;
  final bool current;
}

class PaymentArgs {
  const PaymentArgs({
    required this.productId,
    required this.productType,
    required this.title,
    required this.billingCycle,
    required this.amountMinor,
    required this.currency,
    this.subtitle = 'AMORAA Premium',
  });

  final String productId;
  final String productType;
  final String title;
  final String billingCycle;
  final int amountMinor;
  final String currency;
  final String subtitle;
}

class FeatureMatrixItem {
  const FeatureMatrixItem({required this.feature, required this.availability});

  final String feature;
  final List<bool> availability;
}

class PaymentMethod {
  const PaymentMethod(this.name, this.icon, this.subtitle);

  final String name;
  final IconData icon;
  final String subtitle;
}

class CoachScore {
  const CoachScore(this.label, this.value);

  final String label;
  final int value;
}

class WalletPackage {
  const WalletPackage(this.coins, this.price, this.badge);

  final int coins;
  final int price;
  final String badge;
}

class WalletTransaction {
  const WalletTransaction(this.title, this.amount, this.date, this.positive);

  final String title;
  final int amount;
  final String date;
  final bool positive;
}

class ReferralStat {
  const ReferralStat(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

const featureMatrix = [
  FeatureMatrixItem(
    feature: 'Unlimited likes',
    availability: [true, true, true],
  ),
  FeatureMatrixItem(
    feature: 'See who liked you',
    availability: [true, true, true],
  ),
  FeatureMatrixItem(
    feature: 'Premium events',
    availability: [false, false, true],
  ),
  FeatureMatrixItem(feature: 'Incognito', availability: [false, true, true]),
];

const paymentMethods = [
  PaymentMethod(
    'UPI',
    Icons.account_balance_wallet_rounded,
    'Fast UPI checkout',
  ),
  PaymentMethod(
    'Credit/Debit Card',
    Icons.credit_card_rounded,
    'Visa, Mastercard, RuPay',
  ),
  PaymentMethod(
    'Net Banking',
    Icons.account_balance_rounded,
    'Indian banks supported',
  ),
  PaymentMethod(
    'Razorpay Gateway',
    Icons.lock_rounded,
    'Secure payment gateway',
  ),
];

const coachScores = [
  CoachScore('Warmth', 88),
  CoachScore('Curiosity', 82),
  CoachScore('Clarity', 85),
  CoachScore('Respect', 94),
];

const dateIdeas = [
  'Coffee date with a quiet corner and easy exits',
  'Museum visit with conversation-friendly pacing',
  'Bookstore browsing followed by dessert',
  'Sunset walk near a public promenade',
  'Food festival with shared small plates',
  'Weekend trip idea after trust is established',
  'Art gallery with a calm cafe nearby',
  'Live music night with reserved seating',
];

const reflectionPrompts = [
  'What made your last conversation feel easy?',
  'Did you feel heard and respected?',
  'Which reply would make the next message feel more personal?',
];

const icebreakerTones = [
  'Thoughtful',
  'Funny',
  'Travel',
  'Movies',
  'Food',
  'Coffee',
  'Warm',
  'Curious',
];

const icebreakers = [
  'Suggested opening message: Your architecture interest caught my attention. What is one building you never get tired of seeing?',
  'Funny ice breaker: Gujarati thali challenge. Which item should I respect first?',
  'Thoughtful question: What is a small habit that makes a weekend feel perfect to you?',
  'Travel conversation: If we had one free Saturday nearby, where would you take me first?',
  'Movie discussion: What film feels like your comfort rewatch?',
  'Food conversation: What is your most reliable cafe order?',
  'Coffee date idea: Quiet corner, one hour, and a dessert we can split.',
];

const referralStats = [
  ReferralStat('Friends invited', '12', Icons.group_add_rounded),
  ReferralStat(
    'Successful subscriptions',
    '5',
    Icons.workspace_premium_rounded,
  ),
  ReferralStat('Coins earned', '500', Icons.savings_rounded),
  ReferralStat('Pending rewards', '200', Icons.hourglass_top_rounded),
];
