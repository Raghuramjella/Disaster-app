import 'package:dio/dio.dart';
import '../core/constants.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  static Dio get client => _dio;
}
