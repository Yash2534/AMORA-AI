import 'package:amora_ai/features/profile/data/identity_verification_repository.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps the committed requested-resubmission server state', () {
    final snapshot = IdentityVerificationSnapshot.fromJson({
      'status': 'resubmission_requested',
      'reviewedAt': '2026-08-24T10:00:00.000Z',
      'rejectionReason': 'Please provide a clearer selfie.',
    });

    expect(snapshot.status, IdentityVerificationStatus.resubmissionRequested);
    expect(snapshot.rejectionReason, 'Please provide a clearer selfie.');
    expect(snapshot.reviewedAt, DateTime.utc(2026, 8, 24, 10));
  });

  testWidgets('requested resubmission reopens upload with the server reason', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: KycVerificationScreen(
          loadStatus: () async => const IdentityVerificationSnapshot(
            status: IdentityVerificationStatus.resubmissionRequested,
            rejectionReason: 'Please provide a clearer selfie.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upload Aadhaar'), findsOneWidget);
    expect(
      find.text('New evidence was requested: Please provide a clearer selfie.'),
      findsOneWidget,
    );
    expect(find.text('Identity verified'), findsNothing);
  });
}
