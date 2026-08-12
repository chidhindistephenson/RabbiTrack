import 'package:dio/dio.dart';

const apiConnectionProblemMessage =
    'Cannot reach the API server. Start RabbiTrack services, then try again.';

String apiErrorMessage(Object error, String fallback) {
  if (error is! DioException) {
    return fallback;
  }

  if (isApiConnectionProblem(error)) {
    return apiConnectionProblemMessage;
  }

  return firstApiMessage(error) ?? fallback;
}

bool isApiConnectionProblem(Object error) {
  if (error is! DioException) {
    return false;
  }

  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.response == null;
}

String? firstApiMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map<String, dynamic>) {
    return null;
  }

  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) {
    return message.trim();
  }

  final errors = data['errors'];
  if (errors is Map<String, dynamic>) {
    for (final value in errors.values) {
      if (value is List && value.isNotEmpty && value.first is String) {
        final first = value.first as String;
        if (first.trim().isNotEmpty) {
          return first.trim();
        }
      }
    }
  }

  return null;
}
