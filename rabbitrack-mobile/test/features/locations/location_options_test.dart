import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_models.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_options.dart';

void main() {
  test('location labels and occupancy helpers format values', () {
    expect(locationTypeLabel('cage'), 'Cage');
    expect(locationTypeLabel('grow_out'), 'Grow out');
    expect(locationOccupancyLabel(3, 5), '3 / 5 occupied');
    expect(locationOccupancyLabel(3, null), '3 occupied');
    expect(locationOccupancyRatio(2, 4), 0.5);
    expect(locationOccupancyRatio(4, 2), 1);
  });

  test('location summary helpers format list totals', () {
    expect(locationCountLabel(1), '1 location');
    expect(locationCountLabel(3), '3 locations');
    expect(activeLocationCountLabel(_locations), '2 active');
    expect(locationCapacitySummaryLabel(_locations), '4 / 7 occupied');
    expect(locationCapacitySummaryLabel(_uncappedLocations), '3 occupied');
    expect(locationCapacityStatusLabel(3, null), '3 assigned');
    expect(locationCapacityStatusLabel(3, 5), '2 spaces available');
    expect(locationCapacityStatusLabel(4, 5), '1 space available');
    expect(locationCapacityStatusLabel(5, 5), 'Full');
  });

  test('location create guidance follows type', () {
    expect(
      locationTypeGuidance('cage'),
      'Use cages for individual rabbits or small groups.',
    );
    expect(
      locationTypeGuidance('house'),
      'Use houses for major buildings or rabbitry blocks.',
    );
    expect(
      locationCapacityGuidance('cage'),
      'Set capacity to avoid overcrowding.',
    );
    expect(
      locationCapacityGuidance('row'),
      'Capacity is optional for broad areas.',
    );
  });
}

const _locations = [
  FarmLocationSummary(
    id: 'location-1',
    type: 'cage',
    name: 'Cage A',
    capacity: 5,
    occupiedCount: 3,
    isActive: true,
  ),
  FarmLocationSummary(
    id: 'location-2',
    type: 'cage',
    name: 'Cage B',
    capacity: 2,
    occupiedCount: 1,
    isActive: false,
  ),
  FarmLocationSummary(
    id: 'location-3',
    type: 'row',
    name: 'Row A',
    occupiedCount: 0,
    isActive: true,
  ),
];

const _uncappedLocations = [
  FarmLocationSummary(
    id: 'location-1',
    type: 'row',
    name: 'Row A',
    occupiedCount: 3,
    isActive: true,
  ),
];
