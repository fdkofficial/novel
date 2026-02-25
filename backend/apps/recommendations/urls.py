from django.urls import path
from . import views

urlpatterns = [
    path('', views.RecommendationListView.as_view(), name='recommendations-list'),
    path('refresh/', views.RefreshRecommendationsView.as_view(), name='recommendations-refresh'),
    path('<uuid:pk>/click/', views.TrackClickView.as_view(), name='recommendation-click'),
    path('genre-preferences/', views.GenrePreferenceListView.as_view(), name='genre-preferences'),
]
