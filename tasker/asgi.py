"""ASGI entrypoint — single Daphne server for HTTP + WebSocket.

The websocket leg is wired with an empty URLRouter so adding the first
WS route in a future IDEA is a one-file change, not a re-wiring.
"""

import os

from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "tasker.settings.dev")

django_asgi_app = get_asgi_application()

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        "websocket": AuthMiddlewareStack(URLRouter([])),
    }
)
