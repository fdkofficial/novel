from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import ReadingProgress, Bookmark, Highlight, ReadingAnalytics
from .serializers import (
    ReadingProgressSerializer, BookmarkSerializer, HighlightSerializer,
    ReadingAnalyticsSerializer, SyncProgressSerializer,
)


class ReadingProgressListView(generics.ListAPIView):
    """Get all reading progress for authenticated user (recently read)."""
    serializer_class = ReadingProgressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ReadingProgress.objects.filter(
            user=self.request.user
        ).select_related('novel', 'current_chapter').order_by('-last_read_at')


class ReadingProgressUpdateView(APIView):
    """Create or update reading progress for a novel."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        novel_id = request.data.get('novel_id') or request.data.get('novel')
        chapter_id = request.data.get('chapter_id') or request.data.get('current_chapter')
        progress_val = request.data.get('percentage_completed') or request.data.get('progress_percentage', 0)

        if not novel_id:
            return Response({'error': 'novel_id is required'}, status=status.HTTP_400_BAD_REQUEST)

        progress, created = ReadingProgress.objects.get_or_create(
            user=request.user,
            novel_id=novel_id,
        )

        data = request.data.copy()
        data['novel'] = novel_id
        data['progress_percentage'] = progress_val

        # Try to resolve chapter if chapter_id is provided
        if chapter_id:
            try:
                from apps.novels.models import Chapter
                # Check if it's a UUID or a number
                try:
                    import uuid
                    uuid.UUID(str(chapter_id))
                    data['current_chapter'] = chapter_id
                except ValueError:
                    # Likely a chapter number
                    chapter = Chapter.objects.filter(novel_id=novel_id, chapter_number=chapter_id).first()
                    if chapter:
                        data['current_chapter'] = chapter.id
            except Exception:
                pass

        serializer = ReadingProgressSerializer(progress, data=data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        # Update analytics
        today = timezone.now().date()
        analytics, _ = ReadingAnalytics.objects.get_or_create(
            user=request.user,
            novel_id=novel_id,
            date=today,
        )
        minutes = int(request.data.get('session_minutes', 0))
        pages = int(request.data.get('session_pages', 0))
        analytics.minutes_read += minutes
        analytics.pages_read += pages
        analytics.save(update_fields=['minutes_read', 'pages_read'])

        # Update total reading time
        progress.reading_time_minutes += minutes
        progress.save(update_fields=['reading_time_minutes'])

        return Response(serializer.data, status=status.HTTP_200_OK)


class SyncProgressView(APIView):
    """Batch sync for offline reading support."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Handle offline sync batch."""
        errors = []
        results = {'synced_progress': 0, 'synced_bookmarks': 0, 'removed_bookmarks': 0}

        # Sync progress updates
        for update in request.data.get('progress_updates', []):
            try:
                progress, _ = ReadingProgress.objects.get_or_create(
                    user=request.user,
                    novel_id=update['novel'],
                )
                serializer = ReadingProgressSerializer(progress, data=update, partial=True)
                if serializer.is_valid():
                    serializer.save()
                    results['synced_progress'] += 1
            except Exception as e:
                errors.append(str(e))

        # Add bookmarks
        for bookmark_data in request.data.get('bookmark_adds', []):
            try:
                Bookmark.objects.get_or_create(
                    user=request.user,
                    novel_id=bookmark_data['novel'],
                    chapter_id=bookmark_data.get('chapter'),
                    position=bookmark_data.get('position', 0),
                    defaults=bookmark_data,
                )
                results['synced_bookmarks'] += 1
            except Exception as e:
                errors.append(str(e))

        # Remove bookmarks
        for bookmark_id in request.data.get('bookmark_removes', []):
            Bookmark.objects.filter(id=bookmark_id, user=request.user).delete()
            results['removed_bookmarks'] += 1

        return Response({'results': results, 'errors': errors})


class BookmarkListView(generics.ListCreateAPIView):
    serializer_class = BookmarkSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Bookmark.objects.filter(user=self.request.user)
        novel_id = self.request.query_params.get('novel')
        if novel_id:
            qs = qs.filter(novel_id=novel_id)
        return qs

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class BookmarkDeleteView(generics.DestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Bookmark.objects.filter(user=self.request.user)


class HighlightListView(generics.ListCreateAPIView):
    serializer_class = HighlightSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Highlight.objects.filter(user=self.request.user)
        novel_id = self.request.query_params.get('novel')
        chapter_id = self.request.query_params.get('chapter')
        if novel_id:
            qs = qs.filter(novel_id=novel_id)
        if chapter_id:
            qs = qs.filter(chapter_id=chapter_id)
        return qs

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class HighlightDeleteView(generics.DestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Highlight.objects.filter(user=self.request.user)


class ReadingAnalyticsView(generics.ListAPIView):
    serializer_class = ReadingAnalyticsSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return ReadingAnalytics.objects.filter(
            user=self.request.user
        ).order_by('-date')[:30]
