import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/farms/farm_settings_screen.dart';

void main() {
  testWidgets('FarmSettingsScreen asks for a selected farm', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FarmSettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select a farm first'), findsOneWidget);
    expect(
      find.text('Choose a farm before editing farm settings.'),
      findsOneWidget,
    );
  });
}
