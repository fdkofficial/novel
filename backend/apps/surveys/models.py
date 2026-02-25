from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class Survey(models.Model):
    """Survey definition."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    is_adaptive = models.BooleanField(default=False)  # Adaptive logic enabled
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'surveys'
        ordering = ['-created_at']

    def __str__(self):
        return self.title


class SurveyQuestion(models.Model):
    QUESTION_TYPES = [
        ('text', 'Free Text'),
        ('single', 'Single Choice'),
        ('multiple', 'Multiple Choice'),
        ('rating', 'Rating (1-5)'),
        ('scale', 'Scale (1-10)'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    survey = models.ForeignKey(Survey, on_delete=models.CASCADE, related_name='questions')
    text = models.TextField()
    question_type = models.CharField(max_length=10, choices=QUESTION_TYPES)
    options = models.JSONField(default=list, blank=True)  # For single/multiple choice
    order = models.IntegerField(default=0)
    is_required = models.BooleanField(default=True)
    # Adaptive: only show if depends_on_answer matches depends_on_question answer
    depends_on_question = models.ForeignKey(
        'self', null=True, blank=True, on_delete=models.SET_NULL, related_name='dependent_questions'
    )
    depends_on_answer = models.CharField(max_length=200, blank=True)

    class Meta:
        db_table = 'survey_questions'
        ordering = ['order']


class SurveyResponse(models.Model):
    """User's response to a survey."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    survey = models.ForeignKey(Survey, on_delete=models.CASCADE, related_name='responses')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='survey_responses')
    answers = models.JSONField(default=dict)  # {question_id: answer}
    completed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'survey_responses'
        unique_together = ('survey', 'user')
        ordering = ['-completed_at']

    def __str__(self):
        return f'{self.user.username} - {self.survey.title}'
