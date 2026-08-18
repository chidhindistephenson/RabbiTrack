import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'breeding_calendar_models.dart';

final breedingCalendarRepositoryProvider = Provider<BreedingCalendarRepository>(
  (ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;

    return BreedingCalendarRepository(
      dio: ref.watch(dioProvider),
      token: session?.token,
    );
  },
);

class BreedingCalendarRepository {
  const BreedingCalendarRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<List<BreedingCalendarEvent>> list({
    required String farmId,
    required String start,
    required String end,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/reports/breeding/calendar',
      queryParameters: {'start': start, 'end': end},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final items = response.data!['data'] as List<dynamic>? ?? [];

    return items
        .map(
          (item) =>
              BreedingCalendarEvent.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<String> exportCsv({
    required String farmId,
    required String start,
    required String end,
  }) async {
    final response = await dio.get<String>(
      '/farms/$farmId/reports/breeding/calendar',
      queryParameters: {'start': start, 'end': end, 'format': 'csv'},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.plain,
      ),
    );

    return response.data ?? '';
  }
}
