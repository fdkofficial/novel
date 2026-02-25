import random
from django.core.management.base import BaseCommand
from django.utils.text import slugify
from apps.novels.models import Genre, Novel, Chapter
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Seeds 25+ novels with chapters and genres'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding data...')

        # 1. Create Genres
        genre_names = [
            'Fantasy', 'Sci-Fi', 'Romance', 'Mystery', 'Horror', 
            'Thriller', 'Adventure', 'Drama', 'Comedy', 'Slice of Life'
        ]
        genres = []
        for name in genre_names:
            genre, created = Genre.objects.get_or_create(
                name=name,
                defaults={'slug': slugify(name), 'description': f'Great {name} novels'}
            )
            genres.append(genre)
        
        # 2. Get or create a default author
        author, _ = User.objects.get_or_create(
            username='system_author',
            defaults={
                'email': 'author@example.com',
                'is_staff': True
            }
        )
        if _:
            author.set_password('author123')
            author.save()

        # 3. Create 30 Novels
        titles = [
            "The Shadow over the Infinite", "Love in the Time of AI", "The Lost City of Gold",
            "Whispers of the ancient Woods", "Code of the Cyber Knight", "Petals of the Lunar Flower",
            "The Last Alchemist", "Echoes of the Void", "Mystery of the Clockwork Heart",
            "Beneath the Crimson Sky", "The Glass Throne", "Song of the Sea Siren",
            "The Midnight Library Ghost", "Stars Beyond Our Reach", "The Desert King's Heir",
            "Chronicles of the Broken Sword", "Dreams of the Floating Island", "The Silent Assassin",
            "Heart of the Machine", "Tale of the Twin Suns", "The Forgotten Empire",
            "Legacy of the Phoenix", "Dance of the Shadows", "The Golden Compass Quest",
            "Beyond the Frozen Gate", "The Alchemist's Secret", "Reign of the Fire Lord",
            "The Girl who Spoke to Wind", "Guardian of the Abyss", "The Emerald Dragon"
        ]

        descriptions = [
            "A thrilling journey into the unknown.",
            "A heartwarming romance set in a futuristic world.",
            "An epic adventure seeking lost treasures.",
            "A mysterious tale of ancient magic.",
            "High-stakes action in a cyberpunk city.",
            "A beautiful story about finding one's place in the universe.",
            "The quest for eternal life comes with a price.",
            "What lies in the darkness between stars?",
            "A steampunk mystery involving a lost artifact.",
            "Survival is the only goal in this post-apocalyptic world."
        ]

        for i, title in enumerate(titles):
            novel, created = Novel.objects.get_or_create(
                title=title,
                defaults={
                    'slug': slugify(f"{title}-{i}"),
                    'author': author,
                    'author_name': f"Author {random.randint(1, 10)}",
                    'description': random.choice(descriptions) + " " + "Highly recommended for all readers.",
                    'status': 'published',
                    'average_rating': round(random.uniform(3.5, 5.0), 1),
                    'rating_count': random.randint(10, 500),
                    'view_count': random.randint(100, 10000),
                    'favorite_count': random.randint(5, 100),
                    'total_chapters': 10,
                    'is_featured': i < 5
                }
            )
            
            if created:
                # Assign 1-3 random genres
                random_genres = random.sample(genres, k=random.randint(1, 3))
                novel.genres.set(random_genres)

            # 4. Create/Update 10 Chapters per Novel
            for ch_num in range(1, 11):
                content = (
                    f"<h2>Chapter {ch_num}: {title}</h2>"
                    f"<p>This is the beginning of an epic tale. The air was thick with anticipation as chapter {ch_num} unfolded. "
                    "In the heart of the city, secrets were being whispered in every corner. "
                    "Nobody knew what was coming next, but the feeling of change was undeniable. </p>"
                    "<p>As the sun dipped below the horizon, the true adventure began. "
                    "The protagonists gathered their strength, knowing that the road ahead would be long and treacherous. "
                    "But with courage in their hearts, they stepped forward into the unknown. </p>"
                ) * 10 # Repeat to make it longer
                
                Chapter.objects.update_or_create(
                    novel=novel,
                    chapter_number=ch_num,
                    defaults={
                        'title': f"The Adventure Begins Part {ch_num}" if ch_num == 1 else f"Chapter {ch_num}",
                        'content': content,
                        'word_count': len(content.split())
                    }
                )
        
        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {len(titles)} novels!'))
