from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from . import views_user_novels

router = DefaultRouter()
router.register('', views.NovelViewSet, basename='novel')

urlpatterns = [
    # Genres
    path('genres/', views.GenreListView.as_view(), name='genre-list'),

    # Trending / Popular / Featured
    path('trending/', views.TrendingNovelsView.as_view(), name='trending-novels'),
    path('popular/', views.PopularNovelsView.as_view(), name='popular-novels'),
    path('featured/', views.FeaturedNovelsView.as_view(), name='featured-novels'),

    # Favorites
    path('favorites/', views.FavoriteListView.as_view(), name='favorites-list'),
    path('<uuid:novel_pk>/favorite/', views.FavoriteToggleView.as_view(), name='favorite-toggle'),

    # Ratings
    path('ratings/', views.GlobalRatingListView.as_view(), name='global-ratings-list'),
    path('<uuid:novel_pk>/ratings/', views.NovelRatingListView.as_view(), name='novel-ratings-list'),
    path('<uuid:novel_pk>/rate/', views.NovelRatingView.as_view(), name='novel-rate'),

    # Download
    path('<uuid:pk>/download/', views.NovelDownloadView.as_view(), name='novel-download'),

    # Chapters
    path('chapters/<uuid:pk>/', views.ChapterDetailView.as_view(), name='chapter-detail'),
    path('<uuid:novel_pk>/chapters/<int:chapter_number>/', views.ChapterByNumberView.as_view(), name='novel-chapter-by-number'),

    # User's Own Novels Management
    path('my-novels/', views_user_novels.UserNovelsListView.as_view(), name='user-novels-list'),
    path('my-novels/create/', views_user_novels.UserNovelCreateView.as_view(), name='user-novel-create'),
    path('my-novels/<uuid:pk>/update/', views_user_novels.UserNovelUpdateView.as_view(), name='user-novel-update'),
    path('my-novels/<uuid:pk>/delete/', views_user_novels.UserNovelDeleteView.as_view(), name='user-novel-delete'),
    path('my-novels/<uuid:pk>/publish/', views_user_novels.PublishNovelView.as_view(), name='user-novel-publish'),
    
    # User's Novel Chapters Management
    path('my-novels/<uuid:novel_pk>/chapters/', views_user_novels.UserChapterListView.as_view(), name='user-chapters-list'),
    path('my-novels/<uuid:novel_pk>/chapters/create/', views_user_novels.UserChapterCreateView.as_view(), name='user-chapter-create'),
    path('my-novels/<uuid:novel_pk>/chapters/<uuid:pk>/update/', views_user_novels.UserChapterUpdateView.as_view(), name='user-chapter-update'),
    path('my-novels/<uuid:novel_pk>/chapters/<uuid:pk>/delete/', views_user_novels.UserChapterDeleteView.as_view(), name='user-chapter-delete'),

    # Novel CRUD (ViewSet)
    path('', include(router.urls)),
]
