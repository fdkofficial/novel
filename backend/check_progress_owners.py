import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
django.setup()

from apps.novels.models import Genre, Novel
from apps.reading.models import ReadingProgress
from django.contrib.auth import get_user_model

User = get_user_model()

def check():
    try:
        users = User.objects.all()
        print(f"DEBUG_USER_COUNT={users.count()}")
        for u in users:
            print(f"USER: {u.username} (ID: {u.id})")
            
        progress = ReadingProgress.objects.all()
        print(f"DEBUG_PROGRESS_COUNT={progress.count()}")
        for p in progress:
            print(f"PROGRESS: User {p.user.username} read {p.novel.title} up to {p.progress_percentage}%")
        
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    check()
