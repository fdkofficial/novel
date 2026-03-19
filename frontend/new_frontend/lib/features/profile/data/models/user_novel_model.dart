class UserNovel {
  final String id;
  final String title;
  final String? description;
  final String? coverImage;
  final String status;
  final int totalChapters;
  final int wordCount;
  final List<String> genres;
  final String language;
  final bool isFree;
  final DateTime createdAt;

  UserNovel({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    required this.status,
    required this.totalChapters,
    required this.wordCount,
    required this.genres,
    this.language = 'English',
    this.isFree = true,
    required this.createdAt,
  });

  factory UserNovel.fromJson(Map<String, dynamic> json) {
    return UserNovel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      coverImage: json['cover_image'],
      status: json['status'] ?? 'draft',
      totalChapters: json['total_chapters'] ?? 0,
      wordCount: json['word_count'] ?? 0,
      genres: json['genres'] != null
          ? (json['genres'] as List).map((g) => g['name'].toString()).toList()
          : [],
      language: json['language'] ?? 'English',
      isFree: json['is_free'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class UserChapter {
  final String id;
  final String title;
  final int chapterNumber;
  final String content;
  final int wordCount;
  final bool isFree;
  final DateTime createdAt;

  UserChapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.content,
    required this.wordCount,
    this.isFree = true,
    required this.createdAt,
  });

  factory UserChapter.fromJson(Map<String, dynamic> json) {
    return UserChapter(
      id: json['id'],
      title: json['title'],
      chapterNumber: json['chapter_number'],
      content: json['content'] ?? '',
      wordCount: json['word_count'] ?? 0,
      isFree: json['is_free'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
