import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import 'location_models.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final session = ref.watch(authControllerProvider).valueOrNull;

  return LocationRepository(dio: ref.watch(dioProvider), token: session?.token);
});

class LocationRepository {
  const LocationRepository({required this.dio, required this.token});

  final Dio dio;
  final String? token;

  Future<List<FarmLocationSummary>> list(String farmId) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/locations',
      options: _authOptions(),
    );

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map(
          (location) =>
              FarmLocationSummary.fromJson(location as Map<String, dynamic>),
        )
        .toList();
  }

  Future<FarmLocationSummary> create({
    required String farmId,
    required String type,
    required String name,
    String? parentId,
    String? code,
    int? capacity,
    String? notes,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/farms/$farmId/locations',
      data: {
        'parent_id': parentId,
        'type': type,
        'name': name,
        'code': code,
        'capacity': capacity,
        'notes': notes,
      },
      options: _authOptions(),
    );

    return FarmLocationSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<FarmLocationSummary> update({
    required String farmId,
    required String locationId,
    required String type,
    required String name,
    String? code,
    int? capacity,
    required bool isActive,
    String? notes,
  }) async {
    final response = await dio.patch<Map<String, dynamic>>(
      '/farms/$farmId/locations/$locationId',
      data: {
        'type': type,
        'name': name,
        'code': code,
        'capacity': capacity,
        'is_active': isActive,
        'notes': notes,
      },
      options: _authOptions(),
    );

    return FarmLocationSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<FarmLocationDetail> show({
    required String farmId,
    required String locationId,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/farms/$farmId/locations/$locationId',
      options: _authOptions(),
    );

    return FarmLocationDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Options _authOptions() {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
