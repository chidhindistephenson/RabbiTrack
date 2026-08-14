import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_controller.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/weights/weight_models.dart';

void main() {
  testWidgets('WeightListScreen labels rabbit and litter rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [weightListProvider.overrideWith((ref) async => _weights)],
        child: const MaterialApp(home: WeightListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Records'), findsOneWidget);
    expect(find.text('2 records'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('4.350 kg'), findsWidgets);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('2026-08-03'), findsWidgets);
    expect(find.text('DOE-0001'), findsOneWidget);
    expect(find.text('Rabbit | 2026-08-03 | Digital scale'), findsOneWidget);
    expect(find.text('LIT-260803-TEST'), findsOneWidget);
    expect(
      find.text('Litter total | 2026-08-04 | Field estimate'),
      findsOneWidget,
    );
    expect(find.text('2.750 kg total | 0.550 kg/kit'), findsOneWidget);
  });
}

const _weights = [
  WeightSummary(
    id: 'weight-1',
    rabbitIdentifier: 'DOE-0001',
    weighedOn: '2026-08-03',
    weightValue: '4.350',
    weightUnit: 'kg',
    method: 'Digital scale',
  ),
  WeightSummary(
    id: 'weight-2',
    litterIdentifier: 'LIT-260803-TEST',
    weighedOn: '2026-08-04',
    weightValue: '2.750',
    weightUnit: 'kg',
    kitCount: 5,
    averageWeightValue: '0.550',
    method: 'Field estimate',
  ),
];
