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
  int _sessionGeneration = 0;
  MembershipState get membership => _membership;

  void clearSessionState() {
    _sessionGeneration += 1;
    _membership = MembershipState.none;
    notifyListeners();
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      ((response['data'] as Map?) ?? const {}).cast<String, dynamic>();
  String newIdempotencyKey(String operation) =>
      'flutter:$operation:${DateTime.now().microsecondsSinceEpoch}:${Random.secure().nextInt(1 << 32)}';

  Future<List<MonetizationPlan>> plans() async {
    final values = _data(
      await _remote.request('GET', '/api/subscriptions/plans'),
    )['plans'];
    if (values is! List) {
      throw const FormatException('Subscription plans response is invalid.');
    }
    return values
        .map(
          (value) =>
              MonetizationPlan.fromJson((value as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
  }

  Future<MembershipState> refreshMembership() async {
    final generation = _sessionGeneration;
    final userId = AuthService.instance.currentUser?.id;
    final data = _data(await _remote.request('GET', '/api/subscriptions/me'));
    _ensureCurrentSession(generation, userId);
    _membership = _membershipFrom(data['membership']);
    notifyListeners();
    return _membership;
  }

  Future<MembershipState> cancelMembership() async {
    final generation = _sessionGeneration;
    final userId = AuthService.instance.currentUser?.id;
    final data = _data(
      await _remote.request('POST', '/api/subscriptions/cancel'),
    );
    _ensureCurrentSession(generation, userId);
    _membership = _membershipFrom(data['membership']);
    notifyListeners();
    return _membership;
  }

  Future<MembershipState> restoreMembership() async {
    final generation = _sessionGeneration;
    final userId = AuthService.instance.currentUser?.id;
    final data = _data(
      await _remote.request('POST', '/api/subscriptions/restore'),
    );
    _ensureCurrentSession(generation, userId);
    _membership = _membershipFrom(data['membership']);
    notifyListeners();
    return _membership;
  }

  Future<PaymentOrder> createPaymentOrder({
    required String productType,
    required String productId,
    required String idempotencyKey,
  }) async {
    if (productType != 'subscription') {
      throw ArgumentError('Only subscription payments are supported.');
    }
    final data = _data(
      await _remote.request(
        'POST',
        '/api/payments/orders',
        body: {
          'productType': 'subscription',
          'planId': productId,
          'idempotencyKey': idempotencyKey,
        },
      ),
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
    final generation = _sessionGeneration;
    final userId = AuthService.instance.currentUser?.id;
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
      _ensureCurrentSession(generation, userId);
      _membership = MembershipState.fromJson(
        membership.cast<String, dynamic>(),
      );
      notifyListeners();
    }
  }

  MembershipState _membershipFrom(Object? value) {
    if (value == null) return MembershipState.none;
    if (value is! Map) {
      throw const FormatException('Membership response is invalid.');
    }
    return MembershipState.fromJson(value.cast<String, dynamic>());
  }

  void _ensureCurrentSession(int generation, int? userId) {
    if (generation == _sessionGeneration &&
        userId == AuthService.instance.currentUser?.id) {
      return;
    }
    throw const AuthException(
      'Your account changed while membership was loading. Please try again.',
      code: 'SESSION_CHANGED',
    );
  }
}
