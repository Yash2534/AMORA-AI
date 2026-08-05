import 'dart:convert';

import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KYC remains scroll-safe at compact 1.3 text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: const KycVerificationScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Identity Verification'), findsOneWidget);
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets('media permissions are requested only after a user action', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([
      _success,
      const AmoraMediaPickResult.failure(
        AmoraMediaIssue.permissionDenied,
        'Camera access is needed to take a photo.',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: KycVerificationScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    expect(picker.sources, isEmpty);
    await _tapKycAction(tester, 'Choose Aadhaar image');
    expect(picker.sources, [AmoraMediaSource.gallery]);
    await _tapKycAction(tester, 'Take verification selfie');

    expect(picker.sources, [AmoraMediaSource.gallery, AmoraMediaSource.camera]);
    expect(
      find.text('Camera access is needed to take a photo.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('permanently denied camera offers system settings', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([
      _success,
      const AmoraMediaPickResult.failure(
        AmoraMediaIssue.permissionPermanentlyDenied,
        'Access is disabled in system settings. Open settings to allow it.',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: KycVerificationScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    await _tapKycAction(tester, 'Choose Aadhaar image');
    await _tapKycAction(tester, 'Take verification selfie');
    final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    action.onPressed();
    await tester.pump();

    expect(picker.openSettingsCalls, 1);
  });

  testWidgets('successful verification callback is required for completion', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([_success, _success]);
    var verificationCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: KycVerificationScreen(
          mediaPicker: picker,
          verifyIdentity: ({required aadhaar, required selfie}) async {
            verificationCalls++;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await _tapKycAction(tester, 'Choose Aadhaar image');
    await _tapKycAction(tester, 'Take verification selfie');
    await _tapKycAction(tester, 'Start verification');
    await tester.pumpAndSettle();

    expect(verificationCalls, 1);
    expect(find.text('Verification complete'), findsOneWidget);
  });

  testWidgets('missing KYC backend never shows a verified state', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([_success, _success]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: KycVerificationScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    await _tapKycAction(tester, 'Choose Aadhaar image');
    await _tapKycAction(tester, 'Take verification selfie');
    await _tapKycAction(tester, 'Start verification');

    expect(find.text('Verification complete'), findsNothing);
    expect(
      find.textContaining('Secure verification is temporarily unavailable'),
      findsOneWidget,
    );
  });

  testWidgets('photo manager uses gallery picker and renders selected image', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([_success]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: PhotoManagerScreen(
          mediaPicker: picker,
          cropPreviewRenderer: (_) async => _success.media!.dataUri,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add_photo_alternate_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from photo library'));
    await tester.pumpAndSettle();

    expect(picker.sources, [AmoraMediaSource.gallery]);
    expect(find.text('Crop Photo'), findsOneWidget);
    expect(find.text('Preview Photo'), findsNothing);
    expect(
      find.byKey(const ValueKey('photo-crop-review-button')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('photo-crop-use-button')));
    await tester.pumpAndSettle();
    expect(find.text('Photo added to your profile.'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-photo-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled screenshot selection reports a clear result', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([
      const AmoraMediaPickResult.failure(
        AmoraMediaIssue.cancelled,
        'Image selection was cancelled.',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: ReportFlowScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Attach a screenshot'));
    await tester.tap(find.text('Attach a screenshot'));
    await tester.pump();

    expect(find.text('Image selection was cancelled.'), findsOneWidget);
  });

  testWidgets('denied screenshot gallery access offers retry', (tester) async {
    final picker = _FakeMediaPicker([
      const AmoraMediaPickResult.failure(
        AmoraMediaIssue.permissionDenied,
        'Photo library access is needed to choose an image.',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: ReportFlowScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Attach a screenshot'));
    await tester.tap(find.text('Attach a screenshot'));
    await tester.pump();

    expect(
      find.text('Photo library access is needed to choose an image.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('event feedback attaches a selected gallery photo', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([_success]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: PostEventFeedbackScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Upload a photo'));
    await tester.tap(find.text('Upload a photo'));
    await tester.pump();

    expect(find.text('qa-image.png attached'), findsOneWidget);
    expect(picker.sources, [AmoraMediaSource.gallery]);
  });
}

Future<void> _tapKycAction(WidgetTester tester, String label) async {
  final action = find.text(label);
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pump();
}

final _success = AmoraMediaPickResult.success(
  AmoraPickedMedia(
    dataUri: _successDataUri,
    name: 'qa-image.png',
    byteLength: _successBytes.lengthInBytes,
    bytes: _successBytes,
    mimeType: 'image/png',
  ),
);

const _successDataUri =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
final _successBytes = base64Decode(_successDataUri.split(',').last);

class _FakeMediaPicker implements AmoraMediaPicker {
  _FakeMediaPicker(this.results);

  final List<AmoraMediaPickResult> results;
  final List<AmoraMediaSource> sources = [];
  int openSettingsCalls = 0;

  @override
  Future<AmoraMediaPickResult> pickImage({
    required AmoraMediaSource source,
  }) async {
    sources.add(source);
    return results.removeAt(0);
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }
}
