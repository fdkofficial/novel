import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
django.setup()

from apps.novels.models import Genre, Novel
from apps.reading.models import ReadingProgress

def check():
    try:
        genres = Genre.objects.all()
        novels = Novel.objects.all()
        progress = ReadingProgress.objects.all()
        
        print(f"DEBUG_GENRE_COUNT={genres.count()}")
        print(f"DEBUG_NOVEL_COUNT={novels.count()}")
        print(f"DEBUG_PROGRESS_COUNT={progress.count()}")
        
        for g in genres:
            print(f"GENRE: {g.name}")
        
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    check()
