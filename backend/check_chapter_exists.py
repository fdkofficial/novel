import os
import django

def setup_django():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
    django.setup()

setup_django()

from apps.novels.models import Novel, Chapter

NOVEL_UUID = '9c1a5de7-78f2-48a8-a99c-1b3174056902'
CHAPTER_ID = 1

try:
    novel = Novel.objects.get(id=NOVEL_UUID)
    chapter = Chapter.objects.filter(novel=novel, id=CHAPTER_ID).first()
    if chapter:
        print(f'Chapter with ID {CHAPTER_ID} exists for novel {NOVEL_UUID}.')
    else:
        print(f'Chapter with ID {CHAPTER_ID} does NOT exist for novel {NOVEL_UUID}.')
except Novel.DoesNotExist:
    print(f'Novel with UUID {NOVEL_UUID} does NOT exist.')
