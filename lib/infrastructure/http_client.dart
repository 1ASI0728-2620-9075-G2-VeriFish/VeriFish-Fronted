import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/token_storage.dart';

final sessionInvalidations = ValueNotifier<int>(0);

Dio buildHttpClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            error.requestOptions.path != ApiEndpoints.signin &&
            error.requestOptions.path != ApiEndpoints.signup) {
          await TokenStorage.clear();
          sessionInvalidations.value++;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

final httpClient = buildHttpClient();
