import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/library/presentation/screens/library_dashboard.dart';
import '../../features/library/presentation/screens/bookmarks_screen.dart';
import '../../features/library/presentation/screens/reading_history_screen.dart';
import '../../features/novel/presentation/screens/novel_detail_screen.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';
import '../../features/surveys/presentation/screens/survey_form_screen.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isAuth = authState is AuthAuthenticated;

  return GoRouter(
    initialLocation: isAuth ? '/library' : '/login',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      if (!isAuth) return (loggingIn || registering) ? null : '/login';
      if (loggingIn || registering) return '/library';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryDashboard(),
        routes: [
          GoRoute(
            path: 'novel/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return NovelDetailScreen(novelId: id);
            },
            routes: [
              GoRoute(
                path: 'reader/:chapterId',
                builder: (context, state) {
                  final novelId = state.pathParameters['id']!;
                  final chapterId = state.pathParameters['chapterId']!;
                  return ReaderScreen(novelId: novelId, chapterId: chapterId);
                }
              )
            ]
          ),
          GoRoute(
            path: 'survey/:surveyId',
            builder: (context, state) {
              final id = state.pathParameters['surveyId']!;
              return SurveyFormScreen(surveyId: id);
            },
          ),
          GoRoute(
            path: 'bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
          GoRoute(
            path: 'reading-history',
            builder: (context, state) => const ReadingHistoryScreen(),
          ),
        ]
      ),
    ],
  );
});
