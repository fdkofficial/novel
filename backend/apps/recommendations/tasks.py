from celery import shared_task
from django.contrib.auth import get_user_model
import logging

logger = logging.getLogger(__name__)
User = get_user_model()


@shared_task(name='recommendations.generate_for_user')
def generate_recommendations_for_user(user_id):
    """Celery task: generate AI recommendations for a specific user."""
    try:
        user = User.objects.get(id=user_id)
        from .engine import RecommendationEngine
        engine = RecommendationEngine(user)
        results = engine.get_recommendations(limit=30)
        logger.info(f'Generated {len(results)} recommendations for {user.username}')
        return {'status': 'success', 'count': len(results)}
    except Exception as e:
        logger.error(f'Failed to generate recommendations for user {user_id}: {e}')
        return {'status': 'error', 'error': str(e)}


@shared_task(name='recommendations.generate_for_all')
def generate_recommendations_for_all_users():
    """Celery periodic task: generate recommendations for all active users."""
    user_ids = User.objects.filter(is_active=True).values_list('id', flat=True)
    for user_id in user_ids:
        generate_recommendations_for_user.delay(str(user_id))
    return {'scheduled': len(user_ids)}
