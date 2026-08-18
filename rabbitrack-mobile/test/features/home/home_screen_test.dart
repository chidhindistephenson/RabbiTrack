import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
        ],
        child: const MaterialApp(home: HomeScreen(farm: _farm)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Warren'), findsOneWidget);
    expect(find.text('Today on the farm'), findsOneWidget);
    expect(find.text('Breeding'), findsOneWidget);
    expect(find.text('4 open tasks'), findsNothing);
    expect(find.text('1 overdue, 2 due today.'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Herd status'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Does'), findsOneWidget);
    expect(find.text('Bucks'), findsOneWidget);
    expect(find.text('Live kits'), findsOneWidget);
    expect(find.text('Expected kindlings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Farm money'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Farm money'), findsOneWidget);
    expect(find.text('Recent activity'), findsNothing);
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
        ],
        child: const MaterialApp(home: HomeScreen(farm: _farm)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Warren'), findsOneWidget);
    expect(find.text('Dashboard unavailable'), findsOneWidget);
    expect(find.text('Tasks unavailable'), findsNothing);
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
  does: 7,
  bucks: 5,
  liveKits: 18,
  readyForSale: 3,
  healthAlerts: 1,
  quarantined: 0,
  pregnantDoes: 1,
  nursingDoes: 1,
  openTasks: 4,
  overdueTasks: 1,
  expectedKindlings: 2,
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

const _oddSummary = FarmSummaryCounts(
  activeRabbits: 0,
  does: 0,
  bucks: 0,
  liveKits: 0,
  readyForSale: 0,
  healthAlerts: 0,
  quarantined: 0,
  pregnantDoes: 0,
  nursingDoes: 0,
  openTasks: 0,
  overdueTasks: 0,
  expectedKindlings: 0,
  totalSales: 0,
  salesRevenue: 'NaN',
  totalExpenses: 'Infinity',
  netIncome: '-Infinity',
  currency: 'USD',
);
