import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/detail_section.dart';

void main() {
  testWidgets('DetailSection renders section title and rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DetailSection(
            title: 'Details',
            children: [
              DetailInfoRow('Status', 'available for breeding'),
              DetailInfoRow('Location', 'Cage A1'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('available for breeding'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Cage A1'), findsOneWidget);
  });
}
