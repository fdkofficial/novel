from django.db.models import Q, F
from django.utils.text import slugify
from django.http import FileResponse
from rest_framework import generics, permissions, status, filters
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import action
from rest_framework.viewsets import ModelViewSet
from django_filters.rest_framework import DjangoFilterBackend
from django.core.cache import cache
import uuid

from .models import Novel, Genre, Chapter, NovelRating, Favorite
from .serializers import (
    NovelListSerializer, NovelDetailSerializer, NovelCreateSerializer,
    GenreSerializer, ChapterSerializer, ChapterDetailSerializer,
    NovelRatingSerializer, FavoriteSerializer,
)
from .filters import NovelFilter
from apps.accounts.permissions import IsAdminOrReadOnly, IsOwnerOrAdmin


class GenreListView(generics.ListCreateAPIView):
    queryset = Genre.objects.all()
    serializer_class = GenreSerializer
    permission_classes = [IsAdminOrReadOnly]


class NovelViewSet(ModelViewSet):
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = NovelFilter
    search_fields = ['title', 'author_name', 'description', 'tags']
    ordering_fields = ['created_at', 'view_count', 'average_rating', 'download_count', 'title']
    ordering = ['-created_at']

    def get_queryset(self):
        return Novel.objects.filter(status='published').prefetch_related('genres')

    def get_serializer_class(self):
        if self.action == 'list':
            return NovelListSerializer
        elif self.action == 'create':
            return NovelCreateSerializer
        return NovelDetailSerializer

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [permissions.IsAdminUser()]
        return [permissions.IsAuthenticatedOrReadOnly()]

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Increment view count
        Novel.objects.filter(pk=instance.pk).update(view_count=F('view_count') + 1)
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    def perform_create(self, serializer):
        title = serializer.validated_data.get('title', '')
        slug = slugify(title)
        base_slug = slug
        counter = 1
        while Novel.objects.filter(slug=slug).exists():
            slug = f'{base_slug}-{counter}'
            counter += 1
        serializer.save(author=self.request.user, slug=slug)


class TrendingNovelsView(generics.ListAPIView):
    serializer_class = NovelListSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        cache_key = 'trending_novels'
        cached = cache.get(cache_key)
        if cached:
            return cached

        queryset = Novel.objects.filter(status='published').order_by('-view_count')[:20]
        cache.set(cache_key, queryset, 3600)  # Cache 1 hour
        return queryset


class PopularNovelsView(generics.ListAPIView):
    serializer_class = NovelListSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return Novel.objects.filter(status='published').order_by('-download_count')[:20]


class FeaturedNovelsView(generics.ListAPIView):
    serializer_class = NovelListSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return Novel.objects.filter(status='published', is_featured=True).order_by('-created_at')[:10]


class NovelDownloadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        novel = Novel.objects.get(pk=pk, status='published')
        if not novel.file:
            return Response({'error': 'No file available.'}, status=status.HTTP_404_NOT_FOUND)

        Novel.objects.filter(pk=pk).update(download_count=F('download_count') + 1)

        # Return file URL (for S3) or stream file
        if novel.file.name.startswith('http'):
            return Response({'download_url': novel.file.url})

        return FileResponse(
            novel.file.open('rb'),
            as_attachment=True,
            filename=f'{novel.slug}.epub',
        )


class ChapterDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ChapterDetailSerializer

    def get_queryset(self):
        return Chapter.objects.filter(novel__status='published')


class ChapterByNumberView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ChapterDetailSerializer
    lookup_field = 'chapter_number'

    def get_queryset(self):
        return Chapter.objects.filter(
            novel_id=self.kwargs['novel_pk'],
            novel__status='published'
        )


class NovelRatingView(generics.CreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = NovelRatingSerializer

    def perform_create(self, serializer):
        novel_id = self.kwargs.get('novel_pk')
        novel = Novel.objects.get(pk=novel_id)
        # Upsert rating
        NovelRating.objects.update_or_create(
            novel=novel,
            user=self.request.user,
            defaults={
                'rating': serializer.validated_data['rating'],
                'review': serializer.validated_data.get('review', ''),
            }
        )


class NovelRatingListView(generics.ListAPIView):
    serializer_class = NovelRatingSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return NovelRating.objects.filter(novel__pk=self.kwargs['novel_pk']).order_by('-created_at')


class GlobalRatingListView(generics.ListAPIView):
    """View to get all recent ratings for the community feed."""
    serializer_class = NovelRatingSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return NovelRating.objects.all().order_by('-created_at')[:50]


class FavoriteListView(generics.ListAPIView):
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user).select_related('novel')


class FavoriteToggleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, novel_pk):
        novel = Novel.objects.get(pk=novel_pk)
        favorite, created = Favorite.objects.get_or_create(user=request.user, novel=novel)

        if not created:
            favorite.delete()
            Novel.objects.filter(pk=novel_pk).update(favorite_count=F('favorite_count') - 1)
            return Response({'favorited': False, 'message': 'Removed from favorites'})

        Novel.objects.filter(pk=novel_pk).update(favorite_count=F('favorite_count') + 1)
        return Response({'favorited': True, 'message': 'Added to favorites'}, status=status.HTTP_201_CREATED)
