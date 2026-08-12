import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/team/team_add_screen.dart';

void main() {
  testWidgets('TeamAddScreen blocks non-owner access', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: TeamAddScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Owner access required'), findsOneWidget);
    expect(
      find.text('Only farm owners can add or invite team members.'),
      findsOneWidget,
    );
  });
}
