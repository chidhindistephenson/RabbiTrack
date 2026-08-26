import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'team_models.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return TeamRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class TeamRepository {
  const TeamRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<FarmMemberSummary>> list(String farmId) async {
    if (_isOfflineDemo) {
      return [
        if (isOfflineDemoFarm(farmId)) ..._offlineDemoMembers(),
        ...await _pendingOfflineMembers(farmId),
      ];
    }

    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/members',
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map(
          (member) =>
              FarmMemberSummary.fromJson(member as Map<String, dynamic>),
        )
        .toList();
  }

  Future<FarmMemberSummary> add({
    required String farmId,
    required String email,
    required String role,
  }) async {
    final data = {'email': email, 'role': role};

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/members',
        data: data,
        options: _authOptions(),
      );

      return FarmMemberSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/members',
        data: data,
        headers: _authHeaders(),
      );

      return FarmMemberSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        userId: null,
        name: 'Pending member',
        email: email,
        role: role,
        status: 'pending',
      );
    }
  }

  Future<FarmMemberSummary> updateRole({
    required String farmId,
    required String memberId,
    required String role,
  }) async {
    final data = {'role': role};

    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/farms/$farmId/members/$memberId',
        data: data,
        options: _authOptions(),
      );

      return FarmMemberSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'PATCH',
        path: '/farms/$farmId/members/$memberId',
        data: data,
        headers: _authHeaders(),
      );

      return FarmMemberSummary(
        id: memberId,
        userId: null,
        name: 'Pending member',
        email: '',
        role: role,
        status: 'pending',
      );
    }
  }

  Future<void> remove({
    required String farmId,
    required String memberId,
  }) async {
    await _writeOrQueue(
      method: 'DELETE',
      path: '/farms/$farmId/members/$memberId',
    );
  }

  Future<void> resendInvitation({
    required String farmId,
    required String invitationId,
  }) async {
    await _writeOrQueue(
      method: 'POST',
      path: '/farms/$farmId/invitations/$invitationId/resend',
    );
  }

  Future<void> cancelInvitation({
    required String farmId,
    required String invitationId,
  }) async {
    await _writeOrQueue(
      method: 'DELETE',
      path: '/farms/$farmId/invitations/$invitationId',
    );
  }

  Options _authOptions() {
    return Options(headers: _authHeaders());
  }

  Map<String, dynamic> _authHeaders() {
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> _writeOrQueue({
    required String method,
    required String path,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      await dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: _authOptions().copyWith(method: method),
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: method,
        path: path,
        data: data,
        headers: _authHeaders(),
      );
    }
  }

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;

  List<FarmMemberSummary> _offlineDemoMembers() {
    return const [
      FarmMemberSummary(
        id: 'offline-member-owner',
        userId: 1,
        name: 'Farm Owner',
        email: 'owner@rabbitrack.local',
        role: 'owner',
        status: 'active',
        joinedAt: '2026-08-01',
      ),
      FarmMemberSummary(
        id: 'offline-member-manager',
        userId: 2,
        name: 'Farm Manager',
        email: 'manager@rabbitrack.local',
        role: 'manager',
        status: 'active',
        joinedAt: '2026-08-02',
      ),
      FarmMemberSummary(
        id: 'offline-member-worker',
        userId: 3,
        name: 'Farm Worker',
        email: 'worker@rabbitrack.local',
        role: 'worker',
        status: 'active',
        joinedAt: '2026-08-03',
      ),
      FarmMemberSummary(
        id: 'offline-member-vet',
        userId: 4,
        name: 'Farm Veterinarian',
        email: 'vet@rabbitrack.local',
        role: 'veterinarian',
        status: 'active',
        joinedAt: '2026-08-04',
      ),
      FarmMemberSummary(
        id: 'offline-member-viewer',
        userId: 5,
        name: 'Farm Viewer',
        email: 'viewer@rabbitrack.local',
        role: 'viewer',
        status: 'active',
        joinedAt: '2026-08-05',
      ),
    ];
  }

  Future<List<FarmMemberSummary>> _pendingOfflineMembers(String farmId) async {
    final actions =
        await offlineQueue?.pendingActionsFor(
          method: 'POST',
          path: '/farms/$farmId/members',
        ) ??
        const <QueuedOfflineAction>[];

    return actions
        .map((action) {
          final email = action.data['email'] as String?;
          final role = action.data['role'] as String?;
          if (email == null || role == null) {
            return null;
          }

          return FarmMemberSummary(
            id: 'local-${action.createdAt.microsecondsSinceEpoch}',
            userId: null,
            name: 'Pending member',
            email: email,
            role: role,
            status: 'pending',
          );
        })
        .whereType<FarmMemberSummary>()
        .toList();
  }
}
