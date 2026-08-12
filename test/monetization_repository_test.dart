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
  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => handler(method, path, body);
}

Map<String, dynamic> ok(Map<String, dynamic> data) => {
  'success': true,
  'data': data,
};

void main() {
  test('subscription catalog uses authoritative minor-unit pricing', () async {
    final repository = MonetizationRepository(
      remote: _FakeRemote(
        (_, _, _) async => ok({
          'plans': [
            {
              'id': 'gold',
              'name': 'Gold',
              'displayName': 'Gold Monthly',
              'priceMinor': 199900,
              'currency': 'INR',
              'billingPeriod': 'month',
              'billingInterval': 1,
              'features': ['Priority'],
              'entitlements': {'premium': true},
              'active': true,
              'sortOrder': 1,
            },
          ],
        }),
      ),
    );
    final plan = (await repository.plans()).single;
    expect(plan.id, 'gold');
    expect(plan.priceMinor, 199900);
  });

  test('payment order sends plan identity and never a client price', () async {
    late Map<String, dynamic> requestBody;
    final repository = MonetizationRepository(
      remote: _FakeRemote((_, _, body) async {
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
            'checkout': {'key': 'test', 'orderId': 'order_1'},
          },
        });
      }),
    );
    final order = await repository.createPaymentOrder(
      productType: 'subscription',
      productId: 'gold',
      idempotencyKey: 'subscription:test:key',
    );
    expect(order.amountMinor, 199900);
    expect(requestBody['planId'], 'gold');
    expect(requestBody.containsKey('amount'), false);
  });
}
