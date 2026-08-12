import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/snackbars.dart';

void main() {
  testWidgets('showErrorSnackBar displays the supplied message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _snackBarTestApp(
        onPressed: (context) =>
            showErrorSnackBar(context, 'Could not save record.'),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('Could not save record.'), findsOneWidget);
  });

  testWidgets('showSuccessSnackBar displays the supplied message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _snackBarTestApp(
        onPressed: (context) =>
            showSuccessSnackBar(context, 'Rabbit DOE-0048 created.'),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('Rabbit DOE-0048 created.'), findsOneWidget);
  });
}

Widget _snackBarTestApp({required void Function(BuildContext) onPressed}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () => onPressed(context),
            child: const Text('Show'),
          );
        },
      ),
    ),
  );
}
