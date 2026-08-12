import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_models.dart';
import 'package:rabbitrack_mobile/src/features/farms/farm_selection_options.dart';

void main() {
  test('farmSelectionSubtitle formats farm role and currency', () {
    expect(farmSelectionSubtitle(_farm), r'MAIN | Owner | $');
  });

  test('farmSelectionHeader describes the next action', () {
    expect(
      farmSelectionHeader(farmCount: 0, hasSelectedFarm: false),
      'Create your first farm to start using RabbiTrack.',
    );
    expect(
      farmSelectionHeader(farmCount: 1, hasSelectedFarm: false),
      'Select your farm to continue.',
    );
    expect(
      farmSelectionHeader(farmCount: 2, hasSelectedFarm: false),
      'Select the farm you want to work in.',
    );
    expect(
      farmSelectionHeader(farmCount: 2, hasSelectedFarm: true),
      'Choose a farm to switch your active rabbitry.',
    );
  });
}

const _farm = FarmSummary(
  id: 'farm-1',
  name: 'Main Farm',
  code: 'MAIN',
  role: 'owner',
  timezone: 'Africa/Harare',
  currency: 'USD',
);
