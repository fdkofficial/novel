class ChapterSummary {
  final String id;
  final String title;
  final int chapterNumber;

  ChapterSummary({required this.id, required this.title, required this.chapterNumber});

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    return ChapterSummary(
      id: json['id'],
      title: json['title'],
      chapterNumber: json['chapter_number'] ?? 0,
    );
  }
}

class Novel {
  final String id;
  final String title;
  final String author;
  final String? coverImage;
  final String? description;
  final String? genre;
  final double rating;
  final int chaptersCount;
  final bool isOngoing;
  final List<ChapterSummary> chapters;

  Novel({
    required this.id,
    required this.title,
    required this.author,
    this.coverImage,
    this.description,
    this.genre,
    required this.rating,
    required this.chaptersCount,
    required this.isOngoing,
    this.chapters = const [],
  });

  factory Novel.fromJson(Map<String, dynamic> json) {
    return Novel(
      id: json['id'],
      title: json['title'],
      author: json['author_name'] ?? 'Unknown Author',
      coverImage: json['cover_image'],
      description: json['description'] ?? json['synopsis'],
      genre: json['genre_name'],
      rating: (json['average_rating'] ?? 0.0).toDouble(),
      chaptersCount: json['chapters_count'] ?? 0,
      isOngoing: json['status'] == 'ongoing',
      chapters: json['chapters'] != null
          ? (json['chapters'] as List)
              .map((c) => ChapterSummary.fromJson(c))
              .toList()
          : [],
    );
  }
}

