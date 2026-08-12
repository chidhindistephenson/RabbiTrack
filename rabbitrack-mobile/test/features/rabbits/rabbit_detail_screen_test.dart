import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_detail_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_controller.dart';

void main() {
  testWidgets('RabbitDetailScreen shows a retry state when profile fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => throw StateError('offline')),
          rabbitWeightListProvider('rabbit-1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: RabbitDetailScreen(rabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load rabbit profile'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });

  testWidgets('RabbitDetailScreen renders profile details', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider('rabbit-1').overrideWith((ref) async => _rabbit),
          rabbitWeightListProvider('rabbit-1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: RabbitDetailScreen(rabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BUCK-0003'), findsAtLeastNWidgets(1));
    expect(find.text('Atlas'), findsOneWidget);
    expect(find.text('Ready for sale'), findsAtLeastNWidgets(1));
    expect(find.byTooltip('Edit profile'), findsAtLeastNWidgets(1));
    expect(find.text('Basic info'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Status'), findsAtLeastNWidgets(1));
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Sale record'), findsOneWidget);
    expect(find.text('Weight'), findsAtLeastNWidgets(1));
    await tester.scrollUntilVisible(
      find.text('Notes'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Strong breeder'), findsOneWidget);
  });

  testWidgets('RabbitDetailScreen renders unknown sex explicitly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => _unknownSexRabbit),
          rabbitWeightListProvider('rabbit-1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: RabbitDetailScreen(rabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('?'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('No notes recorded'), findsOneWidget);
  });

  testWidgets('RabbitDetailScreen locks active actions for sold rabbits', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rabbitDetailProvider(
            'rabbit-1',
          ).overrideWith((ref) async => _soldRabbit),
          rabbitWeightListProvider('rabbit-1').overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: RabbitDetailScreen(rabbitId: 'rabbit-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sold'), findsAtLeastNWidgets(1));
    expect(find.textContaining('profile is now historical'), findsOneWidget);
    expect(find.text('Move'), findsNothing);
    expect(find.text('Sale record'), findsOneWidget);
    expect(find.byTooltip('Edit profile'), findsNothing);
  });
}

const _rabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'BUCK-0003',
  name: 'Atlas',
  sex: 'male',
  status: 'ready_for_sale',
  movements: [],
  breed: 'New Zealand White',
  currentLocationName: 'Cage 1495',
  notes: 'Strong breeder',
);

const _unknownSexRabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'RAB-0001',
  sex: 'unknown',
  status: 'growing',
  movements: [],
);

const _soldRabbit = RabbitDetail(
  id: 'rabbit-1',
  identifier: 'BUCK-0003',
  name: 'Atlas',
  sex: 'male',
  status: 'sold',
  movements: [],
  breed: 'New Zealand White',
);
