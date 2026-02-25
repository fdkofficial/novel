from django.urls import path
from . import views


urlpatterns = [
    # Active surveys for user
    path('active/', views.ActiveSurveyListView.as_view(), name='active-surveys'),
    
    # Get specific survey details (questions, etc.)
    path('<uuid:pk>/', views.SurveyDetailView.as_view(), name='survey-detail'),
    
    # Submit response
    path('submit/', views.SurveyResponseCreateView.as_view(), name='survey-submit'),
    
    # Admin Analytics
    path('<uuid:pk>/analytics/', views.SurveyAnalyticsView.as_view(), name='survey-analytics'),
]
