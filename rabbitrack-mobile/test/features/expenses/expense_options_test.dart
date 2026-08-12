import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_options.dart';

void main() {
  test('expenseCategoryLabel formats known and fallback categories', () {
    expect(expenseCategoryLabel('feed'), 'Feed');
    expect(expenseCategoryLabel('other_cost'), 'Other cost');
    expect(expenseCategories, contains('medicine'));
  });
}
