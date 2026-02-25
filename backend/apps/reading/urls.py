from django.urls import path
from . import views

urlpatterns = [
    # Reading Progress
    path('progress/', views.ReadingProgressListView.as_view(), name='reading-progress-list'),
    path('progress/update/', views.ReadingProgressUpdateView.as_view(), name='reading-progress-update'),
    path('progress/sync/', views.SyncProgressView.as_view(), name='reading-progress-sync'),

    # Bookmarks
    path('bookmarks/', views.BookmarkListView.as_view(), name='bookmarks-list'),
    path('bookmarks/<uuid:pk>/', views.BookmarkDeleteView.as_view(), name='bookmark-delete'),

    # Highlights
    path('highlights/', views.HighlightListView.as_view(), name='highlights-list'),
    path('highlights/<uuid:pk>/', views.HighlightDeleteView.as_view(), name='highlight-delete'),

    # Analytics
    path('analytics/', views.ReadingAnalyticsView.as_view(), name='reading-analytics'),
]
