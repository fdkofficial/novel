import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_novel_model.dart';

final userNovelRepositoryProvider = Provider<UserNovelRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return UserNovelRepository(dio);
});

class UserNovelRepository {
  final Dio _dio;

  UserNovelRepository(this._dio);

  Future<List<UserNovel>> getUserNovels() async {
    try {
      final response = await _dio.get('novels/my-novels/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list = data is Map ? (data['results'] ?? []) : data;
        return list.map((json) => UserNovel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching user novels: $e');
      rethrow;
    }
    return [];
  }

  Future<UserNovel?> createNovel({
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
      FormData formData = FormData.fromMap({
        'title': title,
        'description': description,
        'language': language,
        'is_free': isFree,
        'status': 'draft',
        if (coverImage != null)
          'cover_image': await MultipartFile.fromFile(
            coverImage.path,
            filename: coverImage.path.split('/').last,
          )
        else if (coverImageBytes != null)
          'cover_image': MultipartFile.fromBytes(
            coverImageBytes,
            filename: 'cover.jpg',
          ),
        if (genreIds != null && genreIds.isNotEmpty) 'genre_ids': genreIds,
        if (tags != null && tags.isNotEmpty) 'tags': jsonEncode(tags),
      });

      final response = await _dio.post('novels/my-novels/create/', data: formData);
      if (response.statusCode == 201) {
        return UserNovel.fromJson(response.data);
      }
    } catch (e) {
      print('Error creating novel: $e');
      rethrow;
    }
    return null;
  }

  Future<UserNovel?> updateNovel({
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
      FormData formData = FormData.fromMap({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (language != null) 'language': language,
        if (isFree != null) 'is_free': isFree,
        if (coverImage != null)
          'cover_image': await MultipartFile.fromFile(
            coverImage.path,
            filename: coverImage.path.split('/').last,
          )
        else if (coverImageBytes != null)
          'cover_image': MultipartFile.fromBytes(
            coverImageBytes,
            filename: 'cover.jpg',
          ),
        if (genreIds != null) 'genre_ids': genreIds,
        if (tags != null) 'tags': jsonEncode(tags),
      });

      final response = await _dio.patch('novels/my-novels/$novelId/update/', data: formData);
      if (response.statusCode == 200) {
        return UserNovel.fromJson(response.data);
      }
    } catch (e) {
      print('Error updating novel: $e');
      rethrow;
    }
    return null;
  }

  Future<bool> deleteNovel(String novelId) async {
    try {
      final response = await _dio.delete('novels/my-novels/$novelId/delete/');
      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting novel: $e');
      return false;
    }
  }

  Future<bool> publishNovel(String novelId, {bool publish = true}) async {
    try {
      final response = await _dio.post(
        'novels/my-novels/$novelId/publish/',
        data: {'action': publish ? 'publish' : 'unpublish'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error publishing novel: $e');
      return false;
    }
  }

  Future<List<UserChapter>> getNovelChapters(String novelId) async {
    try {
      final response = await _dio.get('novels/my-novels/$novelId/chapters/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list = data is Map ? (data['results'] ?? []) : data;
        return list.map((json) => UserChapter.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching chapters: $e');
      rethrow;
    }
    return [];
  }

  Future<UserChapter?> createChapter({
    required String novelId,
    required String title,
    required String content,
    bool isFree = true,
  }) async {
    try {
      final response = await _dio.post(
        'novels/my-novels/$novelId/chapters/create/',
        data: {
          'title': title,
          'content': content,
          'is_free': isFree,
        },
      );
      if (response.statusCode == 201) {
        return UserChapter.fromJson(response.data);
      }
    } catch (e) {
      print('Error creating chapter: $e');
      rethrow;
    }
    return null;
  }

  Future<UserChapter?> updateChapter({
    required String novelId,
    required String chapterId,
    String? title,
    String? content,
    bool? isFree,
  }) async {
    try {
      final response = await _dio.patch(
        'novels/my-novels/$novelId/chapters/$chapterId/update/',
        data: {
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (isFree != null) 'is_free': isFree,
        },
      );
      if (response.statusCode == 200) {
        return UserChapter.fromJson(response.data);
      }
    } catch (e) {
      print('Error updating chapter: $e');
      rethrow;
    }
    return null;
  }

  Future<bool> deleteChapter(String novelId, String chapterId) async {
    try {
      final response = await _dio.delete(
        'novels/my-novels/$novelId/chapters/$chapterId/delete/',
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting chapter: $e');
      return false;
    }
  }
}
