from rest_framework import serializers
from .models import Survey, SurveyQuestion, SurveyResponse


class SurveyQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = SurveyQuestion
        fields = (
            'id', 'text', 'question_type', 'options', 'order',
            'is_required', 'depends_on_question', 'depends_on_answer'
        )


class SurveySerializer(serializers.ModelSerializer):
    questions = serializers.SerializerMethodField()

    class Meta:
        model = Survey
        fields = ('id', 'title', 'description', 'is_adaptive', 'questions', 'created_at')

    def get_questions(self, obj):
        # Only return top-level questions, dependent ones are handled by frontend adaptive logic
        questions = obj.questions.all().order_by('order')
        return SurveyQuestionSerializer(questions, many=True).data


class SurveyResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = SurveyResponse
        fields = ('id', 'survey', 'answers', 'completed_at')
        read_only_fields = ('id', 'completed_at')

    def validate(self, attrs):
        survey = attrs['survey']
        answers = attrs.get('answers', {})
        
        # Verify all required questions are answered (basic check, complex logic in frontend)
        required_questions = survey.questions.filter(is_required=True, depends_on_question__isnull=True)
        missing = []
        for q in required_questions:
            if str(q.id) not in answers:
                missing.append(str(q.id))
                
        if missing:
            raise serializers.ValidationError({"answers": f"Missing required answers for questions: {', '.join(missing)}"})
            
        return attrs

    def create(self, validated_data):
        user = self.context['request'].user
        # Create or update response
        response, created = SurveyResponse.objects.update_or_create(
            user=user,
            survey=validated_data['survey'],
            defaults={'answers': validated_data['answers']}
        )
        return response
