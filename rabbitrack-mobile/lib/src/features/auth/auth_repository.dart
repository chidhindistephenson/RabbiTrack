import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/api_config.dart';
import '../../shared/api_error_messages.dart';
import '../../shared/offline_action_queue.dart';
import '../../shared/offline_api_cache.dart';
import 'auth_models.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    OfflineCacheInterceptor(
      cache: ref.watch(offlineApiCacheProvider),
      onOnlineResponse: () {
        ref.read(offlineApiStatusProvider.notifier).state =
            OfflineApiStatus.online(at: DateTime.now());
        ref.read(offlineActionQueueProvider).replay(dio);
      },
      onCachedResponse: (cachedAt) {
        ref.read(offlineApiStatusProvider.notifier).state =
            OfflineApiStatus.cached(cachedAt: cachedAt);
      },
    ),
  );

  return dio;
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
  const AuthRepository({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  }) : this._(dio, secureStorage);

  const AuthRepository._(this._dio, this._secureStorage);

  static Future<void>? _googleInitialize;

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  Future<AuthSession?> restore() async {
    final token = await _readToken();
    if (token == null) {
      return null;
    }

    final selectedFarmId = await _readSelectedFarmId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final session = _sessionFromUser(
        token: token,
        user: response.data!['user'] as Map<String, dynamic>,
        selectedFarmId: selectedFarmId,
      );
      await _writeCachedSession(session);

      if (selectedFarmId != null && session.selectedFarm == null) {
        await _secureStorage.delete(key: 'selected_farm_id');
      }

      return session;
    } on DioException catch (error) {
      if (shouldClearStoredAuth(error)) {
        await _secureStorage.delete(key: 'auth_token');
        await _secureStorage.delete(key: 'selected_farm_id');
        await _secureStorage.delete(key: 'auth_session');

        return null;
      }

      if (isApiConnectionProblem(error)) {
        return _readCachedSession(selectedFarmId: selectedFarmId);
      }

      rethrow;
    }
  }

  Future<AuthSession> login({
    required String login,
    required String password,
  }) async {
    try {
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

      final session = _sessionFromUser(
        token: token,
        user: data['user'] as Map<String, dynamic>,
      );
      await _writeCachedSession(session);

      return session;
    } on DioException catch (error) {
      if (!isApiConnectionProblem(error)) {
        rethrow;
      }

      final session = offlineDemoSessionForCredentials(
        login: login,
        password: password,
      );
      if (session == null) {
        rethrow;
      }

      await _secureStorage.write(key: 'auth_token', value: session.token);
      await _writeCachedSession(session);

      return session;
    }
  }

  Future<AuthSession> loginWithGoogle() async {
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (serverClientId.isEmpty) {
      throw StateError(
        'Google sign-in is not configured. Build with --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.',
      );
    }

    final signIn = GoogleSignIn.instance;
    _googleInitialize ??= signIn.initialize(serverClientId: serverClientId);
    await _googleInitialize;
    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'id_token': idToken, 'device_name': 'RabbiTrack Android'},
    );

    final data = response.data!;
    final token = data['token'] as String;
    await _secureStorage.write(key: 'auth_token', value: token);

    final session = _sessionFromUser(
      token: token,
      user: data['user'] as Map<String, dynamic>,
    );
    await _writeCachedSession(session);

    return session;
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

    final session = _sessionFromUser(
      token: token,
      user: data['user'] as Map<String, dynamic>,
    );
    await _writeCachedSession(session);

    return session;
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
    await _secureStorage.delete(key: 'auth_session');
  }

  Future<void> rememberSelectedFarm(String farmId) async {
    await _secureStorage.write(key: 'selected_farm_id', value: farmId);
  }

  Future<AuthSession?> _readCachedSession({String? selectedFarmId}) async {
    try {
      final cached = await _secureStorage.read(key: 'auth_session');
      if (cached == null) {
        return null;
      }

      final json = jsonDecode(cached) as Map<String, dynamic>;
      if (selectedFarmId != null) {
        json['selected_farm_id'] = selectedFarmId;
      }

      return AuthSession.fromJson(json);
    } on MissingPluginException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeCachedSession(AuthSession session) async {
    await _secureStorage.write(
      key: 'auth_session',
      value: jsonEncode(session.toJson()),
    );
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

AuthSession? offlineDemoSessionForCredentials({
  required String login,
  required String password,
}) {
  if (password != 'secret-password') {
    return null;
  }

  final normalizedLogin = login.trim().toLowerCase();
  final user = _offlineDemoUsers[normalizedLogin];
  if (user == null) {
    return null;
  }

  final farm = FarmSummary(
    id: 'offline-demo-farm',
    name: 'RabbiTrack Demo Farm',
    code: 'DEMO-FARM',
    role: user.role,
    timezone: 'Africa/Johannesburg',
    currency: 'USD',
    saleReadyMinAgeDays: 70,
    saleReadyMinWeightKg: 2,
    retirementReviewLitterThreshold: 0,
    breedingMinDoeAgeDays: 0,
    breedingMinBuckAgeDays: 0,
  );

  return AuthSession(
    token: 'offline-demo-${user.username}',
    userName: user.name,
    email: user.email,
    username: user.username,
    farms: [farm],
    selectedFarm: farm,
  );
}

const _offlineDemoUsers = <String, _OfflineDemoUser>{
  'owner@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Owner',
    email: 'owner@rabbitrack.local',
    username: 'owner',
    role: 'owner',
  ),
  'owner': _OfflineDemoUser(
    name: 'RabbiTrack Owner',
    email: 'owner@rabbitrack.local',
    username: 'owner',
    role: 'owner',
  ),
  'admin@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Administrator',
    email: 'admin@rabbitrack.local',
    username: 'admin',
    role: 'administrator',
  ),
  'admin': _OfflineDemoUser(
    name: 'RabbiTrack Administrator',
    email: 'admin@rabbitrack.local',
    username: 'admin',
    role: 'administrator',
  ),
  'administrator@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Administrator',
    email: 'administrator@rabbitrack.local',
    username: 'administrator',
    role: 'administrator',
  ),
  'administrator': _OfflineDemoUser(
    name: 'RabbiTrack Administrator',
    email: 'administrator@rabbitrack.local',
    username: 'administrator',
    role: 'administrator',
  ),
  'manager@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Manager',
    email: 'manager@rabbitrack.local',
    username: 'manager',
    role: 'manager',
  ),
  'manager': _OfflineDemoUser(
    name: 'RabbiTrack Manager',
    email: 'manager@rabbitrack.local',
    username: 'manager',
    role: 'manager',
  ),
  'worker@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Worker',
    email: 'worker@rabbitrack.local',
    username: 'worker',
    role: 'worker',
  ),
  'worker': _OfflineDemoUser(
    name: 'RabbiTrack Worker',
    email: 'worker@rabbitrack.local',
    username: 'worker',
    role: 'worker',
  ),
  'vet@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Veterinarian',
    email: 'vet@rabbitrack.local',
    username: 'vet',
    role: 'veterinarian',
  ),
  'vet': _OfflineDemoUser(
    name: 'RabbiTrack Veterinarian',
    email: 'vet@rabbitrack.local',
    username: 'vet',
    role: 'veterinarian',
  ),
  'veterinarian@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Veterinarian',
    email: 'veterinarian@rabbitrack.local',
    username: 'veterinarian',
    role: 'veterinarian',
  ),
  'veterinarian': _OfflineDemoUser(
    name: 'RabbiTrack Veterinarian',
    email: 'veterinarian@rabbitrack.local',
    username: 'veterinarian',
    role: 'veterinarian',
  ),
  'viewer@rabbitrack.local': _OfflineDemoUser(
    name: 'RabbiTrack Viewer',
    email: 'viewer@rabbitrack.local',
    username: 'viewer',
    role: 'viewer',
  ),
  'viewer': _OfflineDemoUser(
    name: 'RabbiTrack Viewer',
    email: 'viewer@rabbitrack.local',
    username: 'viewer',
    role: 'viewer',
  ),
};

class _OfflineDemoUser {
  const _OfflineDemoUser({
    required this.name,
    required this.email,
    required this.username,
    required this.role,
  });

  final String name;
  final String email;
  final String username;
  final String role;
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
