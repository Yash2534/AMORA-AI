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
  factory MonetizationPlan.fromJson(Map<String, dynamic> json) =>
      MonetizationPlan(
        id: json['id'].toString(),
        name: json['name'].toString(),
        displayName: json['displayName']?.toString() ?? json['name'].toString(),
        description: json['description']?.toString(),
        priceMinor: (json['priceMinor'] as num).toInt(),
        currency: json['currency'].toString(),
        billingPeriod: json['billingPeriod'].toString(),
        billingInterval: (json['billingInterval'] as num).toInt(),
        features: ((json['features'] as List?) ?? const [])
            .map((value) => value.toString())
            .toList(growable: false),
        entitlements: ((json['entitlements'] as Map?) ?? const {})
            .cast<String, dynamic>(),
        offerText: json['offerText']?.toString(),
        active: json['active'] == true,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class MembershipState {
  const MembershipState({
    required this.status,
    required this.premium,
    required this.autoRenew,
    required this.cancelAtPeriodEnd,
    required this.entitlements,
    this.plan,
    this.startedAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.renewalDate,
  });
  final String status;
  final bool premium;
  final MonetizationPlan? plan;
  final DateTime? startedAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? renewalDate;
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
      plan: plan is Map
          ? MonetizationPlan.fromJson(plan.cast<String, dynamic>())
          : null,
      startedAt: date('startedAt'),
      currentPeriodStart: date('currentPeriodStart'),
      currentPeriodEnd: date('currentPeriodEnd'),
      renewalDate: date('renewalDate'),
      autoRenew: json['autoRenew'] == true,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
      entitlements: ((json['entitlements'] as Map?) ?? const {})
          .cast<String, dynamic>(),
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

class WalletState {
  const WalletState({
    required this.status,
    required this.balance,
    required this.creditUnit,
    this.updatedAt,
  });
  final String status;
  final int balance;
  final String creditUnit;
  final DateTime? updatedAt;
  factory WalletState.fromJson(Map<String, dynamic> json) => WalletState(
    status: json['status'].toString(),
    balance: (json['balance'] as num).toInt(),
    creditUnit: json['creditUnit'].toString(),
    updatedAt: DateTime.tryParse(
      json['updatedAt']?.toString() ?? '',
    )?.toLocal(),
  );
}

class WalletLedgerItem {
  const WalletLedgerItem({
    required this.id,
    required this.type,
    required this.direction,
    required this.amount,
    required this.balanceAfter,
    required this.status,
    required this.createdAt,
    this.description,
  });
  final String id;
  final String type;
  final String direction;
  final int amount;
  final int balanceAfter;
  final String status;
  final DateTime createdAt;
  final String? description;
  factory WalletLedgerItem.fromJson(Map<String, dynamic> json) =>
      WalletLedgerItem(
        id: json['id'].toString(),
        type: json['type'].toString(),
        direction: json['direction'].toString(),
        amount: (json['amount'] as num).toInt(),
        balanceAfter: (json['balanceAfter'] as num).toInt(),
        status: json['status'].toString(),
        createdAt: DateTime.parse(json['createdAt'].toString()).toLocal(),
        description: json['description']?.toString(),
      );
}

class WalletLedgerPage {
  const WalletLedgerPage({
    required this.items,
    required this.hasMore,
    this.nextPage,
  });
  final List<WalletLedgerItem> items;
  final bool hasMore;
  final int? nextPage;
}

class WalletProduct {
  const WalletProduct({
    required this.id,
    required this.type,
    required this.name,
    required this.credits,
    this.description,
    this.priceMinor,
    this.currency,
    this.redemptionKind,
    this.grantQuantity = 0,
    this.durationMinutes,
  });
  final String id;
  final String type;
  final String name;
  final String? description;
  final int credits;
  final int? priceMinor;
  final String? currency;
  final String? redemptionKind;
  final int grantQuantity;
  final int? durationMinutes;
  factory WalletProduct.fromJson(Map<String, dynamic> json) => WalletProduct(
    id: json['id'].toString(),
    type: json['type'].toString(),
    name: json['name'].toString(),
    description: json['description']?.toString(),
    credits: (json['credits'] as num).toInt(),
    priceMinor: (json['priceMinor'] as num?)?.toInt(),
    currency: json['currency']?.toString(),
    redemptionKind: json['redemptionKind']?.toString(),
    grantQuantity: (json['grantQuantity'] as num?)?.toInt() ?? 0,
    durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
  );
}

class BoostProduct {
  const BoostProduct({
    required this.id,
    required this.name,
    required this.quantity,
    required this.durationMinutes,
    required this.priceMinor,
    required this.walletCost,
    required this.currency,
    this.description,
  });
  final String id;
  final String name;
  final String? description;
  final int quantity;
  final int durationMinutes;
  final int priceMinor;
  final int walletCost;
  final String currency;
  factory BoostProduct.fromJson(Map<String, dynamic> json) => BoostProduct(
    id: json['id'].toString(),
    name: json['name'].toString(),
    description: json['description']?.toString(),
    quantity: (json['quantity'] as num).toInt(),
    durationMinutes: (json['durationMinutes'] as num).toInt(),
    priceMinor: (json['priceMinor'] as num).toInt(),
    walletCost: (json['walletCost'] as num).toInt(),
    currency: json['currency'].toString(),
  );
}

class BoostState {
  const BoostState({required this.available, this.activeUntil});
  final int available;
  final DateTime? activeUntil;
  bool get active =>
      activeUntil != null && activeUntil!.isAfter(DateTime.now());
  factory BoostState.fromJson(Map<String, dynamic> json) {
    final active = json['active'];
    return BoostState(
      available: (json['available'] as num?)?.toInt() ?? 0,
      activeUntil: active is Map
          ? DateTime.tryParse(active['expiresAt'].toString())?.toLocal()
          : null,
    );
  }
}

class GiftProduct {
  const GiftProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.priceCredits,
    required this.creditUnit,
    this.description,
    this.assetUrl,
  });
  final String id;
  final String name;
  final String type;
  final String? description;
  final int priceCredits;
  final String creditUnit;
  final String? assetUrl;
  factory GiftProduct.fromJson(Map<String, dynamic> json) => GiftProduct(
    id: json['id'].toString(),
    name: json['name'].toString(),
    type: json['type'].toString(),
    description: json['description']?.toString(),
    priceCredits: (json['priceCredits'] as num).toInt(),
    creditUnit: json['creditUnit'].toString(),
    assetUrl: json['assetUrl']?.toString(),
  );
}
