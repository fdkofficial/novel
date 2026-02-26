import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage.dart';
import '../models/chapter_model.dart';

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReaderRepository(dio);
});

class ReaderRepository {
  final Dio _dio;

  ReaderRepository(this._dio);

  Future<Chapter?> getChapterContent(String novelId, String chapterId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      final cached = HiveStorage.getChapter(novelId, chapterId);
      return cached != null ? Chapter.fromJson(cached) : null;
    }

    try {
      final response = await _dio.get('novels/$novelId/chapters/$chapterId/');
      if (response.statusCode == 200) {
        final chapterData = response.data;
        HiveStorage.saveChapter(novelId, Map<String, dynamic>.from(chapterData));
        return Chapter.fromJson(chapterData);
      }
    } catch (e) {
      // Fallback
      final cached = HiveStorage.getChapter(novelId, chapterId);
      return cached != null ? Chapter.fromJson(cached) : null;
    }
    return null;
  }

  Future<void> updateProgress(String novelId, String chapterId, double progress, {int minutes = 0, int pages = 0}) async {
    final data = {
      'novel_id': novelId,
      'chapter_id': chapterId,
      'percentage_completed': progress * 100,
      'session_minutes': minutes,
      'session_pages': pages,
    };

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      // Offline, add to sync queue
      HiveStorage.addToSyncQueue({'type': 'progress', 'data': data});
      return;
    }

    try {
      await _dio.post('reading/progress/update/', data: data);
    } catch (e) {
      HiveStorage.addToSyncQueue({'type': 'progress', 'data': data});
    }
  }

  Future<bool> addBookmark(String novelId, String chapterId, {String? title, String? note, double position = 0.0}) async {
    try {
      final response = await _dio.post('reading/bookmarks/', data: {
        'novel': novelId,
        'chapter': chapterId,
        'title': title ?? 'Bookmark',
        'note': note ?? '',
        'position': position,
      });
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getBookmarks(String novelId) async {
    try {
      final response = await _dio.get('reading/bookmarks/', queryParameters: {'novel': novelId});
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<bool> removeBookmark(String bookmarkId) async {
    try {
      final response = await _dio.delete('reading/bookmarks/$bookmarkId/');
      return response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<void> downloadAllChapters(String novelId, List<String> chapterIds) async {
    for (var id in chapterIds) {
      await getChapterContent(novelId, id);
    }
  }
}
