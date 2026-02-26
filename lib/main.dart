import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/local_storage.dart';
import 'core/storage/hive_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  await HiveStorage.init();
  
  final localStorageService = LocalStorageService(
    secureStorage: secureStorage,
    prefs: prefs,
  );
  
  runApp(
    ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(localStorageService),
      ],
      child: const NovelReadingApp(),
    ),
  );
}

class NovelReadingApp extends ConsumerWidget {
  const NovelReadingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Novel Reading App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
    );
  }
}

// Example theme provider for Riverpod
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
