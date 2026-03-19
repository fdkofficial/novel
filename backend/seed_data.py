import os
import django
from django.utils.text import slugify

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
django.setup()

from apps.novels.models import Novel, Genre
from django.contrib.auth import get_user_model

User = get_user_model()
user = User.objects.first()
if not user:
    user = User.objects.create_superuser('admin', 'admin@example.com', 'admin123')

# Create Genres
fantasy, _ = Genre.objects.get_or_create(name='Fantasy', defaults={'slug': 'fantasy'})
scifi, _ = Genre.objects.get_or_create(name='Sci-Fi', defaults={'slug': 'sci-fi'})

# Create Novels
n1, _ = Novel.objects.get_or_create(
    title='The Great Adventure',
    defaults={
        'author_name': 'John Doe',
        'description': 'An epic fantasy adventure.',
        'status': 'published',
        'slug': 'the-great-adventure'
    }
)
n1.genres.add(fantasy)

n2, _ = Novel.objects.get_or_create(
    title='Space Odyssey',
    defaults={
        'author_name': 'Jane Smith',
        'description': 'A journey through space.',
        'status': 'published',
        'slug': 'space-odyssey'
    }
)
n2.genres.add(scifi)

print("Seeded database successfully.")
