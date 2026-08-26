import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/activity/activity_repository.dart';
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

  test('offline demo locations include queued creates and details', () async {
    final queue = await _queue();
    final repository = LocationRepository(
      dio: _offlineDio(),
      token: 'offline-demo-owner',
      offlineQueue: queue,
    );

    await repository.create(
      farmId: 'offline-demo-farm',
      type: 'cage',
      name: 'Offline Cage',
      code: 'OC-1',
      capacity: 3,
    );

    final locations = await repository.list('offline-demo-farm');
    final pending = locations.last;
    final detail = await repository.show(
      farmId: 'offline-demo-farm',
      locationId: pending.id,
    );

    expect(pending.name, 'Offline Cage');
    expect(detail.code, 'OC-1');
    expect(detail.rabbits, isEmpty);
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

  test('offline demo team list includes seeded and pending members', () async {
    final queue = await _queue();
    final repository = TeamRepository(
      dio: _offlineDio(),
      token: 'offline-demo-owner',
      offlineQueue: queue,
    );

    await repository.add(
      farmId: 'offline-demo-farm',
      email: 'helper@rabbitrack.local',
      role: 'worker',
    );

    final members = await repository.list('offline-demo-farm');

    expect(
      members.any((member) => member.email == 'owner@rabbitrack.local'),
      isTrue,
    );
    expect(members.last.email, 'helper@rabbitrack.local');
    expect(members.last.status, 'pending');
  });

  test('offline demo activity list includes queued farm changes', () async {
    final queue = await _queue();
    final teamRepository = TeamRepository(
      dio: _offlineDio(),
      token: 'offline-demo-owner',
      offlineQueue: queue,
    );
    final activityRepository = ActivityRepository(
      dio: _offlineDio(),
      token: 'offline-demo-owner',
      offlineQueue: queue,
    );

    await teamRepository.add(
      farmId: 'offline-demo-farm',
      email: 'helper@rabbitrack.local',
      role: 'worker',
    );

    final activity = await activityRepository.list('offline-demo-farm');

    expect(
      activity.any((log) => log.description == 'Team invitation saved locally'),
      isTrue,
    );
  });

  test(
    'empty offline farm starts without seeded locations team or activity',
    () async {
      final queue = await _queue();
      final locations = LocationRepository(
        dio: _offlineDio(),
        token: 'offline-demo-owner',
        offlineQueue: queue,
      );
      final team = TeamRepository(
        dio: _offlineDio(),
        token: 'offline-demo-owner',
        offlineQueue: queue,
      );
      final activity = ActivityRepository(
        dio: _offlineDio(),
        token: 'offline-demo-owner',
        offlineQueue: queue,
      );

      expect(await locations.list('offline-empty-farm'), isEmpty);
      expect(await team.list('offline-empty-farm'), isEmpty);
      expect(await activity.list('offline-empty-farm'), isEmpty);
    },
  );
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
