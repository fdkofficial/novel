import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/survey_repository.dart';
import '../../data/models/survey_model.dart';

final activeSurveysProvider = FutureProvider<List<Survey>>((ref) async {
  return ref.watch(surveyRepositoryProvider).getActiveSurveys();
});

final surveyDetailsProvider = FutureProvider.family<Survey?, String>((ref, id) async {
  return ref.watch(surveyRepositoryProvider).getSurveyDetails(id);
});
