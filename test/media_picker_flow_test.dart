import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('media permissions are requested only after a user action', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([
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
    await tester.ensureVisible(find.text('Take a selfie'));
    await tester.tap(find.text('Take a selfie'));
    await tester.pump();

    expect(picker.sources, [AmoraMediaSource.camera]);
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

    await tester.ensureVisible(find.text('Take a selfie'));
    await tester.tap(find.text('Take a selfie'));
    await tester.pump();
    final action = tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    action.onPressed();
    await tester.pump();

    expect(picker.openSettingsCalls, 1);
  });

  testWidgets('accepted camera capture completes the selfie check', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([_success]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: KycVerificationScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Take a selfie'));
    await tester.tap(find.text('Take a selfie'));
    await tester.pump();

    expect(picker.sources, [AmoraMediaSource.camera]);
    expect(find.text('Captured'), findsOneWidget);
  });

  testWidgets('photo manager uses gallery picker and renders selected image', (
    tester,
  ) async {
    final picker = _FakeMediaPicker([_success]);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: PhotoManagerScreen(mediaPicker: picker),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add_photo_alternate_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from photo library'));
    await tester.pumpAndSettle();

    expect(picker.sources, [AmoraMediaSource.gallery]);
    expect(find.text('Photo added. Save changes to keep it.'), findsOneWidget);
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

const _success = AmoraMediaPickResult.success(
  AmoraPickedMedia(
    dataUri:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    name: 'qa-image.png',
    byteLength: 68,
  ),
);

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
