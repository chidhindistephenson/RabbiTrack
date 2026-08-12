import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_controller.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_models.dart';

void main() {
  testWidgets('TaskListScreen renders polished task row labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [taskListProvider.overrideWith((ref) async => _tasks)],
        child: const MaterialApp(home: TaskListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prepare nest box'), findsOneWidget);
    expect(
      find.text(
        '2026-08-03 at 14:30 | Critical | Nest box | DOE-0001 | Cage A',
      ),
      findsOneWidget,
    );
  });
}

const _tasks = [
  TaskSummary(
    id: 'task-1',
    type: 'nest_box_preparation',
    title: 'Prepare nest box',
    dueOn: '2026-08-03',
    dueTime: '14:30',
    priority: 'critical',
    status: 'open',
    rabbitIdentifier: 'DOE-0001',
    locationName: 'Cage A',
  ),
];
