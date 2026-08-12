import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/farms/farm_selection_screen.dart';

void main() {
  testWidgets('FarmSelectionScreen shows signed-out state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FarmSelectionScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.text('Sign in before choosing a farm.'), findsOneWidget);
  });
}
