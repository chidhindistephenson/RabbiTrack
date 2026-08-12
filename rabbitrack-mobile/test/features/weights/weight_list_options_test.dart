import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_list_options.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_models.dart';

void main() {
  test('weightListCountText pluralizes records', () {
    expect(weightListCountText(1), '1 record');
    expect(weightListCountText(2), '2 records');
  });

  test('latestWeightDate and latestWeightValue use first record', () {
    expect(latestWeightDate(_weights), '2026-08-03');
    expect(latestWeightValue(_weights), '4.350 kg');
    expect(latestWeightDate(const []), '-');
    expect(latestWeightValue(const []), '-');
  });
}

const _weights = [
  WeightSummary(
    id: 'weight-1',
    rabbitIdentifier: 'DOE-0001',
    weighedOn: '2026-08-03',
    weightValue: '4.350',
    weightUnit: 'kg',
  ),
  WeightSummary(
    id: 'weight-2',
    rabbitIdentifier: 'DOE-0002',
    weighedOn: '2026-08-01',
    weightValue: '3.200',
    weightUnit: 'kg',
  ),
];
