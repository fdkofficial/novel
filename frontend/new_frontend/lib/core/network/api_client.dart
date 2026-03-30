import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Env URL (can be read from .env in prod)
const String baseUrl = 'https://elitevisiongmbh.de/api/v1/';
const String backendBaseUrl = 'https://elitevisiongmbh.de';

// Setup Dio with Interceptors
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30), // Increased timeout
    receiveTimeout: const Duration(seconds: 30), // Increased timeout
    sendTimeout: const Duration(seconds: 30), // Added send timeout
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(MediaUrlInterceptor());
  
  // Add logging interceptor for debugging
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: false,
    error: true,
    logPrint: (obj) => print('[DIO] $obj'),
  ));
  
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

// Media URL Interceptor to fix localhost URLs
class MediaUrlInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data != null) {
      response.data = _fixMediaUrls(response.data);
    }
    super.onResponse(response, handler);
  }

  dynamic _fixMediaUrls(dynamic data) {
    if (data is Map) {
      final Map<String, dynamic> fixedMap = {};
      data.forEach((key, value) {
        fixedMap[key.toString()] = _fixMediaUrls(value);
      });
      return fixedMap;
    } else if (data is List) {
      return data.map((item) => _fixMediaUrls(item)).toList();
    } else if (data is String) {
      // Replace localhost URLs with the actual backend URL
      if (data.contains('http://localhost:8000')) {
        return data.replaceAll('https://elitevisiongmbh.de', backendBaseUrl);
      }
      if (data.contains('http://127.0.0.1:8000')) {
        return data.replaceAll('http://127.0.0.1:8000', backendBaseUrl);
      }
    }
    return data;
  }
}
