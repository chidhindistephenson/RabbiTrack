import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/diagnostics/api_health_models.dart';

void main() {
  test('parses healthy API payload', () {
    final status = ApiHealthStatus.fromJson({
      'status': 'ok',
      'app': 'RabbiTrack',
      'checks': {'database': true, 'redis': true, 'demo_account': true},
    });

    expect(status.status, 'ok');
    expect(status.app, 'RabbiTrack');
    expect(status.checks['database'], isTrue);
    expect(status.isHealthy, isTrue);
  });

  test('treats degraded checks as unhealthy', () {
    final status = ApiHealthStatus.fromJson({
      'status': 'degraded',
      'checks': {'database': true, 'redis': false},
    });

    expect(status.isHealthy, isFalse);
    expect(status.checks['redis'], isFalse);
  });
}
