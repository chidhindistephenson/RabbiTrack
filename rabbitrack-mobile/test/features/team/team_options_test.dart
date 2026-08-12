import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/team/team_options.dart';

void main() {
  test('farmRoleLabel formats roles', () {
    expect(farmRoleLabel('owner'), 'Owner');
    expect(farmRoleLabel('administrator'), 'Administrator');
    expect(farmRoleLabel('field_worker'), 'Field worker');
    expect(assignableFarmRoles, isNot(contains('owner')));
  });
}
