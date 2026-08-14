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
}
