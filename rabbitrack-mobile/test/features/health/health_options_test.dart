import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/health/health_options.dart';

void main() {
  test('health labels format status, severity, and body systems', () {
    expect(healthStatusLabel('under_review'), 'Under review');
    expect(healthSeverityLabel('critical'), 'Critical');
    expect(healthBodySystemValue('Skin / coat'), 'skin_coat');
    expect(healthBodySystemLabel('respiratory'), 'Respiratory');
  });
}
