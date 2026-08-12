import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';
import 'package:rabbitrack_mobile/src/features/sales/sale_create_screen.dart';

void main() {
  testWidgets('SaleCreateScreen shows empty state without saleable rabbits', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_terminalRabbits));
    await tester.pumpAndSettle();

    expect(find.text('No rabbits available for sale'), findsOneWidget);
    expect(find.text('Add rabbit'), findsOneWidget);
    expect(find.text('Save sale'), findsNothing);
  });

  testWidgets('SaleCreateScreen locks rabbit target from rabbit profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitListProvider.overrideWith((ref) async => _saleableRabbits),
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => _saleableRabbitDetail),
        ],
        child: const MaterialApp(
          home: SaleCreateScreen(initialRabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('Sale will be recorded for this rabbit.'), findsOneWidget);
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'Rabbit'),
      findsNothing,
    );
    expect(find.text('Save sale'), findsOneWidget);
  });

  testWidgets('SaleCreateScreen warns when locked rabbit is not saleable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitListProvider.overrideWith((ref) async => _terminalRabbits),
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => _soldRabbitDetail),
        ],
        child: const MaterialApp(
          home: SaleCreateScreen(initialRabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This rabbit cannot be sold from its current status.'),
      findsOneWidget,
    );
  });
}

Widget _testApp(List<RabbitSummary> rabbits) {
  return ProviderScope(
    overrides: [rabbitListProvider.overrideWith((ref) async => rabbits)],
    child: const MaterialApp(home: SaleCreateScreen()),
  );
}

const _terminalRabbits = [
  RabbitSummary(
    id: 'rabbit-1',
    identifier: 'DOE-0001',
    sex: 'female',
    status: 'sold',
  ),
];

const _saleableRabbits = [
  RabbitSummary(
    id: 'rabbit-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'ready_for_sale',
  ),
];

const _saleableRabbitDetail = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'DOE-0001',
  name: 'Luna',
  sex: 'female',
  status: 'ready_for_sale',
  movements: [],
);

const _soldRabbitDetail = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'DOE-0001',
  name: 'Luna',
  sex: 'female',
  status: 'sold',
  movements: [],
);
