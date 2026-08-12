import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_create_screen.dart';

void main() {
  testWidgets('LocationCreateScreen shows type-specific guidance', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LocationCreateScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cage setup'), findsOneWidget);
    expect(
      find.text('Use cages for individual rabbits or small groups.'),
      findsOneWidget,
    );
    expect(find.text('Set capacity to avoid overcrowding.'), findsOneWidget);

    await tester.tap(find.text('Cage').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('House').last);
    await tester.pumpAndSettle();

    expect(find.text('House setup'), findsOneWidget);
    expect(
      find.text('Use houses for major buildings or rabbitry blocks.'),
      findsOneWidget,
    );
    expect(find.text('Capacity is optional for broad areas.'), findsOneWidget);
  });
}
