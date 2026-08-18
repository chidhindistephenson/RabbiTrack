import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'expense_models.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return ExpenseRepository(
    dio: ref.watch(dioProvider),
    token: session?.token,
    offlineQueue: ref.watch(offlineActionQueueProvider),
  );
});

class ExpenseRepository {
  const ExpenseRepository({
    required this.dio,
    required this.token,
    this.offlineQueue,
  });

  final Dio dio;
  final String? token;
  final OfflineActionQueue? offlineQueue;

  Future<List<ExpenseSummary>> list(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/expenses',
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map(
          (expense) => ExpenseSummary.fromJson(expense as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ExpenseReport> summary(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/expenses/summary',
      options: _authOptions(),
    );

    return ExpenseReport.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<ExpenseSummary> create({
    required String farmId,
    required String category,
    required double amount,
    required String spentOn,
    String? vendor,
    String? notes,
  }) async {
    final data = {
      'category': category,
      'spent_on': spentOn,
      'amount': amount,
      'vendor': vendor,
      'notes': notes,
    };

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/farms/$farmId/expenses',
        data: data,
        options: _authOptions(),
      );

      return ExpenseSummary.fromJson(
        response.data!['data'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error) || offlineQueue == null) {
        rethrow;
      }

      await offlineQueue!.enqueue(
        method: 'POST',
        path: '/farms/$farmId/expenses',
        data: data,
        headers: _authHeaders(),
      );

      return ExpenseSummary(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        category: category,
        vendor: vendor,
        spentOn: spentOn,
        amount: amount.toStringAsFixed(2),
        currency: 'USD',
        notes: notes,
      );
    }
  }

  Options _authOptions() {
    return Options(headers: _authHeaders());
  }

  Map<String, dynamic> _authHeaders() {
    return {'Authorization': 'Bearer $token'};
  }
}
