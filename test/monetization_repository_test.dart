import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements MonetizationRemoteDataSource {
  _FakeRemote(this.handler);
  final Future<Map<String, dynamic>> Function(
    String,
    String,
    Map<String, dynamic>?,
  )
  handler;
  final calls = <(String, String, Map<String, dynamic>?)>[];
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    calls.add((method, path, body));
    return handler(method, path, body);
  }
}

Map<String, dynamic> ok(Map<String, dynamic> data) => {
  'success': true,
  'data': data,
};
final planJson = <String, dynamic>{
  'id': 'gold',
  'name': 'Gold',
  'displayName': 'Gold Monthly',
  'priceMinor': 199900,
  'price': 1999,
  'currency': 'INR',
  'billingPeriod': 'month',
  'billingInterval': 1,
  'features': ['Priority'],
  'entitlements': {'premium': true},
  'active': true,
  'sortOrder': 1,
};

void main() {
  test('loads server plans and preserves minor-unit pricing', () async {
    final repository = MonetizationRepository(
      remote: _FakeRemote(
        (_, _, _) async => ok({
          'plans': [planJson],
        }),
      ),
    );
    final plans = await repository.plans();
    expect(plans.single.id, 'gold');
    expect(plans.single.priceMinor, 199900);
    expect(plans.single.currency, 'INR');
  });

  test('plan API errors are surfaced without local fallback', () async {
    final repository = MonetizationRepository(
      remote: _FakeRemote((_, _, _) async => throw StateError('offline')),
    );
    await expectLater(repository.plans(), throwsStateError);
  });

  test(
    'membership loads and payment verification refreshes authoritative state',
    () async {
      var verified = false;
      final remote = _FakeRemote((method, path, body) async {
        if (path == '/api/subscriptions/me') {
          return ok({
            'membership': {
              'status': 'none',
              'premium': false,
              'autoRenew': false,
              'cancelAtPeriodEnd': false,
              'entitlements': {},
            },
          });
        }
        if (path == '/api/payments/verify') {
          verified = true;
          return ok({
            'membership': {
              'status': 'active',
              'premium': true,
              'plan': planJson,
              'autoRenew': false,
              'cancelAtPeriodEnd': false,
              'entitlements': {'premium': true},
            },
          });
        }
        throw StateError(path);
      });
      final repository = MonetizationRepository(remote: remote);
      expect((await repository.refreshMembership()).premium, false);
      await repository.verifyPayment(
        providerOrderId: 'order_1',
        providerPaymentId: 'pay_1',
        signature: 'signature',
      );
      expect(verified, true);
      expect(repository.membership.premium, true);
    },
  );

  test(
    'payment order sends product identity and idempotency, never client price',
    () async {
      late Map<String, dynamic> requestBody;
      final repository = MonetizationRepository(
        remote: _FakeRemote((_, path, body) async {
          requestBody = body!;
          return ok({
            'order': {
              'paymentId': '1',
              'provider': 'razorpay',
              'providerOrderId': 'order_1',
              'amountMinor': 199900,
              'currency': 'INR',
              'productType': 'subscription',
              'productReferenceId': 'gold',
              'checkout': {'key': 'rzp_test', 'orderId': 'order_1'},
            },
          });
        }),
      );
      final order = await repository.createPaymentOrder(
        productType: 'subscription',
        productId: 'gold',
        idempotencyKey: 'flutter:test:key',
      );
      expect(order.amountMinor, 199900);
      expect(requestBody, containsPair('planId', 'gold'));
      expect(requestBody.containsKey('amount'), false);
      expect(requestBody.containsKey('currency'), false);
    },
  );

  test('wallet balance and paginated ledger parse from backend', () async {
    final repository = MonetizationRepository(
      remote: _FakeRemote((_, path, _) async {
        if (path == '/api/wallet') {
          return ok({
            'wallet': {
              'status': 'active',
              'balance': 701,
              'creditUnit': 'AMORAA_CREDITS',
              'updatedAt': '2026-08-11T00:00:00.000Z',
            },
          });
        }
        return ok({
          'transactions': [
            {
              'id': '1',
              'type': 'gift_spend',
              'direction': 'debit',
              'amount': 299,
              'balanceAfter': 701,
              'status': 'posted',
              'createdAt': '2026-08-11T00:00:00.000Z',
            },
          ],
          'pagination': {'hasMore': true, 'nextPage': 2},
        });
      }),
    );
    expect((await repository.wallet()).balance, 701);
    final page = await repository.walletTransactions(limit: 1);
    expect(page.items.single.amount, 299);
    expect(page.hasMore, true);
    expect(page.nextPage, 2);
  });

  test('boost inventory and activation are backend-derived', () async {
    var stateCalls = 0;
    final repository = MonetizationRepository(
      remote: _FakeRemote((_, path, body) async {
        if (path == '/api/discover/boost') {
          expect(body!['idempotencyKey'], 'activation:key');
          return ok({'active': true});
        }
        if (path == '/api/boosts/me') {
          stateCalls++;
          return ok({
            'boost': {
              'available': 0,
              'active': {'expiresAt': '2026-08-12T00:00:00.000Z'},
            },
          });
        }
        throw StateError(path);
      }),
    );
    final boost = await repository.activateBoost('activation:key');
    expect(stateCalls, 1);
    expect(boost.activeUntil, isNotNull);
  });

  test('gift catalog and send use server gift id with retry key', () async {
    final remote = _FakeRemote((_, path, body) async {
      if (path == '/api/gifts') {
        return ok({
          'gifts': [
            {
              'id': 'rose_ritual',
              'name': 'Rose Ritual',
              'type': 'rose',
              'priceCredits': 299,
              'creditUnit': 'AMORAA_CREDITS',
            },
          ],
        });
      }
      if (path == '/api/gifts/send') {
        expect(body, containsPair('idempotencyKey', 'gift:key:1'));
        expect(body, isNot(contains('priceCredits')));
        return ok({
          'giftTransaction': {'id': '1'},
        });
      }
      throw StateError(path);
    });
    final repository = MonetizationRepository(remote: remote);
    expect((await repository.gifts()).single.priceCredits, 299);
    await repository.sendGift(
      recipientId: '42',
      giftId: 'rose_ritual',
      idempotencyKey: 'gift:key:1',
    );
  });

  test(
    'gift send failures are surfaced and never converted to fake success',
    () async {
      final repository = MonetizationRepository(
        remote: _FakeRemote(
          (_, _, _) async => throw StateError('insufficient'),
        ),
      );
      await expectLater(
        repository.sendGift(
          recipientId: '42',
          giftId: 'rose_ritual',
          idempotencyKey: 'gift:key:2',
        ),
        throwsStateError,
      );
    },
  );
}
