import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
django.setup()

from apps.novels.models import Novel, Genre

output = []
output.append(f"Total Novels: {Novel.objects.count()}")
for novel in Novel.objects.all():
    output.append(f"- {novel.title} ({novel.status}) [ID: {novel.id}]")

output.append(f"Total Genres: {Genre.objects.count()}")
for genre in Genre.objects.all():
    output.append(f"- {genre.name} [ID: {genre.id}]")

with open('db_status.txt', 'w') as f:
    f.write('\n'.join(output))

print("Status written to db_status.txt")
