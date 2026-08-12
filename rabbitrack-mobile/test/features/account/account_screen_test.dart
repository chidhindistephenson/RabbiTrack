import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/account/account_screen.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_controller.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_models.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_repository.dart';

void main() {
  testWidgets('AccountScreen shows signed-out state', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AccountScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(
      find.text('Your account details will appear after you sign in.'),
      findsOneWidget,
    );
  });

  testWidgets('AccountScreen shows polished signed-in account sections', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _TestAuthController(_session),
          ),
        ],
        child: const MaterialApp(home: AccountScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My account'), findsOneWidget);
    expect(find.text('RabbiTrack Owner'), findsWidgets);
    expect(find.text('Personal info'), findsOneWidget);
    expect(find.text('owner@rabbitrack.local'), findsOneWidget);
    expect(find.text('Farm access'), findsOneWidget);
    expect(find.text('RabbiTrack Demo Farm'), findsWidgets);
    expect(find.text('Switch farm'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('API status'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController(AuthSession session)
    : super(_TestAuthRepository(session));
}

class _TestAuthRepository extends AuthRepository {
  _TestAuthRepository(this.session)
    : super(dio: Dio(), secureStorage: const FlutterSecureStorage());

  final AuthSession session;

  @override
  Future<AuthSession?> restore() async => session;
}

const _farm = FarmSummary(
  id: 'farm-1',
  name: 'RabbiTrack Demo Farm',
  code: 'DEMO-FARM',
  role: 'owner',
  timezone: 'Africa/Johannesburg',
  currency: 'USD',
);

const _session = AuthSession(
  token: 'token',
  userName: 'RabbiTrack Owner',
  email: 'owner@rabbitrack.local',
  username: 'owner',
  phone: '+263 77 123 4567',
  farms: [_farm],
  selectedFarm: _farm,
);
