import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/shared/api_error_messages.dart';

void main() {
  test('apiErrorMessage surfaces the response message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 422,
        data: {'message': 'Move assigned rabbits before deactivating.'},
      ),
    );

    expect(
      apiErrorMessage(error, 'Fallback'),
      'Move assigned rabbits before deactivating.',
    );
  });

  test('apiErrorMessage falls back to the first validation error', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 422,
        data: {
          'errors': {
            'capacity': ['Capacity cannot be below current occupancy.'],
          },
        },
      ),
    );

    expect(
      apiErrorMessage(error, 'Fallback'),
      'Capacity cannot be below current occupancy.',
    );
  });

  test('apiErrorMessage detects connection problems', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionError,
    );

    expect(apiErrorMessage(error, 'Fallback'), apiConnectionProblemMessage);
  });
}
