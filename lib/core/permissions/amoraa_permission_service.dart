import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum AmoraaPermissionCategory {
  camera,
  location,
  notifications,
  photos,
  videos,
}

enum AmoraaPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
  serviceDisabled,
  notRequired,
}

@immutable
class AmoraaPermissionResult {
  const AmoraaPermissionResult(this.state, this.message);

  final AmoraaPermissionState state;
  final String message;

  bool get allowsFeature =>
      state == AmoraaPermissionState.granted ||
      state == AmoraaPermissionState.notRequired;
  bool get shouldOpenSettings =>
      state == AmoraaPermissionState.permanentlyDenied ||
      state == AmoraaPermissionState.serviceDisabled;
}

abstract interface class AmoraaPermissionGateway {
  Future<PermissionStatus> status(Permission permission);

  Future<PermissionStatus> request(Permission permission);

  Future<ServiceStatus> serviceStatus(PermissionWithService permission);

  Future<bool> openAppSettingsPage();

  Future<bool> openLocationSettingsPage();
}

class PermissionHandlerGateway implements AmoraaPermissionGateway {
  const PermissionHandlerGateway();

  static const _channel = MethodChannel('com.amoraa/permissions');

  @override
  Future<PermissionStatus> status(Permission permission) => permission.status;

  @override
  Future<PermissionStatus> request(Permission permission) =>
      permission.request();

  @override
  Future<ServiceStatus> serviceStatus(PermissionWithService permission) =>
      permission.serviceStatus;

  @override
  Future<bool> openAppSettingsPage() => openAppSettings();

