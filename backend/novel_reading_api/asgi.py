"""
ASGI config for novel_reading_api project.
"""

import os
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
application = get_asgi_application()
