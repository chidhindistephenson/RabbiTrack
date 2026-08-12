import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/soft_list_tile.dart';

void main() {
  testWidgets('SoftListTile renders title, subtitle, and trailing content', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoftListTile(
            icon: Icons.home_work_outlined,
            title: 'Grow-out pen',
            subtitle: '4 / 8 occupied',
            trailing: const Text('Active'),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Grow-out pen'), findsOneWidget);
    expect(find.text('4 / 8 occupied'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await tester.tap(find.byType(SoftListTile));

    expect(tapped, isTrue);
  });
}
