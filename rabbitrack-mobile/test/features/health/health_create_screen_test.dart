import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/health/health_create_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';

void main() {
  testWidgets('HealthCreateScreen shows health-specific inputs', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_rabbits));
    await tester.pumpAndSettle();

    expect(find.text('Body system'), findsOneWidget);
    expect(find.text('Symptoms'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Respiratory'), findsOneWidget);
    expect(find.text('Reproductive'), findsOneWidget);
  });

  testWidgets('HealthCreateScreen shows empty state without rabbits', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('No active rabbits available'), findsOneWidget);
    expect(find.text('Add rabbit'), findsOneWidget);
  });

  testWidgets('HealthCreateScreen blocks locked sold rabbit target', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitListProvider.overrideWith((ref) async => _soldRabbits),
          rabbitDetailProvider(
            'rabbit-2',
          ).overrideWith((ref) async => _soldRabbitDetail),
        ],
        child: const MaterialApp(
          home: HealthCreateScreen(initialRabbitId: 'rabbit-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rabbit is no longer active'), findsOneWidget);
    expect(find.text('Save health event'), findsNothing);
  });
}

Widget _testApp(List<RabbitSummary> rabbits) {
  return ProviderScope(
    overrides: [rabbitListProvider.overrideWith((ref) async => rabbits)],
    child: const MaterialApp(home: HealthCreateScreen()),
  );
}

const _rabbits = [
  RabbitSummary(
    id: 'rabbit-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'growing',
  ),
];

const _soldRabbits = [
  RabbitSummary(
    id: 'rabbit-2',
    identifier: 'DOE-0002',
    sex: 'female',
    status: 'sold',
  ),
];

const _soldRabbitDetail = RabbitDetail(
  id: 'rabbit-2',
  identifier: 'DOE-0002',
  sex: 'female',
  status: 'sold',
  movements: [],
);
