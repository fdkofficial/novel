import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Env URL (can be read from .env in prod)
const String baseUrl = 'http://localhost:8000/api/v1/';

// Setup Dio with Interceptors
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  return dio;
});

// Auth Interceptor for JWT tokens
class AuthInterceptor extends Interceptor {
  final Ref ref;
  final storage = const FlutterSecureStorage();

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: 'access_token');
    
    if (token != null && !options.path.contains('auth/login')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Implement token refresh logic here on 401
    // if err.response?.statusCode == 401 ...
    super.onError(err, handler);
  }
}
