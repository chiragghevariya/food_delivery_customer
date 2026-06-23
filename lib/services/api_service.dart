import 'package:dio/dio.dart';
import '../config/api_config.dart';

/// A single shared Dio HTTP client for the whole app.
/// It automatically attaches the JWT token to every request.
class ApiService {
  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ));

    // Interceptor = code that runs on every request/response.
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // If we are logged in, add:  Authorization: Bearer <token>
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options); // continue sending the request
      },
    ));
  }

  /// The one and only instance (singleton).
  static final ApiService instance = ApiService._internal();

  late final Dio dio;
  String? _token;

  /// Called by AuthService after login and on app start.
  void setToken(String? token) => _token = token;
}
