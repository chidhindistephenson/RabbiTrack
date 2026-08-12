import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/config/api_config.dart';

void main() {
  test('uses Android emulator API base URL by default', () {
    expect(ApiConfig.baseUrl, 'http://10.0.2.2:8000/api/v1');
  });
}
