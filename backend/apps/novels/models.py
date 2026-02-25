from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()


class Genre(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)
    cover_image = models.ImageField(upload_to='genres/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'genres'
        ordering = ['name']

    def __str__(self):
        return self.name


class Novel(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
        ('archived', 'Archived'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=500)
    slug = models.SlugField(max_length=500, unique=True)
    author = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='authored_novels')
    author_name = models.CharField(max_length=200)  # For non-registered authors
    description = models.TextField()
    cover_image = models.ImageField(upload_to='covers/', blank=True, null=True)
    file = models.FileField(upload_to='novels/', blank=True, null=True)
    file_size = models.BigIntegerField(default=0)  # bytes
    genres = models.ManyToManyField(Genre, related_name='novels', blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='published')
    language = models.CharField(max_length=50, default='English')
    total_pages = models.IntegerField(default=0)
    total_chapters = models.IntegerField(default=0)
    word_count = models.BigIntegerField(default=0)

    # Statistics
    view_count = models.BigIntegerField(default=0)
    download_count = models.BigIntegerField(default=0)
    favorite_count = models.BigIntegerField(default=0)
    average_rating = models.FloatField(default=0.0)
    rating_count = models.IntegerField(default=0)

    # Timestamps
    published_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Tags and metadata
    tags = models.JSONField(default=list)
    is_featured = models.BooleanField(default=False)
    is_free = models.BooleanField(default=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    class Meta:
        db_table = 'novels'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', '-created_at']),
            models.Index(fields=['-view_count']),
            models.Index(fields=['-average_rating']),
        ]

    def __str__(self):
        return self.title


class Chapter(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    novel = models.ForeignKey(Novel, on_delete=models.CASCADE, related_name='chapters')
    title = models.CharField(max_length=500)
    chapter_number = models.IntegerField()
    content = models.TextField()
    word_count = models.IntegerField(default=0)
    is_free = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'chapters'
        ordering = ['chapter_number']
        unique_together = ('novel', 'chapter_number')

    def __str__(self):
        return f'{self.novel.title} - Chapter {self.chapter_number}: {self.title}'


class NovelRating(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    novel = models.ForeignKey(Novel, on_delete=models.CASCADE, related_name='ratings')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings')
    rating = models.IntegerField(choices=[(i, i) for i in range(1, 6)])
    review = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'novel_ratings'
        unique_together = ('novel', 'user')

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Update novel average rating
        from django.db.models import Avg
        stats = NovelRating.objects.filter(novel=self.novel).aggregate(
            avg=Avg('rating'), count=models.Count('id')
        )
        self.novel.average_rating = stats['avg'] or 0.0
        self.novel.rating_count = stats['count']
        self.novel.save(update_fields=['average_rating', 'rating_count'])


class Favorite(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    novel = models.ForeignKey(Novel, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'favorites'
        unique_together = ('user', 'novel')
        ordering = ['-created_at']
