import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rabbitrack_mobile/src/navigation/main_navigation_scaffold.dart';

void main() {
  testWidgets('bottom nav marks Rabbits selected from the current path', (
    tester,
  ) async {
    await tester.pumpWidget(_TestApp(initialLocation: '/rabbits'));

    expect(find.text('Rabbits'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Rabbits page'), findsOneWidget);
  });

  testWidgets('bottom nav routes to Rabbits when tapped', (tester) async {
    await tester.pumpWidget(_TestApp(initialLocation: '/home'));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rabbits page'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nav-rabbits')));
    await tester.pumpAndSettle();

    expect(find.text('Rabbits'), findsOneWidget);
    expect(find.text('Rabbits page'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  _TestApp({required this.initialLocation});

  final String initialLocation;

  late final GoRouter _router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => MainNavigationScaffold(
          currentPath: state.uri.path,
          child: const Center(child: Text('Home page')),
        ),
      ),
      GoRoute(
        path: '/rabbits',
        builder: (context, state) => MainNavigationScaffold(
          currentPath: state.uri.path,
          child: const Center(child: Text('Rabbits page')),
        ),
      ),
      GoRoute(
        path: '/breeding',
        builder: (context, state) => MainNavigationScaffold(
          currentPath: state.uri.path,
          child: const Center(child: Text('Breeding page')),
        ),
      ),
      GoRoute(
        path: '/health',
        builder: (context, state) => MainNavigationScaffold(
          currentPath: state.uri.path,
          child: const Center(child: Text('Health page')),
        ),
      ),
      GoRoute(
        path: '/more',
        builder: (context, state) => MainNavigationScaffold(
          currentPath: state.uri.path,
          child: const Center(child: Text('More page')),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
