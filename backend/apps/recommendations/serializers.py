from rest_framework import serializers
from .models import Recommendation, GenrePreference, ReadingBehavior
from apps.novels.serializers import NovelListSerializer


class RecommendationSerializer(serializers.ModelSerializer):
    novel = NovelListSerializer(read_only=True)

    class Meta:
        model = Recommendation
        fields = ('id', 'novel', 'score', 'algorithm', 'reason', 'is_seen', 'created_at')


class GenrePreferenceSerializer(serializers.ModelSerializer):
    genre_name = serializers.SerializerMethodField()

    class Meta:
        model = GenrePreference
        fields = ('id', 'genre', 'genre_name', 'preference_score', 'updated_at')

    def get_genre_name(self, obj):
        return obj.genre.name


class ReadingBehaviorSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReadingBehavior
        fields = ('id', 'novel', 'engagement_score', 'completion_percentage', 'is_completed', 'updated_at')
