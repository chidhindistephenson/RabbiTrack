import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/offline_demo_data.dart';
import '../auth/auth_controller.dart';
import 'breeding_calendar_models.dart';
import 'breeding_calendar_repository.dart';

final breedingCalendarProvider =
    FutureProvider.autoDispose<List<BreedingCalendarEvent>>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return const [];
      }

      if (isOfflineDemoSession(session) && isOfflineDemoFarm(farm.id)) {
        return offlineDemoBreedingCalendar();
      }

      if (isOfflineDemoSession(session) && isOfflineEmptyFarm(farm.id)) {
        return const [];
      }

      final today = DateTime.now();
      final start = today.subtract(const Duration(days: 30));
      final end = today.add(const Duration(days: 90));

      return ref
          .watch(breedingCalendarRepositoryProvider)
          .list(farmId: farm.id, start: dateValue(start), end: dateValue(end));
    });

String dateValue(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
