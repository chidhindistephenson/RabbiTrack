import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_status_screen.dart';

void main() {
  testWidgets('RabbitStatusScreen hides pregnancy statuses for male rabbits', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_maleRabbit));
    await tester.pumpAndSettle();

    expect(find.text('BUCK-0001 - Atlas'), findsOneWidget);
    expect(find.text('Current status: Growing'), findsOneWidget);
    expect(
      find.text('Pregnant and nursing are hidden because this rabbit is male.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Growing'));
    await tester.pumpAndSettle();

    expect(find.text('Pregnant'), findsNothing);
    expect(find.text('Nursing'), findsNothing);
    expect(find.text('Sold'), findsNothing);
    expect(find.text('Ready for sale'), findsOneWidget);
  });

  testWidgets(
    'RabbitStatusScreen shows pregnancy statuses for female rabbits',
    (tester) async {
      await tester.pumpWidget(_testApp(_femaleRabbit));
      await tester.pumpAndSettle();

      expect(find.text('DOE-0001 - Luna'), findsOneWidget);
      expect(
        find.text(
          'Female reproductive statuses are available for this rabbit.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Growing'));
      await tester.pumpAndSettle();

      expect(find.text('Pregnant'), findsOneWidget);
      expect(find.text('Nursing'), findsOneWidget);
    },
  );
}

Widget _testApp(RabbitDetail rabbit) {
  return ProviderScope(
    overrides: [
      rabbitDetailProvider('rabbit-1').overrideWith((ref) async => rabbit),
    ],
    child: const MaterialApp(home: RabbitStatusScreen(rabbitId: 'rabbit-1')),
  );
}

const _maleRabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'BUCK-0001',
  name: 'Atlas',
  sex: 'male',
  status: 'growing',
  movements: [],
);

const _femaleRabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'DOE-0001',
  name: 'Luna',
  sex: 'female',
  status: 'growing',
  movements: [],
);
