import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_create_screen.dart';

void main() {
  testWidgets('ExpenseCreateScreen exposes category and notes controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ExpenseCreateScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Medicine'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
  });
}
