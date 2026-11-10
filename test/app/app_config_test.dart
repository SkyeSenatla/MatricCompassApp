import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/app_config.dart';

void main() {
  group('AppConfig.parse', () {
    test('reads a matching flavour and config', () {
      final config = AppConfig.parse(
        nativeFlavor: 'dev',
        flavorName: 'dev',
        apiBaseUrl: 'http://10.0.2.2:5146',
      );
      expect(config.flavor, Flavor.dev);
      expect(config.apiBaseUrl, 'http://10.0.2.2:5146');
    });

    test('refuses to start without a config file', () {
      expect(
        () => AppConfig.parse(
          nativeFlavor: 'dev',
          flavorName: '',
          apiBaseUrl: '',
        ),
        throwsStateError,
      );
    });

    test('refuses a prod build given the dev config', () {
      expect(
        () => AppConfig.parse(
          nativeFlavor: 'prod',
          flavorName: 'dev',
          apiBaseUrl: 'http://10.0.2.2:5146',
        ),
        throwsStateError,
      );
    });
  });
}
