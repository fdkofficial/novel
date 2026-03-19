from rest_framework import serializers
from .models import Novel, Genre, Chapter, NovelRating, Favorite


class GenreSerializer(serializers.ModelSerializer):
    novel_count = serializers.SerializerMethodField()

    class Meta:
        model = Genre
        fields = ('id', 'name', 'slug', 'description', 'cover_image', 'novel_count')

    def get_novel_count(self, obj):
        return obj.novels.filter(status='published').count()


class ChapterSerializer(serializers.ModelSerializer):
    class Meta:
        model = Chapter
        fields = ('id', 'title', 'chapter_number', 'word_count', 'is_free', 'created_at')


class ChapterDetailSerializer(serializers.ModelSerializer):
    word_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Chapter
        fields = ('id', 'title', 'chapter_number', 'content', 'word_count', 'is_free', 'created_at', 'updated_at')
        read_only_fields = ('id', 'chapter_number', 'word_count', 'created_at', 'updated_at')
    
    def create(self, validated_data):
        # Calculate word count from content
        content = validated_data.get('content', '')
        validated_data['word_count'] = len(content.split())
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        # Recalculate word count if content changed
        if 'content' in validated_data:
            content = validated_data.get('content', '')
            validated_data['word_count'] = len(content.split())
        return super().update(instance, validated_data)


class NovelListSerializer(serializers.ModelSerializer):
    genres = GenreSerializer(many=True, read_only=True)
    is_favorited = serializers.SerializerMethodField()

    class Meta:
        model = Novel
        fields = (
            'id', 'title', 'slug', 'author_name', 'description', 'cover_image',
            'genres', 'language', 'total_pages', 'total_chapters', 'word_count',
            'view_count', 'download_count', 'favorite_count', 'average_rating',
            'rating_count', 'is_featured', 'is_free', 'price',
            'published_at', 'created_at', 'is_favorited',
        )

    def get_is_favorited(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Favorite.objects.filter(user=request.user, novel=obj).exists()
        return False


class NovelDetailSerializer(NovelListSerializer):
    chapters = ChapterSerializer(many=True, read_only=True)
    genre_ids = serializers.PrimaryKeyRelatedField(
        queryset=Genre.objects.all(), many=True, source='genres', write_only=True, required=False
    )
    is_owner = serializers.SerializerMethodField()

    class Meta(NovelListSerializer.Meta):
        fields = NovelListSerializer.Meta.fields + ('chapters', 'tags', 'genre_ids', 'status', 'is_owner')
    
    def get_is_owner(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.author == request.user
        return False


class NovelCreateSerializer(serializers.ModelSerializer):
    genre_ids = serializers.PrimaryKeyRelatedField(
        queryset=Genre.objects.all(), many=True, source='genres', required=False
    )
    genres = GenreSerializer(many=True, read_only=True)

    class Meta:
        model = Novel
        fields = (
            'id', 'title', 'description', 'cover_image', 'file',
            'genre_ids', 'genres', 'language', 'total_pages', 'total_chapters',
            'word_count', 'status', 'is_free', 'price', 'tags', 'created_at',
        )
        read_only_fields = ('id', 'author_name', 'total_chapters', 'word_count', 'created_at',)
    
    def validate_title(self, value):
        if len(value.strip()) < 3:
            raise serializers.ValidationError("Title must be at least 3 characters long.")
        return value


class NovelRatingSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    novel_title = serializers.CharField(source='novel.title', read_only=True)
    novel_id = serializers.UUIDField(source='novel.id', read_only=True)

    class Meta:
        model = NovelRating
        fields = ('id', 'novel_id', 'novel_title', 'rating', 'review', 'user_name', 'created_at')
        read_only_fields = ('id', 'user_name', 'created_at')

    def get_user_name(self, obj):
        return obj.user.full_name or obj.user.username


class FavoriteSerializer(serializers.ModelSerializer):
    novel = NovelListSerializer(read_only=True)

    class Meta:
        model = Favorite
        fields = ('id', 'novel', 'created_at')
