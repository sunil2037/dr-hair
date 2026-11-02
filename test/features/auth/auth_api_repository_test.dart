import 'package:dio/dio.dart';
import 'package:dr_hair/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dr_hair/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth API request contract', () {
    test(
      'requests OTP through the API and reads the optional local test code',
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
                    'test_otp': '123456',
                  },
                ),
              );
            },
          ),
        );
        final repository = AuthRepositoryImpl(
          remote: AuthRemoteDataSource(dio: dio),
        );

        final code = await repository.requestOtp('9876543210');

        expect(code, '123456');
        expect(capturedRequest?.path, '/api/v1/auth/send_login_otp');
        expect(capturedRequest?.data, {'login': '9876543210'});
        expect(capturedRequest?.extra['sensitive'], isTrue);
      },
    );

    test(
      'production API response does not provide a local test code',
      () async {
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

        expect(await repository.requestOtp('9876543210'), isNull);
      },
    );
  });
}
