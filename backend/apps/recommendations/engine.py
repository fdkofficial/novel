"""
AI Recommendation Engine

Implements:
1. Rule-based scoring (engagement signals)
2. Content-based filtering (genre/tag similarity)
3. Collaborative filtering (user similarity via cosine similarity)
4. Hybrid model (weighted combination)
"""

import numpy as np
import logging
from django.db.models import Q
from django.contrib.auth import get_user_model

logger = logging.getLogger(__name__)
User = get_user_model()


class RecommendationEngine:
    """Hybrid recommendation engine combining multiple algorithms."""

    def __init__(self, user):
        self.user = user

    def get_recommendations(self, limit=20):
        """Get hybrid recommendations for a user."""
        from apps.novels.models import Novel
        from .models import Recommendation, ReadingBehavior

        # Get already-read/interacted novels to exclude
        interacted_novel_ids = ReadingBehavior.objects.filter(
            user=self.user
        ).values_list('novel_id', flat=True)

        candidate_novels = Novel.objects.filter(
            status='published'
        ).exclude(id__in=interacted_novel_ids)

        # Compute scores from each algorithm
        scores = {}

        try:
            content_scores = self._content_based_scores(candidate_novels)
            for novel_id, score in content_scores.items():
                scores[novel_id] = scores.get(novel_id, 0) + score * 0.4
        except Exception as e:
            logger.warning(f'Content-based failed: {e}')

        try:
            collab_scores = self._collaborative_scores(candidate_novels)
            for novel_id, score in collab_scores.items():
                scores[novel_id] = scores.get(novel_id, 0) + score * 0.35
        except Exception as e:
            logger.warning(f'Collaborative failed: {e}')

        try:
            rule_scores = self._rule_based_scores(candidate_novels)
            for novel_id, score in rule_scores.items():
                scores[novel_id] = scores.get(novel_id, 0) + score * 0.25
        except Exception as e:
            logger.warning(f'Rule-based failed: {e}')

        # If no scores, fall back to trending
        if not scores:
            trending = candidate_novels.order_by('-view_count', '-average_rating')[:limit]
            return [{'novel': n, 'score': 0, 'algorithm': 'trending', 'reason': 'Trending now'} for n in trending]

        # Sort by score
        sorted_novels = sorted(scores.items(), key=lambda x: x[1], reverse=True)[:limit]
        novel_ids = [str(nid) for nid, _ in sorted_novels]
        novel_map = {str(n.id): n for n in Novel.objects.filter(id__in=novel_ids)}

        results = []
        for novel_id, score in sorted_novels:
            novel = novel_map.get(str(novel_id))
            if novel:
                results.append({
                    'novel': novel,
                    'score': round(score, 4),
                    'algorithm': 'hybrid',
                    'reason': self._generate_reason(novel),
                })

        # Save recommendations
        self._save_recommendations(results)
        return results

    def _content_based_scores(self, candidates):
        """Score based on genre similarity to user preferences."""
        from .models import GenrePreference

        scores = {}
        user_prefs = {
            str(gp.genre_id): gp.preference_score
            for gp in GenrePreference.objects.filter(user=self.user)
        }

        if not user_prefs:
            return scores

        for novel in candidates.prefetch_related('genres'):
            genre_score = 0.0
            for genre in novel.genres.all():
                genre_score += user_prefs.get(str(genre.id), 0)
            if genre_score > 0:
                scores[novel.id] = min(genre_score / 100.0, 1.0)

        return scores

    def _collaborative_scores(self, candidates):
        """Score based on similar users' preferences using cosine similarity."""
        from .models import ReadingBehavior

        # Get this user's behavior vector
        user_behaviors = ReadingBehavior.objects.filter(user=self.user)
        if not user_behaviors.exists():
            return {}

        user_novel_ids = set(user_behaviors.values_list('novel_id', flat=True))

        # Find users who read at least 2 of the same novels
        similar_user_ids = ReadingBehavior.objects.filter(
            novel_id__in=user_novel_ids
        ).exclude(
            user=self.user
        ).values_list('user_id', flat=True).distinct()[:100]

        if not similar_user_ids:
            return {}

        # Build vectors for cosine similarity
        all_novel_ids = list(candidates.values_list('id', flat=True))
        user_vec = np.zeros(len(all_novel_ids))

        novel_idx = {nid: i for i, nid in enumerate(all_novel_ids)}
        for b in user_behaviors:
            if b.novel_id in novel_idx:
                user_vec[novel_idx[b.novel_id]] = b.engagement_score

        scores = {}
        for similar_user_id in similar_user_ids:
            sim_behaviors = ReadingBehavior.objects.filter(user_id=similar_user_id)
            sim_vec = np.zeros(len(all_novel_ids))
            for b in sim_behaviors:
                if b.novel_id in novel_idx:
                    sim_vec[novel_idx[b.novel_id]] = b.engagement_score

            # Cosine similarity
            norm = np.linalg.norm(user_vec) * np.linalg.norm(sim_vec)
            if norm > 0:
                similarity = np.dot(user_vec, sim_vec) / norm
                # Weight their novel scores by similarity
                for b in sim_behaviors:
                    if b.novel_id in novel_idx and b.novel_id not in user_novel_ids:
                        scores[b.novel_id] = scores.get(b.novel_id, 0) + similarity * b.engagement_score / 100

        return scores

    def _rule_based_scores(self, candidates):
        """Simple rule-based scoring on novel metadata."""
        scores = {}
        for novel in candidates:
            score = 0.0
            score += min(novel.view_count / 10000, 0.3)
            score += min(novel.average_rating / 5.0, 0.5) * 0.4
            score += min(novel.download_count / 5000, 0.2)
            if novel.is_featured:
                score += 0.1
            scores[novel.id] = min(score, 1.0)
        return scores

    def _generate_reason(self, novel):
        """Generate human-readable reason for recommendation."""
        if novel.average_rating >= 4.5:
            return f'Highly rated ({novel.average_rating:.1f}★)'
        if novel.view_count > 10000:
            return 'Trending with readers'
        if novel.is_featured:
            return 'Editor\'s pick'
        return 'Based on your reading history'

    def _save_recommendations(self, results):
        """Persist recommendations to database."""
        from .models import Recommendation
        Recommendation.objects.filter(user=self.user, is_seen=False).delete()
        to_create = [
            Recommendation(
                user=self.user,
                novel=r['novel'],
                score=r['score'],
                algorithm=r['algorithm'],
                reason=r['reason'],
            )
            for r in results
        ]
        Recommendation.objects.bulk_create(to_create, ignore_conflicts=True)


def update_behavior_from_progress(user, novel, progress):
    """Update ReadingBehavior when reading progress changes."""
    from .models import ReadingBehavior, GenrePreference

    behavior, _ = ReadingBehavior.objects.get_or_create(
        user=user, novel=novel
    )
    behavior.reading_sessions += 1
    behavior.total_time_minutes += progress.get('session_minutes', 0)
    behavior.completion_percentage = progress.get('progress_percentage', behavior.completion_percentage)
    behavior.is_completed = behavior.completion_percentage >= 95.0
    behavior.compute_engagement_score()
    behavior.save()

    # Update genre preferences
    for genre in novel.genres.all():
        pref, _ = GenrePreference.objects.get_or_create(user=user, genre=genre)
        pref.preference_score = min(pref.preference_score + behavior.engagement_score * 0.1, 100)
        pref.save(update_fields=['preference_score', 'updated_at'])
