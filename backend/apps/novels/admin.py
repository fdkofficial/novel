from django.contrib import admin
from .models import Novel, Genre, Chapter, NovelRating, Favorite


@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name',)


@admin.register(Novel)
class NovelAdmin(admin.ModelAdmin):
    list_display = ('title', 'author_name', 'status', 'is_featured', 'view_count', 'average_rating', 'created_at')
    list_filter = ('status', 'is_featured', 'is_free', 'language')
    search_fields = ('title', 'author_name', 'description')
    prepopulated_fields = {'slug': ('title',)}
    filter_horizontal = ('genres',)
    readonly_fields = ('view_count', 'download_count', 'favorite_count', 'average_rating', 'rating_count')
    date_hierarchy = 'created_at'


@admin.register(Chapter)
class ChapterAdmin(admin.ModelAdmin):
    list_display = ('novel', 'chapter_number', 'title', 'word_count', 'is_free')
    list_filter = ('novel', 'is_free')
    search_fields = ('title', 'novel__title')
    ordering = ('novel', 'chapter_number')


@admin.register(NovelRating)
class NovelRatingAdmin(admin.ModelAdmin):
    list_display = ('novel', 'user', 'rating', 'created_at')
    list_filter = ('rating',)
    readonly_fields = ('novel', 'user', 'rating', 'created_at')


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ('user', 'novel', 'created_at')
    list_filter = ('created_at',)
