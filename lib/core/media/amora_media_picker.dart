import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum AmoraMediaSource { camera, gallery }

enum AmoraMediaIssue {
  cancelled,
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
  unsupported,
  cameraUnavailable,
  tooLarge,
  invalidImage,
  failed,
}

class AmoraPickedMedia {
  const AmoraPickedMedia({
    required this.dataUri,
    required this.name,
    required this.byteLength,
    this.bytes,
  });

  final String dataUri;
  final String name;
  final int byteLength;
  final Uint8List? bytes;
}

class AmoraMediaPickResult {
  const AmoraMediaPickResult.success(this.media) : issue = null, message = null;

  const AmoraMediaPickResult.failure(this.issue, this.message) : media = null;

  final AmoraPickedMedia? media;
  final AmoraMediaIssue? issue;
  final String? message;

  bool get succeeded => media != null;
  bool get canOpenSettings =>
      issue == AmoraMediaIssue.permissionPermanentlyDenied;
  bool get canRetry => issue == AmoraMediaIssue.permissionDenied;
}

abstract interface class AmoraMediaPicker {
  Future<AmoraMediaPickResult> pickImage({required AmoraMediaSource source});

  Future<bool> openSettings();
}

class DeviceAmoraMediaPicker implements AmoraMediaPicker {
  const DeviceAmoraMediaPicker();

  static const int maximumImageBytes = 12 * 1024 * 1024;

  @override
  Future<AmoraMediaPickResult> pickImage({
    required AmoraMediaSource source,
  }) async {
    if (kIsWeb && source == AmoraMediaSource.camera) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.unsupported,
        'Camera capture is unavailable in this browser. Choose a photo from your device instead.',
      );
    }

    if (!kIsWeb &&
        source == AmoraMediaSource.camera &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.unsupported,
        'Camera capture is not available on this device. Choose a photo instead.',
      );
    }

    final permissionResult = await _requestPermission(source);
    if (permissionResult != null) return permissionResult;

    try {
      final file = await ImagePicker().pickImage(
        source: source == AmoraMediaSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2560,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (file == null) {
        return const AmoraMediaPickResult.failure(
          AmoraMediaIssue.cancelled,
          'Image selection was cancelled.',
        );
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const AmoraMediaPickResult.failure(
          AmoraMediaIssue.invalidImage,
          'That image is empty. Choose another JPEG, PNG, or WebP image.',
        );
      }
      if (bytes.lengthInBytes > maximumImageBytes) {
        return const AmoraMediaPickResult.failure(
          AmoraMediaIssue.tooLarge,
          'That image is larger than 12 MB. Choose a smaller image.',
        );
      }

      final mimeType = _supportedMimeType(bytes);
      if (mimeType == null) {
        return const AmoraMediaPickResult.failure(
          AmoraMediaIssue.invalidImage,
          'Choose a valid JPEG, PNG, or WebP image.',
        );
      }

      return AmoraMediaPickResult.success(
        AmoraPickedMedia(
          dataUri: 'data:$mimeType;base64,${base64Encode(bytes)}',
          name: file.name,
          byteLength: bytes.lengthInBytes,
          bytes: bytes,
        ),
      );
    } on PlatformException catch (error) {
      return _platformFailure(error);
    } catch (_) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.failed,
        'The image could not be opened. Try again or choose another image.',
      );
    }
  }

  Future<AmoraMediaPickResult?> _requestPermission(
    AmoraMediaSource source,
  ) async {
    if (kIsWeb) return null;

    Permission? permission;
    if (source == AmoraMediaSource.camera) {
      permission = Permission.camera;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      permission = Permission.photos;
    }
    if (permission == null) return null;

    final status = await permission.request();
    if (status.isGranted || status.isLimited) return null;
    if (status.isPermanentlyDenied) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.permissionPermanentlyDenied,
        'Access is disabled in system settings. Open settings to allow it.',
      );
    }
    if (status.isRestricted) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.permissionRestricted,
        'Access is restricted on this device. Check parental or device-management settings.',
      );
    }
    return AmoraMediaPickResult.failure(
      AmoraMediaIssue.permissionDenied,
      source == AmoraMediaSource.camera
          ? 'Camera access is needed to take a photo.'
          : 'Photo access is needed to choose an image.',
    );
  }

  AmoraMediaPickResult _platformFailure(PlatformException error) {
    final code = error.code.toLowerCase();
    if (code.contains('permanently') ||
        code.contains('without_prompt') ||
        code.contains('restricted')) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.permissionPermanentlyDenied,
        'Access is disabled in system settings. Open settings to allow it.',
      );
    }
    if (code.contains('denied')) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.permissionDenied,
        'Permission was denied. You can retry when you are ready.',
      );
    }
    if (code.contains('camera') &&
        (code.contains('unavailable') || code.contains('not_found'))) {
      return const AmoraMediaPickResult.failure(
        AmoraMediaIssue.cameraUnavailable,
        'No available camera was found. Choose a photo instead.',
      );
    }
    return const AmoraMediaPickResult.failure(
      AmoraMediaIssue.failed,
      'The image picker could not be opened. Try again.',
    );
  }

  String? _supportedMimeType(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}

void showAmoraMediaResult(
  BuildContext context, {
  required AmoraMediaPickResult result,
  required AmoraMediaPicker picker,
  VoidCallback? onRetry,
}) {
  final message = result.message;
  if (message == null) return;

  final action = result.canOpenSettings
      ? SnackBarAction(
          label: 'Open settings',
          onPressed: () {
            picker.openSettings();
          },
        )
      : result.canRetry && onRetry != null
      ? SnackBarAction(label: 'Retry', onPressed: onRetry)
      : null;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
