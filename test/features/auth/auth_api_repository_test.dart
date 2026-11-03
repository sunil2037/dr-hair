import 'package:dio/dio.dart';
import 'package:dr_hair/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dr_hair/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth API request contract', () {
    test(
      'requests OTP through the API without reading an OTP from the response',
      () async {
        RequestOptions? capturedRequest;
        final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              capturedRequest = options;
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const {
                    'status': 'success',
                    'message': 'Verification code accepted.',
                  },
                ),
              );
            },
          ),
        );
        final repository = AuthRepositoryImpl(
          remote: AuthRemoteDataSource(dio: dio),
        );

        await repository.requestOtp('9876543210');

        expect(capturedRequest?.path, '/api/v1/auth/send_login_otp');
        expect(capturedRequest?.data, {'login': '9876543210'});
        expect(capturedRequest?.extra['sensitive'], isTrue);
      },
    );

    test('API response does not provide a local test code', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://backend.test'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'status': 'success',
                'message': 'If this destination can receive a code, a verification code has been sent.',
              },
            ),
          ),
        ),
      );
      final repository = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(dio: dio),
      );

      await repository.requestOtp('9876543210');
    });
  });
}
