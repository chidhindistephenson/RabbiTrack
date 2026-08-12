import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'finance_report_models.dart';
import 'finance_report_repository.dart';

final monthlyFinanceReportProvider =
    FutureProvider.autoDispose<MonthlyFinanceReport>((ref) async {
      final session = ref.watch(authControllerProvider).valueOrNull;
      final farm = session?.selectedFarm;

      if (farm == null) {
        return const MonthlyFinanceReport(currency: 'USD', months: []);
      }

      return ref.watch(financeReportRepositoryProvider).monthly(farm.id);
    });
