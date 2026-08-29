import 'package:flutter/foundation.dart';

/// Shared API location.
///
/// Set AMORA_API_BASE_URL to an HTTPS deployment or the development machine's
/// LAN URL when running on a physical device.
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
      final uri = Uri.tryParse(configured);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        throw StateError('AMORA_API_BASE_URL must be an absolute URL.');
      }
      if (kReleaseMode && uri.scheme != 'https') {
        throw StateError('Release builds require an HTTPS API URL.');
      }
      return configured;
    }

    if (kReleaseMode) {
      throw StateError('AMORA_API_BASE_URL is required for release builds.');
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }
}
