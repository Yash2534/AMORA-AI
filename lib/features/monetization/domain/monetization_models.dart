import 'dart:convert';

int _jsonInt(Object? value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return num.tryParse(value?.toString() ?? '')?.toInt() ?? fallback;
}

Object? _decodedJson(Object? value) {
  if (value is! String) return value;
  try {
    return jsonDecode(value);
  } catch (_) {
    return null;
  }
}

List<String> _jsonStrings(Object? value) {
  final decoded = _decodedJson(value);
  if (decoded is! List) return const [];
  return decoded.map((item) => item.toString()).toList(growable: false);
}

Map<String, dynamic> _jsonMap(Object? value) {
  final decoded = _decodedJson(value);
  return decoded is Map
      ? decoded.cast<String, dynamic>()
      : const <String, dynamic>{};
}

class MonetizationPlan {
  const MonetizationPlan({
    required this.id,
    required this.name,
    required this.displayName,
    required this.priceMinor,
    required this.currency,
    required this.billingPeriod,
    required this.billingInterval,
    required this.features,
    required this.entitlements,
    this.description,
    this.offerText,
    this.active = true,
    this.sortOrder = 0,
  });
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final int priceMinor;
  final String currency;
  final String billingPeriod;
  final int billingInterval;
  final List<String> features;
  final Map<String, dynamic> entitlements;
  final String? offerText;
  final bool active;
  final int sortOrder;
  int get priceMajor => priceMinor ~/ 100;
  factory MonetizationPlan.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Subscription plan identity is missing.');
    }
    return MonetizationPlan(
      id: id,
      name: name,
      displayName: json['displayName']?.toString() ?? name,
      description: json['description']?.toString(),
      priceMinor: _jsonInt(json['priceMinor']),
      currency: json['currency']?.toString() ?? 'INR',
      billingPeriod: json['billingPeriod']?.toString() ?? 'month',
      billingInterval: _jsonInt(json['billingInterval'], fallback: 1),
      features: _jsonStrings(json['features']),
      entitlements: _jsonMap(json['entitlements']),
      offerText: json['offerText']?.toString(),
      active: json['active'] == true,
      sortOrder: _jsonInt(json['sortOrder']),
    );
  }
}

class MembershipState {
  const MembershipState({
    required this.status,
    required this.premium,
    required this.autoRenew,
    required this.cancelAtPeriodEnd,
    required this.entitlements,
    this.plan,
    this.id,
    this.planId,
    this.startedAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.renewalDate,
    this.cancelledAt,
    this.endedAt,
  });
  final String? id;
  final String? planId;
  final String status;
  final bool premium;
  final MonetizationPlan? plan;
  final DateTime? startedAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? renewalDate;
  final DateTime? cancelledAt;
  final DateTime? endedAt;
  final bool autoRenew;
  final bool cancelAtPeriodEnd;
  final Map<String, dynamic> entitlements;
  static const none = MembershipState(
    status: 'none',
    premium: false,
    autoRenew: false,
    cancelAtPeriodEnd: false,
    entitlements: {},
  );
  factory MembershipState.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => json[key] == null
        ? null
        : DateTime.tryParse(json[key].toString())?.toLocal();
    final plan = json['plan'];
    return MembershipState(
      status: json['status']?.toString() ?? 'none',
      premium: json['premium'] == true,
      id: json['id']?.toString(),
      planId: json['planId']?.toString(),
      plan: plan is Map
          ? MonetizationPlan.fromJson(plan.cast<String, dynamic>())
          : null,
      startedAt: date('startedAt'),
      currentPeriodStart: date('currentPeriodStart'),
      currentPeriodEnd: date('currentPeriodEnd'),
      renewalDate: date('renewalDate'),
      cancelledAt: date('cancelledAt'),
      endedAt: date('endedAt'),
      autoRenew: json['autoRenew'] == true,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      entitlements: _jsonMap(json['entitlements']),
    );
  }
}

class PaymentOrder {
  const PaymentOrder({
    required this.paymentId,
    required this.provider,
    required this.providerOrderId,
    required this.amountMinor,
    required this.currency,
    required this.productType,
    required this.productReferenceId,
    required this.checkoutKey,
  });
  final String paymentId;
  final String provider;
  final String providerOrderId;
  final int amountMinor;
  final String currency;
  final String productType;
  final String productReferenceId;
  final String checkoutKey;
  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    final checkout = (json['checkout'] as Map).cast<String, dynamic>();
    return PaymentOrder(
      paymentId: json['paymentId'].toString(),
      provider: json['provider'].toString(),
      providerOrderId: json['providerOrderId'].toString(),
      amountMinor: (json['amountMinor'] as num).toInt(),
      currency: json['currency'].toString(),
      productType: json['productType'].toString(),
      productReferenceId: json['productReferenceId'].toString(),
      checkoutKey: checkout['key'].toString(),
    );
  }
}
