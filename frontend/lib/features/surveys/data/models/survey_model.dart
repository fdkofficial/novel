class Survey {
  final String id;
  final String title;
  final String description;
  final List<SurveyQuestion> questions;

  Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      questions: (json['questions'] as List? ?? [])
          .map((q) => SurveyQuestion.fromJson(q))
          .toList(),
    );
  }
}

enum QuestionType { text, single, multiple, rating, scale }

class SurveyQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final bool isRequired;
  final String? dependsOnQuestion;
  final String? dependsOnAnswer;

  SurveyQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.isRequired,
    this.dependsOnQuestion,
    this.dependsOnAnswer,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'],
      text: json['text'],
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['question_type'],
        orElse: () => QuestionType.text,
      ),
      options: List<String>.from(json['options'] ?? []),
      isRequired: json['is_required'] ?? true,
      dependsOnQuestion: json['depends_on_question'],
      dependsOnAnswer: json['depends_on_answer'],
    );
  }
}
