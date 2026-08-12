import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/diagnostics/api_status_options.dart';

void main() {
  test('apiCheckLabel formats known and fallback checks', () {
    expect(apiCheckLabel('database'), 'Database');
    expect(apiCheckLabel('demo_account'), 'Demo account');
    expect(apiCheckLabel('queue_worker'), 'Queue worker');
  });

  test('apiBaseUrlMode describes common Android endpoints', () {
    expect(apiBaseUrlMode('http://10.0.2.2:8000/api/v1'), 'Android emulator');
    expect(apiBaseUrlMode('http://127.0.0.1:8000/api/v1'), 'This device only');
    expect(
      apiBaseUrlMode('http://192.168.1.128:8000/api/v1'),
      'Wireless device',
    );
  });

  test('apiTroubleshootingSteps gives wireless guidance', () {
    final steps = apiTroubleshootingSteps('http://192.168.1.128:8000/api/v1');

    expect(
      steps,
      contains('Confirm phone and computer are on the same Wi-Fi.'),
    );
    expect(steps, contains('Confirm Windows Firewall allows TCP port 8000.'));
  });
}
