import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/novel_model.dart';
import '../../data/repositories/novel_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedGenreProvider = StateProvider<String?>((ref) => null);

final novelsProvider = FutureProvider<List<Novel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final genre = ref.watch(selectedGenreProvider);
  return ref.watch(novelRepositoryProvider).getNovels(search: query, genre: genre);
});

final recommendationsProvider = FutureProvider<List<Novel>>((ref) async {
  return ref.watch(novelRepositoryProvider).getRecommendations();
});

final trendingNovelsProvider = FutureProvider<List<Novel>>((ref) async {
  return ref.watch(novelRepositoryProvider).getTrendingNovels();
});

final popularNovelsProvider = FutureProvider<List<Novel>>((ref) async {
  return ref.watch(novelRepositoryProvider).getPopularNovels();
});

final novelDetailsProvider = FutureProvider.family<Novel?, String>((ref, id) async {
  return ref.watch(novelRepositoryProvider).getNovelDetails(id);
});

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return ref.watch(novelRepositoryProvider).getGenres();
});

final readingProgressProvider = FutureProvider<List<ReadingProgress>>((ref) async {
  return ref.watch(novelRepositoryProvider).getReadingProgress();
});

final communityReviewsProvider = FutureProvider<List<NovelReview>>((ref) async {
  return ref.watch(novelRepositoryProvider).getGlobalReviews();
});


