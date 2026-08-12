import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'team_models.dart';
import 'team_repository.dart';

final teamListProvider = FutureProvider.autoDispose<List<FarmMemberSummary>>((
  ref,
) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  final farm = session?.selectedFarm;

  if (farm == null) {
    return [];
  }

  return ref.watch(teamRepositoryProvider).list(farm.id);
});
