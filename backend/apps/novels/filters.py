import django_filters
from .models import Novel, Genre


class NovelFilter(django_filters.FilterSet):
    genre = django_filters.CharFilter(field_name='genres__slug', lookup_expr='exact')
    genre_id = django_filters.UUIDFilter(field_name='genres__id')
    min_rating = django_filters.NumberFilter(field_name='average_rating', lookup_expr='gte')
    max_rating = django_filters.NumberFilter(field_name='average_rating', lookup_expr='lte')
    language = django_filters.CharFilter(lookup_expr='iexact')
    is_free = django_filters.BooleanFilter()
    is_featured = django_filters.BooleanFilter()
    author_name = django_filters.CharFilter(lookup_expr='icontains')

    class Meta:
        model = Novel
        fields = ['genre', 'genre_id', 'language', 'is_free', 'is_featured', 'author_name']
