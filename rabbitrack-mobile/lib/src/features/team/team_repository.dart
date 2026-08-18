import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
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
}
