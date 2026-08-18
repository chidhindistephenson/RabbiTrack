import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/expenses/expense_repository.dart';
import 'package:rabbitrack_mobile/src/features/farms/farm_repository.dart';
import 'package:rabbitrack_mobile/src/features/locations/location_repository.dart';
import 'package:rabbitrack_mobile/src/features/team/team_repository.dart';
import 'package:rabbitrack_mobile/src/shared/offline_action_queue.dart';

void main() {
  test('expense create queues when offline', () async {
    final queue = await _queue();
    final repository = ExpenseRepository(
      dio: _offlineDio(),
      token: 'token',
      offlineQueue: queue,
    );

    final expense = await repository.create(
      farmId: 'farm-1',
      category: 'feed',
      amount: 18.75,
      spentOn: '2026-08-17',
    );

    expect(expense.id, startsWith('local-'));
    expect(expense.amount, '18.75');
    expect(await queue.pendingCount(), 1);
  });

  test('location create and update queue when offline', () async {
    final queue = await _queue();
    final repository = LocationRepository(
      dio: _offlineDio(),
      token: 'token',
      offlineQueue: queue,
    );

    final created = await repository.create(
      farmId: 'farm-1',
      type: 'cage',
      name: 'Cage A',
      capacity: 4,
    );
    final updated = await repository.update(
      farmId: 'farm-1',
      locationId: 'location-1',
      type: 'cage',
      name: 'Cage B',
      capacity: 5,
      isActive: true,
    );

    expect(created.id, startsWith('local-'));
    expect(updated.id, 'location-1');
    expect(await queue.pendingCount(), 2);
  });

  test('farm create and update queue when offline', () async {
    final queue = await _queue();
    final repository = FarmRepository(
      dio: _offlineDio(),
      token: 'token',
      offlineQueue: queue,
    );

    final created = await repository.create(
      name: 'Offline Farm',
      currency: 'USD',
    );
    final updated = await repository.update(
      farmId: 'farm-1',
      name: 'Renamed Farm',
      currency: 'USD',
      timezone: 'Africa/Johannesburg',
      saleReadyMinAgeDays: 70,
      saleReadyMinWeightKg: 2,
      retirementReviewLitterThreshold: 6,
      breedingMinDoeAgeDays: 150,
      breedingMinBuckAgeDays: 120,
    );

    expect(created.id, startsWith('local-'));
    expect(updated.id, 'farm-1');
    expect(await queue.pendingCount(), 2);
  });

  test('team actions queue when offline', () async {
    final queue = await _queue();
    final repository = TeamRepository(
      dio: _offlineDio(),
      token: 'token',
      offlineQueue: queue,
    );

    final member = await repository.add(
      farmId: 'farm-1',
      email: 'worker@rabbitrack.local',
      role: 'worker',
    );
    final updated = await repository.updateRole(
      farmId: 'farm-1',
      memberId: 'member-1',
      role: 'manager',
    );
    await repository.remove(farmId: 'farm-1', memberId: 'member-1');
    await repository.resendInvitation(
      farmId: 'farm-1',
      invitationId: 'invite-1',
    );
    await repository.cancelInvitation(
      farmId: 'farm-1',
      invitationId: 'invite-1',
    );

    expect(member.id, startsWith('local-'));
    expect(updated.role, 'manager');
    expect(await queue.pendingCount(), 5);
  });
}

Future<OfflineActionQueue> _queue() async {
  final temp = await Directory.systemTemp.createTemp('rabbitrack-queue-test');
  addTearDown(() => temp.delete(recursive: true));
  return OfflineActionQueue(directoryProvider: () async => temp);
}

Dio _offlineDio() {
  return Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = _OfflineAdapter();
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: const SocketException('offline'),
    );
  }

  @override
  void close({bool force = false}) {}
}
