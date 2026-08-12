import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_health_models.dart';
import 'api_health_repository.dart';

final apiHealthProvider = FutureProvider.autoDispose<ApiHealthStatus>((ref) {
  return ref.watch(apiHealthRepositoryProvider).check();
});
