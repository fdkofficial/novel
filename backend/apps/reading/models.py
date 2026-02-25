from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class ReadingProgress(models.Model):
    """Tracks user reading progress per novel/chapter."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reading_progress')
    novel = models.ForeignKey('novels.Novel', on_delete=models.CASCADE, related_name='reading_progress')
    current_chapter = models.ForeignKey(
        'novels.Chapter', on_delete=models.SET_NULL, null=True, blank=True
    )
    current_page = models.IntegerField(default=0)
    progress_percentage = models.FloatField(default=0.0)  # 0.0 to 100.0
    reading_time_minutes = models.IntegerField(default=0)
    is_completed = models.BooleanField(default=False)
    last_read_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reading_progress'
        unique_together = ('user', 'novel')
        ordering = ['-last_read_at']
        indexes = [
            models.Index(fields=['user', '-last_read_at']),
        ]

    def __str__(self):
        return f'{self.user.username} - {self.novel.title} ({self.progress_percentage:.1f}%)'


class Bookmark(models.Model):
    """User bookmarks within novels/chapters."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bookmarks')
    novel = models.ForeignKey('novels.Novel', on_delete=models.CASCADE, related_name='bookmarks')
    chapter = models.ForeignKey(
        'novels.Chapter', on_delete=models.CASCADE, related_name='bookmarks', null=True, blank=True
    )
    page = models.IntegerField(default=0)
    position = models.IntegerField(default=0)  # Character/word position
    title = models.CharField(max_length=200, blank=True)
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'bookmarks'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user.username} bookmark in {self.novel.title}'


class Highlight(models.Model):
    """Text highlights and annotations."""
    HIGHLIGHT_COLORS = [
        ('yellow', 'Yellow'),
        ('green', 'Green'),
        ('blue', 'Blue'),
        ('pink', 'Pink'),
        ('orange', 'Orange'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='highlights')
    novel = models.ForeignKey('novels.Novel', on_delete=models.CASCADE, related_name='highlights')
    chapter = models.ForeignKey('novels.Chapter', on_delete=models.CASCADE, related_name='highlights')
    text = models.TextField()
    start_offset = models.IntegerField()
    end_offset = models.IntegerField()
    color = models.CharField(max_length=10, choices=HIGHLIGHT_COLORS, default='yellow')
    note = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'highlights'
        ordering = ['chapter', 'start_offset']


class ReadingAnalytics(models.Model):
    """Daily reading analytics per user."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='analytics')
    novel = models.ForeignKey('novels.Novel', on_delete=models.CASCADE, related_name='analytics')
    date = models.DateField()
    minutes_read = models.IntegerField(default=0)
    pages_read = models.IntegerField(default=0)
    chapters_completed = models.IntegerField(default=0)

    class Meta:
        db_table = 'reading_analytics'
        unique_together = ('user', 'novel', 'date')
        ordering = ['-date']
