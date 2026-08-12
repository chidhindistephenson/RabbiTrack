import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/api_config.dart';
import 'auth_models.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  const AuthRepository({required this._dio, required this._secureStorage});

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Future<AuthSession?> restore() async {
    final token = await _readToken();
    if (token == null) {
      return null;
    }

    try {
      final selectedFarmId = await _readSelectedFarmId();
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final session = _sessionFromUser(
        token: token,
        user: response.data!['user'] as Map<String, dynamic>,
        selectedFarmId: selectedFarmId,
      );

      if (selectedFarmId != null && session.selectedFarm == null) {
        await _secureStorage.delete(key: 'selected_farm_id');
      }

      return session;
    } on DioException catch (error) {
      if (shouldClearStoredAuth(error)) {
        await _secureStorage.delete(key: 'auth_token');
        await _secureStorage.delete(key: 'selected_farm_id');

        return null;
      }

      rethrow;
    }
  }

  Future<AuthSession> login({
    required String login,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'login': login,
        'password': password,
        'device_name': 'RabbiTrack Android',
      },
    );

    final data = response.data!;
    final token = data['token'] as String;
    await _secureStorage.write(key: 'auth_token', value: token);

    return _sessionFromUser(
      token: token,
      user: data['user'] as Map<String, dynamic>,
    );
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String farmName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'farm_name': farmName,
        'device_name': 'RabbiTrack Android',
      },
    );

    final data = response.data!;
    final token = data['token'] as String;
    await _secureStorage.write(key: 'auth_token', value: token);

    return _sessionFromUser(
      token: token,
      user: data['user'] as Map<String, dynamic>,
    );
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/password/forgot',
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/auth/password/reset',
      data: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<void> logout(String? token) async {
    if (token != null) {
      try {
        await _dio.post<Map<String, dynamic>>(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } on DioException {
        // Local sign-out should still succeed if the API session is already gone.
      }
    }

    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'selected_farm_id');
  }

  Future<void> rememberSelectedFarm(String farmId) async {
    await _secureStorage.write(key: 'selected_farm_id', value: farmId);
  }

  Future<String?> _readToken() async {
    try {
      return await _secureStorage.read(key: 'auth_token');
    } on MissingPluginException {
      return null;
    }
  }

  Future<String?> _readSelectedFarmId() async {
    try {
      return await _secureStorage.read(key: 'selected_farm_id');
    } on MissingPluginException {
      return null;
    }
  }

  AuthSession _sessionFromUser({
    required String token,
    required Map<String, dynamic> user,
    String? selectedFarmId,
  }) {
    final farmsJson = user['farms'] as List<dynamic>;
    final farms = farmsJson
        .map((farm) => FarmSummary.fromJson(farm as Map<String, dynamic>))
        .toList();
    final selectedFarm = initialSelectedFarm(
      farms: farms,
      selectedFarmId: selectedFarmId,
    );

    return AuthSession(
      token: token,
      userName: user['name'] as String,
      email: user['email'] as String,
      username: user['username'] as String?,
      phone: user['phone'] as String?,
      farms: farms,
      selectedFarm: selectedFarm,
    );
  }
}

FarmSummary? selectedFarmFromList({
  required List<FarmSummary> farms,
  required String farmId,
}) {
  for (final farm in farms) {
    if (farm.id == farmId) {
      return farm;
    }
  }

  return null;
}

FarmSummary? initialSelectedFarm({
  required List<FarmSummary> farms,
  String? selectedFarmId,
}) {
  final rememberedFarm = selectedFarmId == null
      ? null
      : selectedFarmFromList(farms: farms, farmId: selectedFarmId);

  return rememberedFarm ?? (farms.length == 1 ? farms.first : null);
}

bool shouldClearStoredAuth(Object error) {
  if (error is! DioException) {
    return false;
  }

  return error.response?.statusCode == 401 || error.response?.statusCode == 403;
}
