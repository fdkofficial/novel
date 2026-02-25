class Chapter {
  final String id;
  final String title;
  final String content;
  final int chapterNumber;

  Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.chapterNumber,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'].toString(),
      title: json['title'],
      content: json['content'] ?? '',
      chapterNumber: json['chapter_number'] ?? 0,
    );
  }
}

