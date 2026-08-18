import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_error_messages.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_models.dart';
import 'package:rabbitrack_mobile/src/features/auth/auth_repository.dart';

void main() {
  test('loginErrorMessage explains connection failures', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      type: DioExceptionType.connectionError,
    );

    expect(isAuthConnectionProblem(error), isTrue);
    expect(
      loginErrorMessage(error),
      'Cannot reach the API server. Start RabbiTrack services, then try again.',
    );
  });

  test('loginErrorMessage surfaces local Google configuration problems', () {
    expect(
      loginErrorMessage(StateError('Google sign-in is not configured.')),
      'Google sign-in is not configured.',
    );
  });

  test('isAuthConnectionProblem ignores validation errors', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 422,
      ),
    );

    expect(isAuthConnectionProblem(error), isFalse);
  });

  test('stored auth is cleared only for unauthorized restore errors', () {
    final offline = DioException(
      requestOptions: RequestOptions(path: '/auth/me'),
      type: DioExceptionType.connectionTimeout,
    );
    final unauthorized = DioException(
      requestOptions: RequestOptions(path: '/auth/me'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/me'),
        statusCode: 401,
      ),
    );

    expect(shouldClearStoredAuth(offline), isFalse);
    expect(shouldClearStoredAuth(unauthorized), isTrue);
  });

  test('selectedFarmFromList finds only current farm access', () {
    const farms = [
      FarmSummary(
        id: 'farm-1',
        name: 'Main Farm',
        code: 'MAIN',
        role: 'owner',
        timezone: 'Africa/Harare',
        currency: 'USD',
      ),
    ];

    expect(
      selectedFarmFromList(farms: farms, farmId: 'farm-1')?.name,
      'Main Farm',
    );
    expect(selectedFarmFromList(farms: farms, farmId: 'old-farm'), isNull);
  });

  test('initialSelectedFarm auto-selects one available farm', () {
    const farms = [
      FarmSummary(
        id: 'farm-1',
        name: 'Invited Farm',
        code: 'INVITE',
        role: 'worker',
        timezone: 'Africa/Harare',
        currency: 'USD',
      ),
    ];

    expect(initialSelectedFarm(farms: farms)?.name, 'Invited Farm');
  });

  test('initialSelectedFarm keeps multi-farm sessions explicit', () {
    const farms = [
      FarmSummary(
        id: 'farm-1',
        name: 'Farm One',
        code: 'ONE',
        role: 'owner',
        timezone: 'Africa/Harare',
        currency: 'USD',
      ),
      FarmSummary(
        id: 'farm-2',
        name: 'Farm Two',
        code: 'TWO',
        role: 'worker',
        timezone: 'Africa/Harare',
        currency: 'USD',
      ),
    ];

    expect(initialSelectedFarm(farms: farms), isNull);
    expect(
      initialSelectedFarm(farms: farms, selectedFarmId: 'farm-2')?.name,
      'Farm Two',
    );
  });

  test('AuthSession serializes enough data for offline restore', () {
    const session = AuthSession(
      token: 'token-123',
      userName: 'RabbiTrack Worker',
      email: 'worker@rabbitrack.local',
      username: 'worker',
      phone: null,
      farms: [
        FarmSummary(
          id: 'farm-1',
          name: 'Demo Farm',
          code: 'DEMO',
          role: 'worker',
          timezone: 'Africa/Johannesburg',
          currency: 'USD',
          saleReadyMinAgeDays: 70,
          saleReadyMinWeightKg: 2.4,
          retirementReviewLitterThreshold: 6,
          breedingMinDoeAgeDays: 150,
          breedingMinBuckAgeDays: 120,
        ),
      ],
      selectedFarm: FarmSummary(
        id: 'farm-1',
        name: 'Demo Farm',
        code: 'DEMO',
        role: 'worker',
        timezone: 'Africa/Johannesburg',
        currency: 'USD',
        saleReadyMinAgeDays: 70,
        saleReadyMinWeightKg: 2.4,
        retirementReviewLitterThreshold: 6,
        breedingMinDoeAgeDays: 150,
        breedingMinBuckAgeDays: 120,
      ),
    );

    final restored = AuthSession.fromJson(session.toJson());

    expect(restored.token, 'token-123');
    expect(restored.email, 'worker@rabbitrack.local');
    expect(restored.selectedFarm?.id, 'farm-1');
    expect(restored.selectedFarm?.role, 'worker');
    expect(restored.selectedFarm?.saleReadyMinAgeDays, 70);
    expect(restored.selectedFarm?.saleReadyMinWeightKg, 2.4);
    expect(restored.selectedFarm?.retirementReviewLitterThreshold, 6);
    expect(restored.selectedFarm?.breedingMinDoeAgeDays, 150);
    expect(restored.selectedFarm?.breedingMinBuckAgeDays, 120);
  });

  test('offline demo login accepts seeded owner credentials', () {
    final session = offlineDemoSessionForCredentials(
      login: 'owner@rabbitrack.local',
      password: 'secret-password',
    );

    expect(session, isNotNull);
    expect(session!.email, 'owner@rabbitrack.local');
    expect(session.selectedFarm?.name, 'RabbiTrack Demo Farm');
    expect(session.selectedFarm?.role, 'owner');
    expect(session.selectedFarm?.currency, 'USD');
  });

  test('offline demo login rejects unknown or wrong credentials', () {
    expect(
      offlineDemoSessionForCredentials(
        login: 'owner@rabbitrack.local',
        password: 'wrong-password',
      ),
      isNull,
    );
    expect(
      offlineDemoSessionForCredentials(
        login: 'stranger@rabbitrack.local',
        password: 'secret-password',
      ),
      isNull,
    );
  });
}
