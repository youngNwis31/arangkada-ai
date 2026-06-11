import 'package:flutter_test/flutter_test.dart';
import 'package:arangkada_ai/config/app_config.dart';

void main() {
  test('App config values are set', () {
    expect(AppConfig.appName, 'Arangkada AI');
    expect(AppConfig.appVersion, 'v0.01');
    expect(AppConfig.developer, 'James Earl Medrano');
  });
}
