import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/app_state.dart';
import 'package:rabbitrack_mobile/src/shared/rabbit_icon.dart';

void main() {
  testWidgets('AppState can render a custom icon widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppState(
            icon: Icons.search,
            iconWidget: RabbitIcon(color: Colors.green, size: 32),
            title: 'No rabbits yet',
            message: 'Add your first rabbit.',
          ),
        ),
      ),
    );

    expect(find.byType(RabbitIcon), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.text('No rabbits yet'), findsOneWidget);
  });
}
