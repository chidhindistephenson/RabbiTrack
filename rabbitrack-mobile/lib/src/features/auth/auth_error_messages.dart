import 'package:dio/dio.dart';

import '../../shared/api_error_messages.dart';

String loginErrorMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }

  if (error is! DioException) {
    return 'Something went wrong. Please try again.';
  }

  if (isApiConnectionProblem(error)) {
    return apiConnectionProblemMessage;
  }

  if (error.response?.statusCode == 422) {
    final message = firstApiMessage(error);
    return message ?? 'The email, username, phone, or password is incorrect.';
  }

  if (error.response?.statusCode == 401) {
    return 'Your session is not authorized. Please sign in again.';
  }

  return 'Could not sign in. Please try again.';
}

String signupErrorMessage(Object error) {
  if (error is StateError) {
    return error.message;
  }

  if (error is! DioException) {
    return 'Something went wrong. Please try again.';
  }

  if (isApiConnectionProblem(error)) {
    return apiConnectionProblemMessage;
  }

  return firstApiMessage(error) ??
      'Could not create the account. Check the details and try again.';
}

String passwordResetErrorMessage(Object error) {
  if (error is! DioException) {
    return 'Something went wrong. Please try again.';
  }

  if (isApiConnectionProblem(error)) {
    return apiConnectionProblemMessage;
  }

  return firstApiMessage(error) ??
      'Could not reset password. Check the code and try again.';
}

bool isAuthConnectionProblem(Object error) {
  return isApiConnectionProblem(error);
}
