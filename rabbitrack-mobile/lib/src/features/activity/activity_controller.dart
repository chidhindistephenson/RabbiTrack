import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'activity_models.dart';
import 'activity_repository.dart';

final activityListProvider =
    FutureProvider.autoDispose<List<ActivityLogSummary>>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return [];
      }

      return ref.watch(activityRepositoryProvider).list(farm.id);
    });
