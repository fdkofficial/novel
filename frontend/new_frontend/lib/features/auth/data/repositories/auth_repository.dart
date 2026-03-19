import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio, ref);
});

class AuthRepository {
  final Dio _dio;
  final Ref _ref;

  AuthRepository(this._dio, this._ref);

  Future<AuthUser?> login(String email, String password) async {
    try {
      final response = await _dio.post('auth/login/', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final access = data['access'];
        final refresh = data['refresh'];
        final userJson = data['user'];

        await _ref.read(localStorageProvider).saveTokens(access, refresh);
        
        return AuthUser.fromJson(userJson);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<AuthUser?> register(String username, String email, String password, {String? firstName, String? lastName, String? passwordConfirm}) async {
    try {
      final response = await _dio.post('auth/register/', data: {
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'password_confirm': passwordConfirm,
      });

      if (response.statusCode == 201) {
        // Registration success, usually returns user or token
        // If it returns token, login automatically
        if (response.data['access'] != null) {
          final access = response.data['access'];
          final refresh = response.data['refresh'];
          await _ref.read(localStorageProvider).saveTokens(access, refresh);
        }
        return AuthUser.fromJson(response.data['user'] ?? response.data);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    await _ref.read(localStorageProvider).clearTokens();
  }
}
