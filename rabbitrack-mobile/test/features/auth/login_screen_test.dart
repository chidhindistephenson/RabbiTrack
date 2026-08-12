import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen prefills local demo credentials', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('owner@rabbitrack.local'), findsOneWidget);
    expect(find.text('secret-password'), findsOneWidget);
  });
}
