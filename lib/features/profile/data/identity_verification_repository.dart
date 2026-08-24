import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';

enum IdentityVerificationStatus {
  notStarted,
  pending,
  underReview,
  verified,
  rejected,
  resubmissionRequested,
}

class IdentityVerificationSnapshot {
  const IdentityVerificationSnapshot({
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final IdentityVerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  factory IdentityVerificationSnapshot.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString();
    final status = switch (rawStatus) {
      'pending' => IdentityVerificationStatus.pending,
      'under_review' => IdentityVerificationStatus.underReview,
      'verified' => IdentityVerificationStatus.verified,
      'rejected' => IdentityVerificationStatus.rejected,
      'resubmission_requested' =>
        IdentityVerificationStatus.resubmissionRequested,
      _ => IdentityVerificationStatus.notStarted,
    };
    return IdentityVerificationSnapshot(
      status: status,
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class IdentityVerificationRepository {
  IdentityVerificationRepository._();

  static final instance = IdentityVerificationRepository._();

  Future<IdentityVerificationSnapshot> status() async {
    final response = await AuthService.instance.authenticatedRequest(
      'GET',
      '/api/identity-verification/me',
    );
    return _snapshot(response);
  }

  Future<bool> submit({
    required AmoraPickedMedia aadhaar,
    required AmoraPickedMedia selfie,
  }) async {
    final response = await AuthService.instance.authenticatedMultipartFiles(
      '/api/identity-verification/submissions',
      files: [
        AuthenticatedMultipartFile(
          field: 'aadhaar',
          bytes: aadhaar.bytes,
          filename: _safeName('aadhaar', aadhaar),
          mimeType: aadhaar.mimeType,
        ),
        AuthenticatedMultipartFile(
          field: 'selfie',
          bytes: selfie.bytes,
          filename: _safeName('selfie', selfie),
          mimeType: selfie.mimeType,
        ),
      ],
    );
    return {
      IdentityVerificationStatus.pending,
      IdentityVerificationStatus.underReview,
      IdentityVerificationStatus.verified,
    }.contains(_snapshot(response).status);
  }

  IdentityVerificationSnapshot _snapshot(Map<String, dynamic> response) {
    final verification = ((response['data'] as Map?)?['verification'] as Map?)
        ?.cast<String, dynamic>();
    if (verification == null) {
      throw const AuthException('Identity verification response is invalid.');
    }
    return IdentityVerificationSnapshot.fromJson(verification);
  }

  String _safeName(String prefix, AmoraPickedMedia media) {
    final extension = switch (media.mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}.$extension';
  }
}
