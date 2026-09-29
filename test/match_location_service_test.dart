import 'dart:async';

import 'package:amora_ai/core/permissions/amoraa_permission_service.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/data/match_location_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

class _PermissionGateway implements AmoraaPermissionGateway {
  _PermissionGateway({
    this.requested = PermissionStatus.granted,
    this.service = ServiceStatus.enabled,
  });

  PermissionStatus requested;
  ServiceStatus service;
  int requestCount = 0;

  @override
  Future<bool> openAppSettingsPage() async => true;

  @override
  Future<bool> openLocationSettingsPage() async => true;

  @override
  Future<PermissionStatus> request(Permission permission) async {
    requestCount += 1;
    return requested;
  }

  @override
  Future<ServiceStatus> serviceStatus(PermissionWithService permission) async =>
      service;

  @override
  Future<PermissionStatus> status(Permission permission) async =>
      PermissionStatus.denied;
}

class _PositionGateway implements MatchPositionGateway {
  _PositionGateway({this.error});

  final Object? error;
  int calls = 0;

  @override
  Future<MatchPosition> currentPosition() async {
    calls += 1;
    if (error != null) throw error!;
    return const MatchPosition(23.0225, 72.5714);
  }
}

class _ApiService extends DiscoverApiService {
  _ApiService({this.succeeds = true})
    : super(accessTokenProvider: () async => 'test-token');

  final bool succeeds;
  int uploads = 0;

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    uploads += 1;
    return succeeds
        ? const DiscoverApiResult.success(<String, dynamic>{
            'locationAvailable': true,
          }, statusCode: 200)
        : const DiscoverApiResult.failure(
            'Backend location update failed.',
            statusCode: 500,
          );
  }
}

MatchLocationService _service(
  _PermissionGateway permission,
  _PositionGateway position,
  _ApiService api,
) => MatchLocationService(
  permissionService: AmoraaPermissionService(
    gateway: permission,
    targetPlatform: TargetPlatform.android,
    isWeb: false,
  ),
  positionGateway: position,
  apiService: api,
);

void main() {
  test('location permission is not requested until the user enables it', () {
    final permission = _PermissionGateway();
    _service(permission, _PositionGateway(), _ApiService());
    expect(permission.requestCount, 0);
  });

  test(
    'allowed location obtains and uploads the foreground position',
    () async {
      final permission = _PermissionGateway();
      final position = _PositionGateway();
      final api = _ApiService();
      final result = await _service(
        permission,
        position,
        api,
      ).enableCurrentLocation();
      expect(result.outcome, MatchLocationOutcome.enabled);
      expect(permission.requestCount, 1);
      expect(position.calls, 1);
      expect(api.uploads, 1);
    },
  );

  test(
    'denied and permanently denied permissions do not obtain location',
    () async {
      for (final denied in <PermissionStatus>[
        PermissionStatus.denied,
        PermissionStatus.permanentlyDenied,
      ]) {
        final permission = _PermissionGateway(requested: denied);
        final position = _PositionGateway();
        final api = _ApiService();
        final result = await _service(
          permission,
          position,
          api,
        ).enableCurrentLocation();
        expect(
          result.outcome,
          denied == PermissionStatus.denied
              ? MatchLocationOutcome.denied
              : MatchLocationOutcome.permanentlyDenied,
        );
        expect(position.calls, 0);
        expect(api.uploads, 0);
      }
    },
  );

  test(
    'disabled location services are handled before permission request',
    () async {
      final permission = _PermissionGateway(service: ServiceStatus.disabled);
      final position = _PositionGateway();
      final result = await _service(
        permission,
        position,
        _ApiService(),
      ).enableCurrentLocation();
      expect(result.outcome, MatchLocationOutcome.serviceDisabled);
      expect(permission.requestCount, 0);
      expect(position.calls, 0);
    },
  );

  test(
    'position timeout and backend failure are safe explicit outcomes',
    () async {
      final timeout = await _service(
        _PermissionGateway(),
        _PositionGateway(error: TimeoutException('timeout')),
        _ApiService(),
      ).enableCurrentLocation();
      expect(timeout.outcome, MatchLocationOutcome.timedOut);

      final failed = await _service(
        _PermissionGateway(),
        _PositionGateway(),
        _ApiService(succeeds: false),
      ).enableCurrentLocation();
      expect(failed.outcome, MatchLocationOutcome.uploadFailed);
    },
  );
}
