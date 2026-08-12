import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'team_models.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return TeamRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class TeamRepository {
  const TeamRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

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
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/members',
      data: {'email': email, 'role': role},
      options: _authOptions(),
    );

    return FarmMemberSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<FarmMemberSummary> updateRole({
    required String farmId,
    required String memberId,
    required String role,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/members/$memberId',
      data: {'role': role},
      options: _authOptions(),
    );

    return FarmMemberSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> remove({
    required String farmId,
    required String memberId,
  }) async {
    await dio.delete<Map<String, dynamic>>(
      '/farms/$farmId/members/$memberId',
      options: _authOptions(),
    );
  }

  Future<void> resendInvitation({
    required String farmId,
    required String invitationId,
  }) async {
    await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/invitations/$invitationId/resend',
      options: _authOptions(),
    );
  }

  Future<void> cancelInvitation({
    required String farmId,
    required String invitationId,
  }) async {
    await dio.delete<Map<String, dynamic>>(
      '/farms/$farmId/invitations/$invitationId',
      options: _authOptions(),
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
