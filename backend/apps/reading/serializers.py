from rest_framework import serializers
from .models import ReadingProgress, Bookmark, Highlight, ReadingAnalytics
from apps.novels.serializers import NovelListSerializer
from apps.novels.models import Chapter
import uuid


class ChapterFlexibleField(serializers.Field):
    def to_internal_value(self, data):
        from apps.novels.models import Chapter
        import uuid
        try:
            # Try UUID
            uuid_val = uuid.UUID(str(data))
            chapter = Chapter.objects.filter(id=uuid_val).first()
            if chapter:
                return chapter
        except ValueError:
            try:
                int_id = int(data)
                chapter = Chapter.objects.filter(id=int_id).first()
                if chapter:
                    return chapter
            except Exception:
                pass
        raise serializers.ValidationError('Chapter must be a valid UUID or integer ID.')

    def to_representation(self, value):
        return str(value.id) if hasattr(value, 'id') else str(value)


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
    position = serializers.FloatField()
    chapter = ChapterFlexibleField()

    class Meta:
        model = Bookmark
        fields = ('id', 'novel', 'chapter', 'page', 'position', 'title', 'note', 'created_at')
        read_only_fields = ('id', 'created_at')

    def validate_chapter(self, value):
        from apps.novels.models import Chapter
        import uuid
        # Accept integer or UUID
        if isinstance(value, str):
            try:
                # Try UUID
                uuid.UUID(value)
                return value
            except ValueError:
                # Try integer
                try:
                    int_id = int(value)
                    chapter = Chapter.objects.filter(id=int_id).first()
                    if chapter:
                        return chapter.id
                except Exception:
                    pass
        elif isinstance(value, int):
            chapter = Chapter.objects.filter(id=value).first()
            if chapter:
                return chapter.id
        return value

    def to_internal_value(self, data):
        from apps.novels.models import Chapter
        import uuid
        chapter_value = data.get('chapter')
        if chapter_value is not None:
            try:
                # Try UUID
                uuid_val = uuid.UUID(str(chapter_value))
                data['chapter'] = uuid_val
            except ValueError:
                try:
                    int_id = int(chapter_value)
                    chapter = Chapter.objects.filter(id=int_id).first()
                    if chapter:
                        data['chapter'] = chapter.id
                except Exception:
                    pass
        return super().to_internal_value(data)


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