  @override
  Future<bool> openLocationSettingsPage() async {
    try {
      return await _channel.invokeMethod<bool>('openLocationSettings') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

class AmoraaPermissionService {
  AmoraaPermissionService({
    this.gateway = const PermissionHandlerGateway(),
    this.targetPlatform,
    this.isWeb,
  });

  static final instance = AmoraaPermissionService();

  final AmoraaPermissionGateway gateway;
  final TargetPlatform? targetPlatform;
  final bool? isWeb;
  bool _notificationRequestedInSession = false;

  TargetPlatform get _platform => targetPlatform ?? defaultTargetPlatform;
  bool get _runningOnWeb => isWeb ?? kIsWeb;
  bool get _isMobile =>
      !_runningOnWeb &&
      (_platform == TargetPlatform.android || _platform == TargetPlatform.iOS);

  Future<AmoraaPermissionResult> requestCameraPermission() => _request(
    AmoraaPermissionCategory.camera,
    Permission.camera,
    unavailableMessage: 'Camera capture is unavailable on this device.',
  );

  Future<AmoraaPermissionResult> requestLocationPermission() async {
    if (!_isMobile) {
      return const AmoraaPermissionResult(
        AmoraaPermissionState.unavailable,
        'Location access is unavailable on this device.',
      );
    }
    try {
      final service = await gateway.serviceStatus(Permission.locationWhenInUse);
      if (service == ServiceStatus.disabled) {
        return const AmoraaPermissionResult(
          AmoraaPermissionState.serviceDisabled,
          'Turn on location services to use this feature.',
        );
      }
    } catch (_) {
      return const AmoraaPermissionResult(
        AmoraaPermissionState.unavailable,
        'Location access is unavailable on this device.',
      );
    }
    return _request(
      AmoraaPermissionCategory.location,
      Permission.locationWhenInUse,
      unavailableMessage: 'Location access is unavailable on this device.',
    );
  }

  Future<AmoraaPermissionResult> notificationPermissionStatus() => _status(
    AmoraaPermissionCategory.notifications,
    Permission.notification,
    unavailableMessage: 'Notifications are unavailable on this device.',
  );

  Future<AmoraaPermissionResult> requestNotificationPermission() async {
    final current = await notificationPermissionStatus();
    if (current.state != AmoraaPermissionState.denied) return current;
    if (_notificationRequestedInSession) return current;
    _notificationRequestedInSession = true;
    return _request(
      AmoraaPermissionCategory.notifications,
      Permission.notification,
      unavailableMessage: 'Notifications are unavailable on this device.',
      checkStatusFirst: false,
    );
  }

  /// Android's system Photo Picker grants access only to the selected media,
  /// so it deliberately avoids broad gallery permission on every Android API.
  Future<AmoraaPermissionResult> requestPhotoPermission({
    bool usesSystemPicker = true,
  }) {
    if (_platform == TargetPlatform.android && usesSystemPicker) {
      return Future.value(
        const AmoraaPermissionResult(
          AmoraaPermissionState.notRequired,
          'The Android system picker provides access to the selected photo.',
        ),
      );
    }
    return _request(
      AmoraaPermissionCategory.photos,
      Permission.photos,
      unavailableMessage: 'Photo selection is unavailable on this device.',
    );
  }

  /// Kept available for existing/future video pickers without introducing a
  /// video-upload feature or requesting media access at application startup.
  Future<AmoraaPermissionResult> requestVideoPermission({
    bool usesSystemPicker = true,
  }) {
    if (_platform == TargetPlatform.android && usesSystemPicker) {
      return Future.value(
        const AmoraaPermissionResult(
          AmoraaPermissionState.notRequired,
          'The Android system picker provides access to the selected video.',
        ),
      );
    }
    return _request(
      AmoraaPermissionCategory.videos,
      Permission.videos,
      unavailableMessage: 'Video selection is unavailable on this device.',
    );
  }

  Future<bool> openSettings({bool locationServices = false}) => locationServices
      ? gateway.openLocationSettingsPage()
      : gateway.openAppSettingsPage();

  Future<AmoraaPermissionResult> _status(
    AmoraaPermissionCategory category,
    Permission permission, {
    required String unavailableMessage,
  }) async {
    if (!_isMobile) {
      return AmoraaPermissionResult(
        AmoraaPermissionState.unavailable,
        unavailableMessage,
      );
    }
    try {
      return _map(category, await gateway.status(permission));
    } catch (_) {
      return AmoraaPermissionResult(
        AmoraaPermissionState.unavailable,
        unavailableMessage,
      );
    }
  }

  Future<AmoraaPermissionResult> _request(
    AmoraaPermissionCategory category,
    Permission permission, {
    required String unavailableMessage,
    bool checkStatusFirst = true,
  }) async {
    if (!_isMobile) {
      return AmoraaPermissionResult(
        AmoraaPermissionState.unavailable,
        unavailableMessage,
      );
    }
    try {
      if (checkStatusFirst) {
        final current = await gateway.status(permission);
        if (current != PermissionStatus.denied) return _map(category, current);
      }
      return _map(category, await gateway.request(permission));
    } catch (_) {
      return AmoraaPermissionResult(
        AmoraaPermissionState.unavailable,
        unavailableMessage,
      );
    }
  }

  static AmoraaPermissionResult _map(
    AmoraaPermissionCategory category,
    PermissionStatus status,
  ) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => AmoraaPermissionResult(
      AmoraaPermissionState.granted,
      '${_label(category)} access is enabled.',
    ),
    PermissionStatus.permanentlyDenied => AmoraaPermissionResult(
      AmoraaPermissionState.permanentlyDenied,
      '${_explanation(category)} Open Settings to allow it.',
    ),
    PermissionStatus.restricted => AmoraaPermissionResult(
      AmoraaPermissionState.restricted,
      '${_label(category)} access is restricted by this device.',
    ),
    PermissionStatus.denied => AmoraaPermissionResult(
      AmoraaPermissionState.denied,
      _deniedMessage(category),
    ),
  };

  static String _label(AmoraaPermissionCategory category) => switch (category) {
    AmoraaPermissionCategory.camera => 'Camera',
    AmoraaPermissionCategory.location => 'Location',
    AmoraaPermissionCategory.notifications => 'Notification',
    AmoraaPermissionCategory.photos => 'Photo',
    AmoraaPermissionCategory.videos => 'Video',
  };

  static String _explanation(
    AmoraaPermissionCategory category,
  ) => switch (category) {
    AmoraaPermissionCategory.camera =>
      'Camera access is needed to take profile photos and complete selfie verification.',
    AmoraaPermissionCategory.location =>
      'Location access helps AMORAA use the existing location-based experience.',
    AmoraaPermissionCategory.notifications =>
      'Notification access lets AMORAA deliver supported messages and account updates.',
    AmoraaPermissionCategory.photos =>
      'Photo access is needed to select profile photos from your device.',
    AmoraaPermissionCategory.videos =>
      'Video access is needed for video selection.',
  };

  static String _deniedMessage(
    AmoraaPermissionCategory category,
  ) => switch (category) {
    AmoraaPermissionCategory.camera =>
      'Camera access is needed to take profile photos and complete selfie verification.',
    AmoraaPermissionCategory.location =>
      'Location access helps AMORAA use the existing location-based experience.',
    AmoraaPermissionCategory.notifications =>
      'Notifications are turned off. Enable notifications in Settings to receive messages, matches, and important account updates.',
    AmoraaPermissionCategory.photos =>
      'Photo access is needed to select profile photos from your device.',
    AmoraaPermissionCategory.videos =>
      'Video access is needed for video selection.',
  };
}

Future<void> showAmoraaPermissionFeedback(
  BuildContext context, {
  required AmoraaPermissionCategory category,
  required AmoraaPermissionResult result,
  required AmoraaPermissionService service,
}) async {
  if (result.allowsFeature || !context.mounted) return;
  if (result.shouldOpenSettings) {
    final locationServices =
        result.state == AmoraaPermissionState.serviceDisabled;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          locationServices
              ? 'Location services are turned off'
              : '${AmoraaPermissionService._label(category)} access is turned off',
        ),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              service.openSettings(locationServices: locationServices);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(result.message)));
}
