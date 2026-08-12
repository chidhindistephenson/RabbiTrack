import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/rabbit_icon.dart';

void main() {
  testWidgets('RabbitIcon renders outlined and filled variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              RabbitIcon(color: Colors.green, size: 24),
              RabbitIcon(color: Colors.green, size: 24, filled: true),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(RabbitIcon), findsNWidgets(2));
    expect(
      find.byWidgetPredicate((widget) => widget is RabbitIcon && widget.filled),
      findsOneWidget,
    );
  });
}
