import 'dart:async';

import 'package:amora_ai/core/permissions/amoraa_permission_service.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:geolocator/geolocator.dart';

class MatchPosition {
  const MatchPosition(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

abstract interface class MatchPositionGateway {
  Future<MatchPosition> currentPosition();
}

class GeolocatorMatchPositionGateway implements MatchPositionGateway {
  const GeolocatorMatchPositionGateway();

  @override
  Future<MatchPosition> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return MatchPosition(position.latitude, position.longitude);
  }
}

enum MatchLocationOutcome {
  enabled,
  denied,
  permanentlyDenied,
  serviceDisabled,
  unavailable,
  timedOut,
  uploadFailed,
}

class MatchLocationResult {
  const MatchLocationResult(this.outcome, this.message);

  final MatchLocationOutcome outcome;
  final String message;

  bool get enabled => outcome == MatchLocationOutcome.enabled;
}

class MatchLocationService {
  MatchLocationService({
    AmoraaPermissionService? permissionService,
    MatchPositionGateway? positionGateway,
    DiscoverApiService? apiService,
  }) : permissionService =
           permissionService ?? AmoraaPermissionService.instance,
       positionGateway =
           positionGateway ?? const GeolocatorMatchPositionGateway(),
       apiService = apiService ?? DiscoverApiService();

  final AmoraaPermissionService permissionService;
  final MatchPositionGateway positionGateway;
  final DiscoverApiService apiService;

  Future<MatchLocationResult> enableCurrentLocation() async {
    final permission = await permissionService.requestLocationPermission();
    switch (permission.state) {
      case AmoraaPermissionState.granted:
      case AmoraaPermissionState.notRequired:
        break;
      case AmoraaPermissionState.denied:
        return const MatchLocationResult(
          MatchLocationOutcome.denied,
          'Location was not enabled. Discover remains available without distance matching.',
        );
      case AmoraaPermissionState.permanentlyDenied:
      case AmoraaPermissionState.restricted:
        return const MatchLocationResult(
          MatchLocationOutcome.permanentlyDenied,
          'Location access is disabled. Open device settings to enable it.',
        );
      case AmoraaPermissionState.serviceDisabled:
        return const MatchLocationResult(
          MatchLocationOutcome.serviceDisabled,
          'Turn on device location services to use distance matching.',
        );
      case AmoraaPermissionState.unavailable:
        return const MatchLocationResult(
          MatchLocationOutcome.unavailable,
          'Current location is unavailable on this device.',
        );
    }
    try {
      final position = await positionGateway.currentPosition();
      final response = await apiService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!response.success) {
        return MatchLocationResult(
          MatchLocationOutcome.uploadFailed,
          response.message.isEmpty
              ? 'Could not save location for distance matching.'
              : response.message,
        );
      }
      return const MatchLocationResult(
        MatchLocationOutcome.enabled,
        'Current location enabled for distance matching.',
      );
    } on TimeoutException {
      return const MatchLocationResult(
        MatchLocationOutcome.timedOut,
        'Current location timed out. Please try again.',
      );
    } catch (_) {
      return const MatchLocationResult(
        MatchLocationOutcome.unavailable,
        'Current location could not be obtained. Please try again.',
      );
    }
  }
}
