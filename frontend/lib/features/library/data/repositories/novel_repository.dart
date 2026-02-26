import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/hive_storage.dart';
import '../models/novel_model.dart';

final novelRepositoryProvider = Provider<NovelRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return NovelRepository(dio);
});

class Genre {
  final String id;
  final String name;
  final String? coverImage;

  Genre({required this.id, required this.name, this.coverImage});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'],
      name: json['name'],
      coverImage: json['cover_image'],
    );
  }
}

class ReadingProgress {
  final Novel novel;
  final String lastChapterId;
  final double percentage;

  ReadingProgress({required this.novel, required this.lastChapterId, required this.percentage});

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    final novelData = json['novel_detail'] ?? json['novel'];
    return ReadingProgress(
      novel: Novel.fromJson(Map<String, dynamic>.from(novelData)),
      lastChapterId: (json['current_chapter'] ?? '').toString(),
      percentage: (json['progress_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class NovelReview {
  final String id;
  final String novelId;
  final String novelTitle;
  final String userName;
  final double rating;
  final String review;
  final DateTime createdAt;

  NovelReview({
    required this.id,
    required this.novelId,
    required this.novelTitle,
    required this.userName,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory NovelReview.fromJson(Map<String, dynamic> json) {
    return NovelReview(
      id: json['id'].toString(),
      novelId: json['novel_id'] ?? '',
      novelTitle: json['novel_title'] ?? 'Unknown Novel',
      userName: json['user_name'] ?? 'Anonymous',
      rating: (json['rating'] ?? 0.0).toDouble(),
      review: json['review'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NovelRepository {
  final Dio _dio;

  NovelRepository(this._dio);

  Future<List<ReadingProgress>> getReadingProgress() async {
    try {
      final response = await _dio.get('reading/progress/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list;
        if (data is Map) {
          list = data['results'] ?? [];
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        return list.map((item) => ReadingProgress.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      print('Error fetching reading progress: $e');
      return [];
    }
    return [];
  }

  Future<List<Genre>> getGenres() async {
    try {
      final response = await _dio.get('novels/genres/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list;
        if (data is Map) {
          list = data['results'] ?? [];
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        return list.map((item) => Genre.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      print('Error fetching genres: $e');
      return [];
    }
    return [];
  }

  Future<List<Novel>> getNovels({String? genre, String? search}) async {
    final connectivity = await Connectivity().checkConnectivity();
    final isOffline = connectivity == ConnectivityResult.none;

    if (isOffline) {
      final cached = HiveStorage.getAllNovels();
      return cached.map((item) => Novel.fromJson(Map<String, dynamic>.from(item))).toList();
    }

    try {
      final response = await _dio.get('novels/', queryParameters: {
        if (genre != null && genre.isNotEmpty) 'genre': genre,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list;
        if (data is Map) {
          list = data['results'] ?? [];
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        
        // Cache to Hive
        for (var item in list) {
          HiveStorage.saveNovel(Map<String, dynamic>.from(item));
        }

        return list.map((item) => Novel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      print('Error fetching novels: $e');
      // If error occurs, try returning cache
      final cached = HiveStorage.getAllNovels();
      return cached.map((item) => Novel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  Future<Novel?> getNovelDetails(String id) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      final cached = HiveStorage.getAllNovels().firstWhere((n) => n['id'] == id, orElse: () => null);
      return cached != null ? Novel.fromJson(Map<String, dynamic>.from(cached)) : null;
    }

    try {
      final response = await _dio.get('novels/$id/');
      if (response.statusCode == 200) {
        final novelData = response.data;
        HiveStorage.saveNovel(Map<String, dynamic>.from(novelData));
        return Novel.fromJson(novelData);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<Novel>> getRecommendations() async {
    try {
      final response = await _dio.get('recommendations/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list;
        if (data is Map) {
          list = data['results'] ?? [];
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        return list.map((json) => Novel.fromJson(Map<String, dynamic>.from(json['novel']))).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<List<Novel>> getTrendingNovels() async {
    try {
      final response = await _dio.get('novels/trending/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list = data is Map ? (data['results'] ?? []) : data;
        return list.map((json) => Novel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<List<Novel>> getPopularNovels() async {
    try {
      final response = await _dio.get('novels/popular/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list = data is Map ? (data['results'] ?? []) : data;
        return list.map((json) => Novel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<String?> downloadNovel(String novelId) async {
    try {
      final response = await _dio.get('novels/$novelId/download/');
      if (response.statusCode == 200) {
        return response.data['download_url'];
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<NovelReview>> getGlobalReviews() async {
    try {
      final response = await _dio.get('novels/ratings/');
      if (response.statusCode == 200) {
        final dynamic data = response.data;
        List list;
        if (data is Map) {
          list = data['results'] ?? [];
        } else if (data is List) {
          list = data;
        } else {
          list = [];
        }
        return list.map((item) => NovelReview.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      print('Error fetching global reviews: $e');
      return [];
    }
    return [];
  }

  Future<bool> toggleFavorite(String novelId) async {
    try {
      final response = await _dio.post('novels/$novelId/favorite/');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}

