import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_novel_model.dart';
import '../../data/repositories/user_novel_repository.dart';

final userNovelsProvider = StateNotifierProvider<UserNovelsNotifier, AsyncValue<List<UserNovel>>>((ref) {
  final repository = ref.watch(userNovelRepositoryProvider);
  return UserNovelsNotifier(repository);
});

class UserNovelsNotifier extends StateNotifier<AsyncValue<List<UserNovel>>> {
  final UserNovelRepository _repository;

  UserNovelsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNovels();
  }

  Future<void> loadNovels() async {
    state = const AsyncValue.loading();
    try {
      final novels = await _repository.getUserNovels();
      state = AsyncValue.data(novels);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createNovel({
    required String title,
    required String description,
    File? coverImage,
    Uint8List? coverImageBytes,
    List<String>? genreIds,
    String language = 'English',
    bool isFree = true,
    List<String>? tags,
  }) async {
    try {
      final novel = await _repository.createNovel(
        title: title,
        description: description,
        coverImage: coverImage,
        coverImageBytes: coverImageBytes,
        genreIds: genreIds,
        language: language,
        isFree: isFree,
        tags: tags,
      );
      if (novel != null) {
        await loadNovels();
        return novel.id; // Return the novel ID
      }
    } catch (e) {
      print('Error in createNovel: $e');
    }
    return null;
  }

  Future<bool> updateNovel({
    required String novelId,
    String? title,
    String? description,
    File? coverImage,
    Uint8List? coverImageBytes,
    List<String>? genreIds,
    String? language,
    bool? isFree,
    List<String>? tags,
  }) async {
    try {
      final novel = await _repository.updateNovel(
        novelId: novelId,
        title: title,
        description: description,
        coverImage: coverImage,
        coverImageBytes: coverImageBytes,
        genreIds: genreIds,
        language: language,
        isFree: isFree,
        tags: tags,
      );
      if (novel != null) {
        await loadNovels();
        return true;
      }
    } catch (e) {
      print('Error in updateNovel: $e');
    }
    return false;
  }

  Future<bool> deleteNovel(String novelId) async {
    try {
      final success = await _repository.deleteNovel(novelId);
      if (success) {
        await loadNovels();
        return true;
      }
    } catch (e) {
      print('Error in deleteNovel: $e');
    }
    return false;
  }

  Future<bool> publishNovel(String novelId, {bool publish = true}) async {
    try {
      final success = await _repository.publishNovel(novelId, publish: publish);
      if (success) {
        await loadNovels();
        return true;
      }
    } catch (e) {
      print('Error in publishNovel: $e');
    }
    return false;
  }
}

final novelChaptersProvider = StateNotifierProvider.family<NovelChaptersNotifier, AsyncValue<List<UserChapter>>, String>((ref, novelId) {
  final repository = ref.watch(userNovelRepositoryProvider);
  return NovelChaptersNotifier(repository, novelId);
});

class NovelChaptersNotifier extends StateNotifier<AsyncValue<List<UserChapter>>> {
  final UserNovelRepository _repository;
  final String novelId;

  NovelChaptersNotifier(this._repository, this.novelId) : super(const AsyncValue.loading()) {
    loadChapters();
  }

  Future<void> loadChapters() async {
    state = const AsyncValue.loading();
    try {
      final chapters = await _repository.getNovelChapters(novelId);
      state = AsyncValue.data(chapters);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createChapter({
    required String title,
    required String content,
    bool isFree = true,
  }) async {
    try {
      final chapter = await _repository.createChapter(
        novelId: novelId,
        title: title,
        content: content,
        isFree: isFree,
      );
      if (chapter != null) {
        await loadChapters();
        return true;
      }
    } catch (e) {
      print('Error in createChapter: $e');
    }
    return false;
  }

  Future<bool> updateChapter({
    required String chapterId,
    String? title,
    String? content,
    bool? isFree,
  }) async {
    try {
      final chapter = await _repository.updateChapter(
        novelId: novelId,
        chapterId: chapterId,
        title: title,
        content: content,
        isFree: isFree,
      );
      if (chapter != null) {
        await loadChapters();
        return true;
      }
    } catch (e) {
      print('Error in updateChapter: $e');
    }
    return false;
  }

  Future<bool> deleteChapter(String chapterId) async {
    try {
      final success = await _repository.deleteChapter(novelId, chapterId);
      if (success) {
        await loadChapters();
        return true;
      }
    } catch (e) {
      print('Error in deleteChapter: $e');
    }
    return false;
  }
}
