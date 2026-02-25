import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/chapter_model.dart';

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ReaderRepository(dio);
});

class ReaderRepository {
  final Dio _dio;

  ReaderRepository(this._dio);

  Future<Chapter?> getChapterContent(String novelId, String chapterId) async {
    try {
      // In our backend, chapters are nested or fetched by novel id and sequence
      // For now, let's assume we fetch by ID if possible, or by novel + order
      final response = await _dio.get('novels/$novelId/chapters/$chapterId/');
      if (response.statusCode == 200) {
        return Chapter.fromJson(response.data);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> updateProgress(String novelId, String chapterId, double progress) async {
    try {
      await _dio.post('reading/progress/update/', data: {
        'novel_id': novelId,
        'chapter_id': chapterId,
        'percentage_completed': progress,
      });
    } catch (e) {
      // Silently fail or cache for later sync
    }
  }
}
