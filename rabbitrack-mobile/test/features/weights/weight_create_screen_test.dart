import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/litters/litter_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_create_screen.dart';

void main() {
  testWidgets('WeightCreateScreen shows rabbit empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitListProvider.overrideWith((ref) async => const []),
          litterListProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: WeightCreateScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active rabbits to weigh'), findsOneWidget);
    expect(find.text('Add rabbit'), findsOneWidget);
  });

  testWidgets('WeightCreateScreen locks rabbit target from rabbit profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider('rabbit-1').overrideWith((ref) async => _rabbit),
          rabbitListProvider.overrideWith((ref) async => const []),
          litterListProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: WeightCreateScreen(initialRabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(
      find.text('Rabbit weight will be saved to this profile.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'Rabbit'),
      findsNothing,
    );
    expect(find.text('Weight kg'), findsOneWidget);
    expect(find.text('Save weight'), findsOneWidget);
  });

  testWidgets('WeightCreateScreen blocks locked sold rabbit target', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => _soldRabbit),
          rabbitListProvider.overrideWith((ref) async => const []),
          litterListProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: WeightCreateScreen(initialRabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rabbit is no longer active'), findsOneWidget);
    expect(find.text('Save weight'), findsNothing);
  });
}

const _rabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'DOE-0001',
  name: 'Luna',
  sex: 'female',
  status: 'growing',
  movements: [],
);

const _soldRabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'DOE-0001',
  name: 'Luna',
  sex: 'female',
  status: 'sold',
  movements: [],
);
