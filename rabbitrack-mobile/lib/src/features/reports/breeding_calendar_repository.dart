import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
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
    if (_isOfflineDemo) {
      final events = isOfflineDemoFarm(farmId)
          ? offlineDemoBreedingCalendar()
          : const <BreedingCalendarEvent>[];
      return _calendarCsv(events);
    }

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

  bool get _isOfflineDemo => token?.startsWith('offline-demo-') == true;
}

String _calendarCsv(List<BreedingCalendarEvent> events) {
  return [
    'date,type,title,subtitle,related_type,related_id,rabbit_identifier',
    for (final event in events)
      [
        event.date,
        event.type,
        event.title,
        event.subtitle,
        event.relatedType,
        event.relatedId,
        event.rabbitIdentifier,
      ].map(_csvValue).join(','),
  ].join('\n');
}

String _csvValue(Object? value) {
  final text = (value ?? '').toString();
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }

  return '"${text.replaceAll('"', '""')}"';
}
