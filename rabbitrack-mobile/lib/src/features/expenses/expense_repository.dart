import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'expense_models.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return ExpenseRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class ExpenseRepository {
  const ExpenseRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

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
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/expenses',
      data: {
        'category': category,
        'spent_on': spentOn,
        'amount': amount,
        'vendor': vendor,
        'notes': notes,
      },
      options: _authOptions(),
    );

    return ExpenseSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
