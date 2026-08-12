import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/farms/farm_create_screen.dart';

void main() {
  testWidgets('FarmCreateScreen shows signed-out state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FarmCreateScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.text('Sign in before creating a farm.'), findsOneWidget);
  });
}
