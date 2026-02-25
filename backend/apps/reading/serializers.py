from rest_framework import serializers
from .models import ReadingProgress, Bookmark, Highlight, ReadingAnalytics
from apps.novels.serializers import NovelListSerializer


class ReadingProgressSerializer(serializers.ModelSerializer):
    novel_detail = NovelListSerializer(source='novel', read_only=True)

    class Meta:
        model = ReadingProgress
        fields = (
            'id', 'novel', 'novel_detail', 'current_chapter', 'current_page',
            'progress_percentage', 'reading_time_minutes', 'is_completed',
            'last_read_at', 'created_at',
        )
        read_only_fields = ('id', 'last_read_at', 'created_at')


class BookmarkSerializer(serializers.ModelSerializer):
    class Meta:
        model = Bookmark
        fields = ('id', 'novel', 'chapter', 'page', 'position', 'title', 'note', 'created_at')
        read_only_fields = ('id', 'created_at')


class HighlightSerializer(serializers.ModelSerializer):
    class Meta:
        model = Highlight
        fields = (
            'id', 'novel', 'chapter', 'text', 'start_offset', 'end_offset',
            'color', 'note', 'created_at',
        )
        read_only_fields = ('id', 'created_at')


class ReadingAnalyticsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReadingAnalytics
        fields = ('id', 'novel', 'date', 'minutes_read', 'pages_read', 'chapters_completed')


class SyncProgressSerializer(serializers.Serializer):
    """Batch sync payload for offline reading."""
    progress_updates = ReadingProgressSerializer(many=True)
    bookmark_adds = BookmarkSerializer(many=True, required=False)
    bookmark_removes = serializers.ListField(
        child=serializers.UUIDField(), required=False
    )
    highlight_adds = HighlightSerializer(many=True, required=False)
