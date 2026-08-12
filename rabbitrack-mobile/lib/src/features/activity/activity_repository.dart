import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'activity_models.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return ActivityRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class ActivityRepository {
  const ActivityRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<List<ActivityLogSummary>> list(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/activity',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((log) => ActivityLogSummary.fromJson(log as Map<String, dynamic>))
        .toList();
  }
}
