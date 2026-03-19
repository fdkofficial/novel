from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class ReadingBehavior(models.Model):
    """Tracks user reading behavior for AI recommendations."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reading_behaviors')
    novel = models.ForeignKey('novels.Novel', on_delete=models.CASCADE, related_name='behaviors')

    # Behavior signals
    view_count = models.IntegerField(default=0)
    reading_sessions = models.IntegerField(default=0)
    total_time_minutes = models.IntegerField(default=0)
    completion_percentage = models.FloatField(default=0.0)
    is_completed = models.BooleanField(default=False)
    is_favorited = models.BooleanField(default=False)
    rated = models.IntegerField(null=True, blank=True)  # 1-5 or None

    # Derived score (computed)
    engagement_score = models.FloatField(default=0.0)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'reading_behaviors'
        unique_together = ('user', 'novel')

    def compute_engagement_score(self):
        """Rule-based engagement scoring."""
        score = 0.0
        score += min(self.view_count * 2, 10)
        score += min(self.reading_sessions * 3, 15)
        score += min(self.total_time_minutes * 0.05, 20)
        score += self.completion_percentage * 0.3
        if self.is_completed:
            score += 20
        if self.is_favorited:
            score += 15
        if self.rated:
            score += (self.rated / 5.0) * 20
        self.engagement_score = min(score, 100.0)
        return self.engagement_score


class GenrePreference(models.Model):
    """Tracks genre affinity per user."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='genre_preferences')
    genre = models.ForeignKey('novels.Genre', on_delete=models.CASCADE, related_name='preferences')
    preference_score = models.FloatField(default=0.0)  # 0-100
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'genre_preferences'
        unique_together = ('user', 'genre')
        ordering = ['-preference_score']


class Recommendation(models.Model):
    """AI-generated novel recommendations for users."""
    ALGORITHM_CHOICES = [
        ('collaborative', 'Collaborative Filtering'),
        ('content_based', 'Content-Based Filtering'),
        ('hybrid', 'Hybrid'),
        ('rule_based', 'Rule-Based'),
        ('trending', 'Trending'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='recommendations')
    novel = models.ForeignKey('novels.Novel', on_delete=models.CASCADE, related_name='recommendations')
    score = models.FloatField(default=0.0)
    algorithm = models.CharField(max_length=20, choices=ALGORITHM_CHOICES)
    reason = models.CharField(max_length=500, blank=True)  # Human-readable reason
    is_seen = models.BooleanField(default=False)
    is_clicked = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'recommendations'
        ordering = ['-score']
