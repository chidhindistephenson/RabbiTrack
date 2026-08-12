import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_controller.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_models.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_repository.dart';
import 'package:rabbitrack_mobile/src/features/team/team_controller.dart';
import 'package:rabbitrack_mobile/src/features/team/team_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/team/team_models.dart';

void main() {
  testWidgets('TeamListScreen renders clean role labels', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [teamListProvider.overrideWith((ref) async => _members)],
        child: const MaterialApp(home: TeamListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Worker One'), findsOneWidget);
    expect(find.text('worker'), findsNothing);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Pending invite'), findsOneWidget);
  });

  testWidgets('TeamListScreen exposes pending invitation actions for owners', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _TestAuthController(_session),
          ),
          teamListProvider.overrideWith((ref) async => [_members.last]),
        ],
        child: const MaterialApp(home: TeamListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byWidgetPredicate((widget) => widget is PopupMenuButton).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Resend invite'), findsOneWidget);
    expect(find.text('Cancel invite'), findsOneWidget);
    expect(find.text('Change role'), findsNothing);
    expect(find.text('Remove access'), findsNothing);
  });

  testWidgets('TeamListScreen does not expose owner role management', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _TestAuthController(_session),
          ),
          teamListProvider.overrideWith(
            (ref) async => [
              const FarmMemberSummary(
                id: 'owner-member',
                userId: 1,
                name: 'RabbiTrack Owner',
                email: 'owner@rabbitrack.local',
                role: 'owner',
                status: 'active',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: TeamListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RabbiTrack Owner'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is PopupMenuButton),
      findsNothing,
    );
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController(AuthSession session)
    : super(_TestAuthRepository(session)) {
    state = AsyncData(session);
  }
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
  farms: [_farm],
  selectedFarm: _farm,
);

const _members = [
  FarmMemberSummary(
    id: 'member-1',
    userId: 2,
    name: 'Worker One',
    email: 'worker@rabbitrack.test',
    role: 'worker',
    status: 'active',
  ),
  FarmMemberSummary(
    id: 'invite-1',
    userId: null,
    name: 'Pending invite',
    email: 'pending@rabbitrack.test',
    role: 'viewer',
    status: 'pending',
  ),
];
