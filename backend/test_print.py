print("Testing output...")
import os
import django
try:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
    django.setup()
    from apps.novels.models import Novel, Genre
    print(f"Total Novels: {Novel.objects.count()}")
    for novel in Novel.objects.all():
        print(f"- {novel.title}")
except Exception as e:
    print(f"Error: {e}")
