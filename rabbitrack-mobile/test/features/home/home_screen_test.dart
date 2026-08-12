import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/activity/activity_controller.dart';
import 'package:rabbitrack_mobile/src/features/activity/activity_models.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_models.dart';
import 'package:rabbitrack_mobile/src/features/home/farm_summary_controller.dart';
import 'package:rabbitrack_mobile/src/features/home/farm_summary_models.dart';
import 'package:rabbitrack_mobile/src/features/home/home_screen.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_controller.dart';
import 'package:rabbitrack_mobile/src/features/tasks/task_models.dart';

void main() {
  testWidgets('HomeScreen renders dashboard content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmSummaryProvider.overrideWith((ref) async => _summary),
          taskSummaryProvider.overrideWith((ref) async => _taskSummary),
          taskListProvider.overrideWith((ref) async => _tasks),
          activityListProvider.overrideWith((ref) async => _activity),
        ],
        child: const MaterialApp(home: HomeScreen(farm: _farm)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Warren'), findsOneWidget);
    expect(find.text('Today on the farm'), findsOneWidget);
    expect(find.text('Task focus'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Farm money'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Farm money'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent activity'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Care calendar'), findsNothing);
    expect(find.text('At a glance'), findsNothing);
  });

  testWidgets('HomeScreen shows fallback cards when dashboard providers fail', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          farmSummaryProvider.overrideWith((ref) => Future.error('offline')),
          taskSummaryProvider.overrideWith((ref) => Future.error('offline')),
          taskListProvider.overrideWith((ref) => Future.error('offline')),
          activityListProvider.overrideWith((ref) => Future.error('offline')),
        ],
        child: const MaterialApp(home: HomeScreen(farm: _farm)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Warren'), findsOneWidget);
    expect(find.text('Dashboard unavailable'), findsOneWidget);
    expect(find.text('Finance unavailable'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Priorities unavailable'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Priorities unavailable'), findsOneWidget);
  });

  testWidgets(
    'HomeScreen tolerates narrow screens and unusual finance values',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            farmSummaryProvider.overrideWith((ref) async => _oddSummary),
            taskSummaryProvider.overrideWith((ref) async => _taskSummary),
            taskListProvider.overrideWith((ref) async => _tasks),
            activityListProvider.overrideWith((ref) async => _activity),
          ],
          child: const MaterialApp(home: HomeScreen(farm: _farm)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Warren'), findsOneWidget);
      expect(find.text('Today on the farm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

const _farm = FarmSummary(
  id: 'farm-1',
  name: 'Test Warren',
  code: 'TEST',
  role: 'owner',
  timezone: 'Africa/Harare',
  currency: 'USD',
);

const _summary = FarmSummaryCounts(
  activeRabbits: 12,
  readyForSale: 3,
  healthAlerts: 1,
  quarantined: 0,
  openTasks: 4,
  totalSales: 2,
  salesRevenue: '40.00',
  totalExpenses: '12.50',
  netIncome: '27.50',
  currency: 'USD',
);

const _taskSummary = TaskSummaryCounts(today: 2, overdue: 1, open: 4);

const _tasks = [
  TaskSummary(
    id: 'task-1',
    type: 'health_check',
    title: 'Check doe',
    dueOn: '2026-08-03',
    priority: 'high',
    status: 'open',
    rabbitIdentifier: 'DOE-0001',
  ),
];

const _activity = [
  ActivityLogSummary(
    id: 'activity-1',
    action: 'rabbit.created',
    description: 'Created DOE-0001.',
    createdAt: '2026-08-03 10:00:00',
  ),
];

const _oddSummary = FarmSummaryCounts(
  activeRabbits: 0,
  readyForSale: 0,
  healthAlerts: 0,
  quarantined: 0,
  openTasks: 0,
  totalSales: 0,
  salesRevenue: 'NaN',
  totalExpenses: 'Infinity',
  netIncome: '-Infinity',
  currency: 'USD',
);
