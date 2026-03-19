import os
import django
from django.test import RequestFactory

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
django.setup()

from apps.novels.views import NovelViewSet
from apps.novels.models import Novel

factory = RequestFactory()

def run_test():
    # 1. Total count
    print(f"Total Novels in DB: {Novel.objects.count()}")
    for n in Novel.objects.all():
        print(f" - {n.title} (Status: {n.status}, Genres: {[g.name for g in n.genres.all()]})")

    # 2. Test List View (no filter)
    request = factory.get('/api/v1/novels/')
    view = NovelViewSet.as_view({'get': 'list'})
    response = view(request)
    print(f"\nList View Status: {response.status_code}")
    # Fix for response.data in DRF testing
    print(f"List Count: {len(response.data['results']) if 'results' in response.data else len(response.data)}")

    # 3. Test Search
    request = factory.get('/api/v1/novels/', {'search': 'Great'})
    response = view(request)
    print(f"\nSearch 'Great' Status: {response.status_code}")
    print(f"Search Results: {response.data}")

    # 4. Test Genre Filter
    novel = Novel.objects.filter(status='published').first()
    if novel and novel.genres.exists():
        genre_id = novel.genres.first().id
        request = factory.get('/api/v1/novels/', {'genre': str(genre_id)})
        response = view(request)
        print(f"\nGenre Filter '{genre_id}' Status: {response.status_code}")
        print(f"Genre Results: {response.data}")

if __name__ == "__main__":
    run_test()
