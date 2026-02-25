"""
WSGI config for novel_reading_api project.
"""

import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'novel_reading_api.settings')
application = get_wsgi_application()
