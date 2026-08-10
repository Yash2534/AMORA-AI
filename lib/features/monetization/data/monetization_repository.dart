import 'dart:math';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/monetization/domain/monetization_models.dart';
import 'package:flutter/foundation.dart';

abstract interface class MonetizationRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}

class AuthMonetizationRemoteDataSource implements MonetizationRemoteDataSource {
  AuthMonetizationRemoteDataSource(this.auth);
  final AuthService auth;
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => auth.authenticatedRequest(method, path, body: body);
}

class MonetizationRepository extends ChangeNotifier {
  MonetizationRepository({
    AuthService? auth,
    MonetizationRemoteDataSource? remote,
  }) : _remote =
           remote ??
           AuthMonetizationRemoteDataSource(auth ?? AuthService.instance);
  static final _singleton = MonetizationRepository();
  static MonetizationRepository? debugOverride;
  static MonetizationRepository get instance => debugOverride ?? _singleton;
  final MonetizationRemoteDataSource _remote;
  MembershipState _membership = MembershipState.none;
  MembershipState get membership => _membership;
  void clearSessionState() {
    _membership = MembershipState.none;
    notifyListeners();
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      ((response['data'] as Map?) ?? const {}).cast<String, dynamic>();
  String newIdempotencyKey(String operation) =>
      'flutter:$operation:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 32)}';

  Future<List<MonetizationPlan>> plans() async {
    final data = _data(
      await _remote.request('GET', '/api/subscriptions/plans'),
    );
    return ((data['plans'] as List?) ?? const [])
        .map(
          (value) =>
              MonetizationPlan.fromJson((value as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<MembershipState> refreshMembership() async {
    final data = _data(await _remote.request('GET', '/api/subscriptions/me'));
    _membership = MembershipState.fromJson(
      (data['membership'] as Map).cast<String, dynamic>(),
    );
    notifyListeners();
    return _membership;
  }

  Future<MembershipState> cancelMembership() async {
    final data = _data(
      await _remote.request('POST', '/api/subscriptions/cancel'),
    );
    _membership = MembershipState.fromJson(
      (data['membership'] as Map).cast<String, dynamic>(),
    );
    notifyListeners();
    return _membership;
  }

  Future<MembershipState> restoreMembership() async {
    final data = _data(
      await _remote.request('POST', '/api/subscriptions/restore'),
    );
    _membership = MembershipState.fromJson(
      (data['membership'] as Map).cast<String, dynamic>(),
    );
    notifyListeners();
    return _membership;
  }

  Future<PaymentOrder> createPaymentOrder({
    required String productType,
    required String productId,
    required String idempotencyKey,
  }) async {
    final body = <String, dynamic>{
      'productType': productType,
      if (productType == 'subscription')
        'planId': productId
      else
        'productId': productId,
      'idempotencyKey': idempotencyKey,
    };
    final data = _data(
      await _remote.request('POST', '/api/payments/orders', body: body),
    );
    return PaymentOrder.fromJson(
      (data['order'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> verifyPayment({
    required String providerOrderId,
    required String providerPaymentId,
    required String signature,
  }) async {
    final data = _data(
      await _remote.request(
        'POST',
        '/api/payments/verify',
        body: {
          'providerOrderId': providerOrderId,
          'providerPaymentId': providerPaymentId,
          'signature': signature,
        },
      ),
    );
    final membership = data['membership'];
    if (membership is Map) {
      _membership = MembershipState.fromJson(
        membership.cast<String, dynamic>(),
      );
      notifyListeners();
    }
  }

  Future<WalletState> wallet() async {
    final data = _data(await _remote.request('GET', '/api/wallet'));
    return WalletState.fromJson(
      (data['wallet'] as Map).cast<String, dynamic>(),
    );
  }

  Future<List<WalletProduct>> walletProducts({String? type}) async {
    final path = type == null
        ? '/api/wallet/products'
        : '/api/wallet/products?type=$type';
    final data = _data(await _remote.request('GET', path));
    return ((data['products'] as List?) ?? const [])
        .map(
          (value) =>
              WalletProduct.fromJson((value as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<WalletLedgerPage> walletTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'type': ?type,
    };
    final data = _data(
      await _remote.request(
        'GET',
        Uri(
          path: '/api/wallet/transactions',
          queryParameters: query,
        ).toString(),
      ),
    );
    final pagination = ((data['pagination'] as Map?) ?? const {})
        .cast<String, dynamic>();
    return WalletLedgerPage(
      items: ((data['transactions'] as List?) ?? const [])
          .map(
            (value) => WalletLedgerItem.fromJson(
              (value as Map).cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
      hasMore: pagination['hasMore'] == true,
      nextPage: (pagination['nextPage'] as num?)?.toInt(),
    );
  }

  Future<WalletState> redeem(String productId, String key) async {
    final data = _data(
      await _remote.request(
        'POST',
        '/api/wallet/redemptions',
        body: {'productId': productId, 'idempotencyKey': key},
      ),
    );
    return WalletState.fromJson(
      (data['wallet'] as Map).cast<String, dynamic>(),
    );
  }

  Future<PaymentOrder> createTopUpOrder(String productId, String key) async {
    final data = _data(
      await _remote.request(
        'POST',
        '/api/wallet/top-up/orders',
        body: {'productId': productId, 'idempotencyKey': key},
      ),
    );
    return PaymentOrder.fromJson(
      (data['order'] as Map).cast<String, dynamic>(),
    );
  }

  Future<List<BoostProduct>> boostProducts() async {
    final data = _data(await _remote.request('GET', '/api/boosts/products'));
    return ((data['products'] as List?) ?? const [])
        .map(
          (value) =>
              BoostProduct.fromJson((value as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<BoostState> boostState() async {
    final data = _data(await _remote.request('GET', '/api/boosts/me'));
    return BoostState.fromJson((data['boost'] as Map).cast<String, dynamic>());
  }

  Future<BoostState> purchaseBoost(
    String productId,
    String source,
    String key,
  ) async {
    final data = _data(
      await _remote.request(
        'POST',
        '/api/boosts/purchase',
        body: {'productId': productId, 'source': source, 'idempotencyKey': key},
      ),
    );
    return BoostState.fromJson((data['boost'] as Map).cast<String, dynamic>());
  }

  Future<BoostState> activateBoost(String key) async {
    await _remote.request(
      'POST',
      '/api/discover/boost',
      body: {'idempotencyKey': key},
    );
    return boostState();
  }

  Future<List<GiftProduct>> gifts() async {
    final data = _data(await _remote.request('GET', '/api/gifts'));
    return ((data['gifts'] as List?) ?? const [])
        .map(
          (value) =>
              GiftProduct.fromJson((value as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<void> sendGift({
    required String recipientId,
    required String giftId,
    required String idempotencyKey,
    String? conversationId,
    String? note,
  }) => _remote.request(
    'POST',
    '/api/gifts/send',
    body: {
      'recipientId': int.parse(recipientId),
      'giftId': giftId,
      'idempotencyKey': idempotencyKey,
      if (conversationId != null) 'conversationId': int.parse(conversationId),
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
    },
  );
}
