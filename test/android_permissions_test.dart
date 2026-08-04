import 'dart:io';

import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/permissions/amoraa_permission_service.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/safety/presentation/sos_checkin_screen.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('Android manifest', () {
    late String manifest;

    setUpAll(() {
      manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
    });

    test('declares exactly the approved runtime permission categories', () {
      final permissions = RegExp(
        r'<uses-permission android:name="([^"]+)"[^>]*/>',
      ).allMatches(manifest).map((match) => match.group(1)).toSet();

      expect(permissions, {
        'android.permission.CAMERA',
        'android.permission.ACCESS_COARSE_LOCATION',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_MEDIA_VIDEO',
      });
      expect(manifest, isNot(contains('MANAGE_EXTERNAL_STORAGE')));
      expect(manifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
      expect(manifest, isNot(contains('READ_EXTERNAL_STORAGE')));
    });
  });

  group('typed permission service', () {
    test('constructing the service never requests a permission', () {
      final gateway = _FakePermissionGateway();

      AmoraaPermissionService(
        gateway: gateway,
        targetPlatform: TargetPlatform.android,
        isWeb: false,
      );

      expect(gateway.requests, isEmpty);
    });

    test('camera request is user-triggered and typed', () async {
      final gateway = _FakePermissionGateway(
        statuses: {Permission.camera: PermissionStatus.denied},
        requestResults: {Permission.camera: PermissionStatus.granted},
      );
      final service = _androidService(gateway);

      expect(gateway.requests, isEmpty);
      final result = await service.requestCameraPermission();

      expect(gateway.requests, [Permission.camera]);
      expect(result.state, AmoraaPermissionState.granted);
    });

    test('Android system media picker avoids broad gallery requests', () async {
      final gateway = _FakePermissionGateway();
      final service = _androidService(gateway);

      final photos = await service.requestPhotoPermission();
      final videos = await service.requestVideoPermission();

      expect(photos.state, AmoraaPermissionState.notRequired);
      expect(videos.state, AmoraaPermissionState.notRequired);
      expect(gateway.statusChecks, isEmpty);
      expect(gateway.requests, isEmpty);
    });

    test(
      'notification denial is not repeatedly requested in one session',
      () async {
        final gateway = _FakePermissionGateway(
          statuses: {Permission.notification: PermissionStatus.denied},
          requestResults: {Permission.notification: PermissionStatus.denied},
        );
        final service = _androidService(gateway);

        await service.requestNotificationPermission();
        await service.requestNotificationPermission();

        expect(gateway.requests, [Permission.notification]);
      },
    );

    test('disabled location service blocks the permission request', () async {
      final gateway = _FakePermissionGateway(
        locationServiceStatus: ServiceStatus.disabled,
      );
      final result = await _androidService(gateway).requestLocationPermission();

      expect(result.state, AmoraaPermissionState.serviceDisabled);
      expect(gateway.requests, isEmpty);
    });

    test(
      'device media picker requests Camera and handles denial safely',
      () async {
        final gateway = _FakePermissionGateway(
          statuses: {Permission.camera: PermissionStatus.denied},
          requestResults: {Permission.camera: PermissionStatus.denied},
        );
        final picker = DeviceAmoraMediaPicker(
          permissionService: _androidService(gateway),
        );

        final result = await picker.pickImage(source: AmoraMediaSource.camera);

        expect(gateway.requests, [Permission.camera]);
        expect(result.issue, AmoraMediaIssue.permissionDenied);
      },
    );
  });

  testWidgets('Live Location requests permission only when enabled', (
    tester,
  ) async {
    final gateway = _FakePermissionGateway(
      statuses: {Permission.locationWhenInUse: PermissionStatus.denied},
      requestResults: {Permission.locationWhenInUse: PermissionStatus.granted},
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: SosCheckinScreen(permissionService: _androidService(gateway)),
      ),
    );
    await tester.pump();

    expect(gateway.requests, isEmpty);
    final toggle = find.byKey(
      const ValueKey('live-location-permission-toggle'),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(gateway.requests, [Permission.locationWhenInUse]);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });

  testWidgets('permanently denied Location offers Open Settings', (
    tester,
  ) async {
    final gateway = _FakePermissionGateway(
      statuses: {
        Permission.locationWhenInUse: PermissionStatus.permanentlyDenied,
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: SosCheckinScreen(permissionService: _androidService(gateway)),
      ),
    );
    await tester.pump();

    final toggle = find.byKey(
      const ValueKey('live-location-permission-toggle'),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Location access is turned off'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pump();
    expect(gateway.appSettingsCalls, 1);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  testWidgets('disabled Location services opens system Location settings', (
    tester,
  ) async {
    final gateway = _FakePermissionGateway(
      locationServiceStatus: ServiceStatus.disabled,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: SosCheckinScreen(permissionService: _androidService(gateway)),
      ),
    );
    await tester.pump();

    final toggle = find.byKey(
      const ValueKey('live-location-permission-toggle'),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Location services are turned off'), findsOneWidget);
    expect(
      find.text('Turn on location services to use this feature.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Open Settings'));
    await tester.pump();
    expect(gateway.locationSettingsCalls, 1);
  });

  testWidgets(
    'Push notifications request permission from the existing toggle',
    (tester) async {
      final gateway = _FakePermissionGateway(
        statuses: {Permission.notification: PermissionStatus.denied},
        requestResults: {Permission.notification: PermissionStatus.granted},
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: NotificationPreferencesScreen(
            permissionService: _androidService(gateway),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(gateway.requests, isEmpty);
      await tester.scrollUntilVisible(
        find.text('Push notifications'),
        280,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      final channel = find.byKey(
        const ValueKey('notification-channel-push-notifications'),
      );
      final toggle = find.descendant(
        of: channel,
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(gateway.requests, [Permission.notification]);
      expect(tester.widget<Switch>(toggle).value, isTrue);
    },
  );
}

AmoraaPermissionService _androidService(_FakePermissionGateway gateway) =>
    AmoraaPermissionService(
      gateway: gateway,
      targetPlatform: TargetPlatform.android,
      isWeb: false,
    );

class _FakePermissionGateway implements AmoraaPermissionGateway {
  _FakePermissionGateway({
    this.statuses = const {},
    this.requestResults = const {},
    this.locationServiceStatus = ServiceStatus.enabled,
  });

  final Map<Permission, PermissionStatus> statuses;
  final Map<Permission, PermissionStatus> requestResults;
  final ServiceStatus locationServiceStatus;
  final List<Permission> statusChecks = [];
  final List<Permission> requests = [];
  int appSettingsCalls = 0;
  int locationSettingsCalls = 0;

  @override
  Future<bool> openAppSettingsPage() async {
    appSettingsCalls++;
    return true;
  }

  @override
  Future<bool> openLocationSettingsPage() async {
    locationSettingsCalls++;
    return true;
  }

  @override
  Future<PermissionStatus> request(Permission permission) async {
    requests.add(permission);
    return requestResults[permission] ?? PermissionStatus.denied;
  }

  @override
  Future<ServiceStatus> serviceStatus(PermissionWithService permission) async =>
      locationServiceStatus;

  @override
  Future<PermissionStatus> status(Permission permission) async {
    statusChecks.add(permission);
    return statuses[permission] ?? PermissionStatus.denied;
  }
}
