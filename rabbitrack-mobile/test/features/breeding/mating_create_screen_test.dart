import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_controller.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_models.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_repository.dart';
import 'package:rabbitrack_mobile/src/features/breeding/mating_create_screen.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_models.dart';

void main() {
  testWidgets('MatingCreateScreen shows empty state without a breeding pair', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('Available breeding pair needed'), findsOneWidget);
    expect(find.text('Add rabbit'), findsOneWidget);
    expect(find.text('Save mating'), findsNothing);
  });

  testWidgets('MatingCreateScreen exposes doe and buck choices', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_rabbits));
    await tester.pumpAndSettle();

    expect(find.text('Doe'), findsOneWidget);
    expect(find.text('Buck'), findsOneWidget);
    expect(find.text('Mating date'), findsOneWidget);
    expect(find.text('Observed'), findsOneWidget);
    expect(find.text('Attempted'), findsOneWidget);
    expect(find.text('Uncertain'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Behavior observed'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Notes'), findsOneWidget);

    await tester.tap(find.text('Doe'));
    await tester.pumpAndSettle();
    expect(find.text('DOE-0001 - Luna'), findsOneWidget);
    expect(find.text('BUCK-0001 - Atlas'), findsNothing);
    await tester.tap(find.text('DOE-0001 - Luna'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buck'));
    await tester.pumpAndSettle();
    expect(find.text('BUCK-0001 - Atlas'), findsOneWidget);
    expect(find.text('RAB-0001 - Mystery'), findsNothing);
  });

  testWidgets('MatingCreateScreen hides does with unresolved breeding status', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_rabbitsWithOpenDoe));
    await tester.pumpAndSettle();

    expect(find.text('Available breeding pair needed'), findsOneWidget);
    expect(find.text('DOE-0002 - Busy'), findsNothing);
    expect(find.text('Save mating'), findsNothing);
  });

  testWidgets('MatingCreateScreen hides rabbits below farm breeding age', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_rabbitsWithUnderagePair, _ageRuleSession));
    await tester.pumpAndSettle();

    expect(find.text('Doe'), findsOneWidget);
    expect(find.text('Buck'), findsOneWidget);

    await tester.tap(find.text('Doe'));
    await tester.pumpAndSettle();
    expect(find.text('DOE-OLD - Clover'), findsOneWidget);
    expect(find.text('DOE-YOUNG - Sprout'), findsNothing);
    await tester.tap(find.text('DOE-OLD - Clover'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buck'));
    await tester.pumpAndSettle();
    expect(find.text('BUCK-OLD - Flint'), findsOneWidget);
    expect(find.text('BUCK-YOUNG - Pebble'), findsNothing);
  });

  testWidgets(
    'MatingCreateScreen warns and requires confirmation for siblings',
    (tester) async {
      await tester.pumpWidget(_testApp(_relatedRabbits));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Doe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DOE-0001 - Luna'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buck'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BUCK-0001 - Atlas'));
      await tester.pumpAndSettle();

      expect(
        find.text('These rabbits share both recorded parents.'),
        findsOneWidget,
      );
      expect(find.text('Confirm relationship risk'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -360));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save mating'),
      );
      expect(saveButton.onPressed, isNull);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      final enabledSaveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save mating'),
      );
      expect(enabledSaveButton.onPressed, isNotNull);
    },
  );
}

Widget _testApp(List<RabbitSummary> rabbits, [AuthSession? session]) {
  return ProviderScope(
    overrides: [
      if (session != null)
        authControllerProvider.overrideWith(
          (ref) => _TestAuthController(session),
        ),
      rabbitListProvider.overrideWith((ref) async => rabbits),
    ],
    child: const MaterialApp(home: MatingCreateScreen()),
  );
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

const _rabbits = [
  RabbitSummary(
    id: 'doe-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'available_for_breeding',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Atlas',
    sex: 'male',
    status: 'available_for_breeding',
  ),
  RabbitSummary(
    id: 'unknown-1',
    identifier: 'RAB-0001',
    name: 'Mystery',
    sex: 'unknown',
    status: 'growing',
  ),
];

const _rabbitsWithOpenDoe = [
  RabbitSummary(
    id: 'doe-2',
    identifier: 'DOE-0002',
    name: 'Busy',
    sex: 'female',
    status: 'awaiting_pregnancy_check',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Atlas',
    sex: 'male',
    status: 'available_for_breeding',
  ),
];

const _relatedRabbits = [
  RabbitSummary(
    id: 'doe-1',
    identifier: 'DOE-0001',
    name: 'Luna',
    sex: 'female',
    status: 'available_for_breeding',
    motherId: 'doe-mother',
    fatherId: 'buck-father',
  ),
  RabbitSummary(
    id: 'buck-1',
    identifier: 'BUCK-0001',
    name: 'Atlas',
    sex: 'male',
    status: 'available_for_breeding',
    motherId: 'doe-mother',
    fatherId: 'buck-father',
  ),
];

const _ageRuleFarm = FarmSummary(
  id: 'farm-1',
  name: 'Demo Farm',
  code: 'DEMO-FARM',
  role: 'owner',
  timezone: 'Africa/Johannesburg',
  currency: 'USD',
  breedingMinDoeAgeDays: 150,
  breedingMinBuckAgeDays: 120,
);

const _ageRuleSession = AuthSession(
  token: 'token',
  userName: 'Owner',
  email: 'owner@rabbitrack.local',
  farms: [_ageRuleFarm],
  selectedFarm: _ageRuleFarm,
);

const _rabbitsWithUnderagePair = [
  RabbitSummary(
    id: 'doe-old',
    identifier: 'DOE-OLD',
    name: 'Clover',
    sex: 'female',
    status: 'available_for_breeding',
    dateOfBirth: '2025-12-01',
  ),
  RabbitSummary(
    id: 'doe-young',
    identifier: 'DOE-YOUNG',
    name: 'Sprout',
    sex: 'female',
    status: 'available_for_breeding',
    dateOfBirth: '2026-07-01',
  ),
  RabbitSummary(
    id: 'buck-old',
    identifier: 'BUCK-OLD',
    name: 'Flint',
    sex: 'male',
    status: 'available_for_breeding',
    dateOfBirth: '2025-12-01',
  ),
  RabbitSummary(
    id: 'buck-young',
    identifier: 'BUCK-YOUNG',
    name: 'Pebble',
    sex: 'male',
    status: 'available_for_breeding',
    dateOfBirth: '2026-07-01',
  ),
];
