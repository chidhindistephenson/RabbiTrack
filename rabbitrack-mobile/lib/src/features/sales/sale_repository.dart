import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'sale_models.dart';

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return SaleRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class SaleRepository {
  const SaleRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<List<SaleSummary>> list(String farmId, {String? rabbitId}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/sales',
      queryParameters: {'rabbit_id': ?rabbitId},
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((sale) => SaleSummary.fromJson(sale as Map<String, dynamic>))
        .toList();
  }

  Future<SaleReport> summary(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/sales/summary',
      options: _authOptions(),
    );

    return SaleReport.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<SaleSummary> create({
    required String farmId,
    required String rabbitId,
    required double salePrice,
    required String soldOn,
    String? buyerName,
    String? buyerPhone,
    String? notes,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/sales',
      data: {
        'rabbit_id': rabbitId,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'sold_on': soldOn,
        'sale_price': salePrice,
        'notes': notes,
      },
      options: _authOptions(),
    );

    return SaleSummary.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
