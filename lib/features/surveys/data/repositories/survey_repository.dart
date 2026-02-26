import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/survey_model.dart';

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SurveyRepository(dio);
});

class SurveyRepository {
  final Dio _dio;

  SurveyRepository(this._dio);

  Future<List<Survey>> getActiveSurveys() async {
    try {
      final response = await _dio.get('surveys/active/');
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => Survey.fromJson(json)).toList();
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  Future<Survey?> getSurveyDetails(String id) async {
    try {
      final response = await _dio.get('surveys/$id/');
      if (response.statusCode == 200) {
        return Survey.fromJson(response.data);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> submitResponse(String surveyId, Map<String, dynamic> answers) async {
    try {
      final response = await _dio.post('surveys/submit/', data: {
        'survey': surveyId,
        'answers': answers,
      });
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
