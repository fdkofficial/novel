import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
django.setup()

from apps.novels.models import Novel, Genre

print(f"Total Novels: {Novel.objects.count()}")
print(f"Published Novels: {Novel.objects.filter(status='published').count()}")
for novel in Novel.objects.all():
    print(f"- {novel.title} ({novel.status})")

print(f"Total Genres: {Genre.objects.count()}")
for genre in Genre.objects.all():
    print(f"- {genre.name} ({genre.slug})")
