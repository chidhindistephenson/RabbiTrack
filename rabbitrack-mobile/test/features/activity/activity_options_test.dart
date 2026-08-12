import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/activity/activity_options.dart';

void main() {
  test('activityActionLabel formats activity actions', () {
    expect(activityActionLabel('sale.recorded'), 'Sale');
    expect(activityActionLabel('expense.recorded'), 'Expense');
    expect(activityActionLabel('farm.updated'), 'Farm');
    expect(activityActionLabel('custom_action.created'), 'Custom action');
  });
}
