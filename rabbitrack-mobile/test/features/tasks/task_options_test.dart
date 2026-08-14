import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_options.dart';

void main() {
  test('task option labels format task values', () {
    expect(taskTypeLabel('nest_box_preparation'), 'Nest box');
    expect(taskPriorityLabel('critical'), 'Critical');
    expect(taskStatusLabel('in_review'), 'In review');
    expect(taskDueLabel('2026-08-03', '14:30'), '2026-08-03 at 14:30');
    expect(taskDueLabel('2026-08-03', null), '2026-08-03');
    expect(taskDueFilterTitle('overdue'), 'Overdue');
  });
}
