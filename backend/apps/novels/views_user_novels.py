from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils.text import slugify

from .models import Novel, Chapter
from .serializers import (
    NovelListSerializer, NovelDetailSerializer, NovelCreateSerializer,
    ChapterSerializer, ChapterDetailSerializer,
)


class UserNovelsListView(generics.ListAPIView):
    """Get all novels created by the authenticated user."""
    serializer_class = NovelListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Novel.objects.filter(author=self.request.user).order_by('-created_at')


class UserNovelCreateView(generics.CreateAPIView):
    """Create a new novel for the authenticated user."""
    serializer_class = NovelCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        title = serializer.validated_data.get('title', '')
        slug = slugify(title)
        base_slug = slug
        counter = 1
        while Novel.objects.filter(slug=slug).exists():
            slug = f'{base_slug}-{counter}'
            counter += 1
        
        author_name = self.request.user.full_name or self.request.user.username
        serializer.save(author=self.request.user, slug=slug, author_name=author_name)


class UserNovelUpdateView(generics.UpdateAPIView):
    """Update user's own novel."""
    serializer_class = NovelCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Novel.objects.filter(author=self.request.user)


class UserNovelDeleteView(generics.DestroyAPIView):
    """Delete user's own novel."""
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Novel.objects.filter(author=self.request.user)


class UserChapterListView(generics.ListAPIView):
    """Get all chapters for a user's novel."""
    serializer_class = ChapterSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        novel_id = self.kwargs['novel_pk']
        return Chapter.objects.filter(
            novel_id=novel_id,
            novel__author=self.request.user
        ).order_by('chapter_number')


class UserChapterCreateView(generics.CreateAPIView):
    """Add a chapter to user's novel."""
    serializer_class = ChapterDetailSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        novel_id = self.kwargs['novel_pk']
        novel = Novel.objects.get(id=novel_id, author=self.request.user)
        
        # Auto-increment chapter number
        last_chapter = Chapter.objects.filter(novel=novel).order_by('-chapter_number').first()
        chapter_number = (last_chapter.chapter_number + 1) if last_chapter else 1
        
        chapter = serializer.save(novel=novel, chapter_number=chapter_number)
        
        # Update novel's total chapters and word count
        novel.total_chapters = Chapter.objects.filter(novel=novel).count()
        novel.word_count = sum(Chapter.objects.filter(novel=novel).values_list('word_count', flat=True))
        novel.save(update_fields=['total_chapters', 'word_count'])


class UserChapterUpdateView(generics.UpdateAPIView):
    """Update a chapter in user's novel."""
    serializer_class = ChapterDetailSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        novel_id = self.kwargs['novel_pk']
        return Chapter.objects.filter(
            novel_id=novel_id,
            novel__author=self.request.user
        )

    def perform_update(self, serializer):
        chapter = serializer.save()
        
        # Update novel's word count
        novel = chapter.novel
        novel.word_count = sum(Chapter.objects.filter(novel=novel).values_list('word_count', flat=True))
        novel.save(update_fields=['word_count'])


class UserChapterDeleteView(generics.DestroyAPIView):
    """Delete a chapter from user's novel."""
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        novel_id = self.kwargs['novel_pk']
        return Chapter.objects.filter(
            novel_id=novel_id,
            novel__author=self.request.user
        )

    def perform_destroy(self, instance):
        novel = instance.novel
        instance.delete()
        
        # Update novel's total chapters and word count
        novel.total_chapters = Chapter.objects.filter(novel=novel).count()
        novel.word_count = sum(Chapter.objects.filter(novel=novel).values_list('word_count', flat=True))
        novel.save(update_fields=['total_chapters', 'word_count'])


class PublishNovelView(APIView):
    """Publish or unpublish user's novel."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            novel = Novel.objects.get(id=pk, author=request.user)
            action = request.data.get('action', 'publish')
            
            if action == 'publish':
                novel.status = 'published'
                message = 'Novel published successfully'
            elif action == 'unpublish':
                novel.status = 'draft'
                message = 'Novel unpublished'
            else:
                return Response({'error': 'Invalid action'}, status=status.HTTP_400_BAD_REQUEST)
            
            novel.save(update_fields=['status'])
            return Response({'message': message, 'status': novel.status})
        except Novel.DoesNotExist:
            return Response({'error': 'Novel not found'}, status=status.HTTP_404_NOT_FOUND)
