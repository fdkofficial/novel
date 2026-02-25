import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localStorageProvider = Provider<LocalStorageService>((ref) => throw UnimplementedError());

class LocalStorageService {
  final FlutterSecureStorage secureStorage;
  final SharedPreferences prefs;

  LocalStorageService({required this.secureStorage, required this.prefs});

  // JWT Tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await secureStorage.write(key: 'access_token', value: accessToken);
    await secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<String?> getAccessToken() async => await secureStorage.read(key: 'access_token');
  Future<String?> getRefreshToken() async => await secureStorage.read(key: 'refresh_token');

  Future<void> clearTokens() async {
    await secureStorage.delete(key: 'access_token');
    await secureStorage.delete(key: 'refresh_token');
  }

  // Reader Preferences
  Future<void> saveTheme(String theme) async => await prefs.setString('reader_theme', theme);
  String getTheme() => prefs.getString('reader_theme') ?? 'light';
  
  Future<void> saveFontSize(double size) async => await prefs.setDouble('font_size', size);
  double getFontSize() => prefs.getDouble('font_size') ?? 16.0;

  Future<void> saveFont(String font) async => await prefs.setString('font_family', font);
  String getFont() => prefs.getString('font_family') ?? 'Georgia';
}
