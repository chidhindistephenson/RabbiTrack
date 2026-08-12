import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:rabbitrack_mobile/src/features/diagnostics/api_health_controller.dart';
import 'package:rabbitrack_mobile/src/features/diagnostics/api_health_models.dart';
import 'package:rabbitrack_mobile/src/app.dart';

void main() {
  testWidgets('RabbiTrack login shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RabbiTrackApp()));
    await tester.pumpAndSettle();

    expect(find.text('RabbiTrack'), findsOneWidget);
    expect(find.text("Let's continue your farm journey"), findsOneWidget);
    expect(find.text('Email, username, or phone'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('API status is reachable before login', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiHealthProvider.overrideWith((ref) async => _health)],
        child: const RabbiTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.text('Continue'))).go('/api-status');
    await tester.pumpAndSettle();

    expect(find.text('API status'), findsOneWidget);
    expect(find.text('API ready'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text("Let's continue your farm journey"), findsOneWidget);
  });

  testWidgets('protected routes still redirect to login when signed out', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RabbiTrackApp()));
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.text('Continue'))).go('/rabbits');
    await tester.pumpAndSettle();

    expect(find.text("Let's continue your farm journey"), findsOneWidget);
    expect(find.text('Email, username, or phone'), findsOneWidget);
  });
}

const _health = ApiHealthStatus(
  status: 'ok',
  app: 'RabbiTrack',
  checks: {'database': true, 'redis': true, 'demo_account': true},
);
