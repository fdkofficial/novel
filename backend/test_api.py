import os
import django
from django.test import RequestFactory
from rest_framework.request import Request

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
django.setup()

from apps.novels.views import NovelViewSet
from apps.novels.models import Novel

factory = RequestFactory()

def test_search(query):
    request = factory.get('/api/v1/novels/', {'search': query})
    view = NovelViewSet.as_view({'get': 'list'})
    response = view(request)
    print(f"Search for '{query}': {response.status_code}")
    print(f"Data: {response.data}")

def test_genre(genre_id):
    request = factory.get('/api/v1/novels/', {'genre': genre_id})
    view = NovelViewSet.as_view({'get': 'list'})
    response = view(request)
    print(f"Filter by genre '{genre_id}': {response.status_code}")
    print(f"Data: {response.data}")

# Test with seeded data
test_search("Great")
test_search("Odyssey")
novel = Novel.objects.first()
if novel and novel.genres.exists():
    genre_id = novel.genres.first().id
    test_genre(genre_id)
else:
    print("No novels or genres to test.")
