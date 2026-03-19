import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/survey_model.dart';
import '../../data/repositories/survey_repository.dart';
import '../providers/survey_providers.dart';

class SurveyFormScreen extends ConsumerStatefulWidget {
  final String surveyId;
  const SurveyFormScreen({super.key, required this.surveyId});

  @override
  ConsumerState<SurveyFormScreen> createState() => _SurveyFormScreenState();
}

class _SurveyFormScreenState extends ConsumerState<SurveyFormScreen> {
  final Map<String, dynamic> _answers = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final surveyAsync = ref.watch(surveyDetailsProvider(widget.surveyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Survey')),
      body: surveyAsync.when(
        data: (surveyData) {
          final survey = surveyData as Survey?;
          if (survey == null) return const Center(child: Text('Survey not found'));

          final visibleQuestions = survey.questions.where((q) {
            if (q.dependsOnQuestion == null) return true;
            final dependentAnswer = _answers[q.dependsOnQuestion];
            return dependentAnswer?.toString() == q.dependsOnAnswer;
          }).toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleQuestions.length,
                  itemBuilder: (context, index) {
                    final q = visibleQuestions[index];
                    return _buildQuestionCard(q);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                    ),
                    onPressed: _isSubmitting || !_isFormValid(visibleQuestions) 
                      ? null 
                      : () => _submit(survey.id),
                    child: _isSubmitting 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Response', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  bool _isFormValid(List<SurveyQuestion> questions) {
    for (var q in questions) {
      if (q.isRequired && (_answers[q.id] == null || _answers[q.id].toString().isEmpty)) {
        return false;
      }
    }
    return true;
  }

  Widget _buildQuestionCard(SurveyQuestion q) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              q.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInput(q),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(SurveyQuestion q) {
    switch (q.type) {
      case QuestionType.text:
        return TextField(
          decoration: const InputDecoration(hintText: 'Enter your answer', border: OutlineInputBorder()),
          onChanged: (val) => setState(() => _answers[q.id] = val),
        );
      case QuestionType.single:
        return Column(
          children: q.options.map((opt) => RadioListTile(
            title: Text(opt),
            value: opt,
            groupValue: _answers[q.id],
            onChanged: (val) => setState(() => _answers[q.id] = val),
          )).toList(),
        );
      case QuestionType.multiple:
        final currentAnswers = List<String>.from(_answers[q.id] ?? []);
        return Column(
          children: q.options.map((opt) => CheckboxListTile(
            title: Text(opt),
            value: currentAnswers.contains(opt),
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  currentAnswers.add(opt);
                } else {
                  currentAnswers.remove(opt);
                }
                _answers[q.id] = currentAnswers;
              });
            },
          )).toList(),
        );
      case QuestionType.rating:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) => IconButton(
            icon: Icon(
              Icons.star, 
              color: (_answers[q.id] ?? 0) > i ? Colors.amber : Colors.grey[300]
            ),
            onPressed: () => setState(() => _answers[q.id] = i+1),
          )),
        );
      case QuestionType.scale:
        return Slider(
          value: (_answers[q.id] ?? 5.0).toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: (_answers[q.id] ?? 5).toString(),
          onChanged: (val) => setState(() => _answers[q.id] = val.toInt()),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _submit(String surveyId) async {
    setState(() => _isSubmitting = true);
    final success = await ref.read(surveyRepositoryProvider).submitResponse(surveyId, _answers);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!'))
      );
      ref.invalidate(activeSurveysProvider);
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed. Please try again.'))
      );
    }
  }
}
