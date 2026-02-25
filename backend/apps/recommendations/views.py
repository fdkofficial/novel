from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Recommendation, GenrePreference, ReadingBehavior
from .serializers import RecommendationSerializer, GenrePreferenceSerializer
from .tasks import generate_recommendations_for_user


class RecommendationListView(generics.ListAPIView):
    """Get AI-generated recommendations for the authenticated user."""
    serializer_class = RecommendationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Recommendation.objects.filter(
            user=self.request.user
        ).select_related('novel').order_by('-score')

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()

        if not queryset.exists():
            # Trigger generation in background
            try:
                generate_recommendations_for_user.delay(str(request.user.id))
            except Exception:
                pass # Celery might not be running

            # Fallback: Return featured or trending novels wrapped as recommendations
            from apps.novels.models import Novel
            fallback_novels = Novel.objects.filter(status='published').order_by('-view_count')[:10]
            
            fallback_data = []
            for novel in fallback_novels:
                # Wrap novel in a mock recommendation structure
                from apps.novels.serializers import NovelListSerializer
                fallback_data.append({
                    'id': str(novel.id),
                    'novel': NovelListSerializer(novel).data,
                    'score': 100.0,
                    'algorithm': 'trending',
                    'reason': 'Popular among readers',
                    'is_seen': False,
                    'created_at': None
                })
            return Response(fallback_data)

        # Mark as seen
        queryset.update(is_seen=True)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class RefreshRecommendationsView(APIView):
    """Manually trigger recommendation refresh."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        generate_recommendations_for_user.delay(str(request.user.id))
        return Response({'message': 'Refreshing recommendations...'})


class TrackClickView(APIView):
    """Track when user clicks on a recommendation."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        Recommendation.objects.filter(
            id=pk, user=request.user
        ).update(is_clicked=True)
        return Response({'tracked': True})


class GenrePreferenceListView(generics.ListAPIView):
    """Get user's genre preferences."""
    serializer_class = GenrePreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return GenrePreference.objects.filter(
            user=self.request.user
        ).order_by('-preference_score')
