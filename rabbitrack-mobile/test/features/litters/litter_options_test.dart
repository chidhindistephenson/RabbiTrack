import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_options.dart';

void main() {
  test('litterStatusLabel formats litter statuses', () {
    expect(litterStatusLabel('nursing'), 'Nursing');
    expect(litterStatusLabel('weaned'), 'Weaned');
    expect(litterStatusLabel('ready_for_sale'), 'Ready for sale');
  });
}
