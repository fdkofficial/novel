import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/novel_model.dart';
import '../../data/repositories/novel_repository.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedGenreProvider = StateProvider<String?>((ref) => null);

final novelsProvider = FutureProvider.autoDispose<List<Novel>>((ref) async {
  ref.keepAlive(); // Keep the provider alive to prevent cancellation
  final query = ref.watch(searchQueryProvider);
  final genre = ref.watch(selectedGenreProvider);
  return ref.watch(novelRepositoryProvider).getNovels(search: query, genre: genre);
});

final recommendationsProvider = FutureProvider.autoDispose<List<Novel>>((ref) async {
  ref.keepAlive();
  return ref.watch(novelRepositoryProvider).getRecommendations();
});

final trendingNovelsProvider = FutureProvider.autoDispose<List<Novel>>((ref) async {
  ref.keepAlive();
  return ref.watch(novelRepositoryProvider).getTrendingNovels();
});

final popularNovelsProvider = FutureProvider.autoDispose<List<Novel>>((ref) async {
  ref.keepAlive();
  return ref.watch(novelRepositoryProvider).getPopularNovels();
});

final novelDetailsProvider = FutureProvider.autoDispose.family<Novel?, String>((ref, id) async {
  ref.keepAlive();
  return ref.watch(novelRepositoryProvider).getNovelDetails(id);
});

final genresProvider = FutureProvider.autoDispose<List<Genre>>((ref) async {
  ref.keepAlive();
  return ref.watch(novelRepositoryProvider).getGenres();
});

final readingProgressProvider = FutureProvider.autoDispose<List<ReadingProgress>>((ref) async {
  ref.keepAlive();
  return ref.watch(novelRepositoryProvider).getReadingProgress();
});

final communityReviewsProvider = FutureProvider.autoDispose<List<NovelReview>>((ref) async {
  ref.keepAlive();
  return ref.watch(novelRepositoryProvider).getGlobalReviews();
});
