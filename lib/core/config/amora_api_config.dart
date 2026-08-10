import 'package:flutter/foundation.dart';

/// Shared API location.
///
/// Set AMORA_API_BASE_URL to an HTTPS deployment or a LAN address
/// when running on a physical device.
///
/// Android emulators use the host loopback alias 10.0.2.2.
class AmoraApiConfig {
  const AmoraApiConfig._();

  static const _configuredBaseUrl = String.fromEnvironment(
    'AMORA_API_BASE_URL',
  );

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim().replaceFirst(
      RegExp(r'/$'),
      '',
    );

    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return 'http://localhost:5000';
    }

    return 'http://10.0.2.2:5000';
  }
}
