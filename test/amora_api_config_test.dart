import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _configuredBaseUrl = String.fromEnvironment('AMORA_API_BASE_URL');
const _expectRelease = bool.fromEnvironment('AMORA_TEST_EXPECT_RELEASE');

void main() {
  test(
    'API base URL follows the release default or explicit deployment URL',
    () {
      if (_expectRelease) {
        expect(kReleaseMode, isTrue);
      }

      final expectedBaseUrl = _configuredBaseUrl.isNotEmpty
          ? _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '')
          : kReleaseMode
          ? 'https://api.searchenginemonks.com'
          : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:5000'
          : 'http://localhost:5000';

      expect(AmoraApiConfig.baseUrl, expectedBaseUrl);
    },
  );
}
