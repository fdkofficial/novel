import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chapter_model.dart';
import '../../data/repositories/reader_repository.dart';

class ChapterParams {
  final String novelId;
  final String chapterId;
  ChapterParams(this.novelId, this.chapterId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterParams && novelId == other.novelId && chapterId == other.chapterId;

  @override
  int get hashCode => novelId.hashCode ^ chapterId.hashCode;
}

final chapterContentProvider = FutureProvider.family<Chapter?, ChapterParams>((ref, params) async {
  return ref.watch(readerRepositoryProvider).getChapterContent(params.novelId, params.chapterId);
});
