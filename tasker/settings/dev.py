"""Development settings."""

import os

from .base import *  # noqa: F401,F403

DEBUG = True
ALLOWED_HOSTS = ["*"]

SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False

# Django 4.0+ rejects POSTs whose Origin header isn't in CSRF_TRUSTED_ORIGINS
# (even on same-origin requests behind a proxy, the Origin check still runs).
# Derive from HTTP_PORT so the dev stack works on whatever port the host
# assigned. Prod sets this explicitly via its own ALLOWED_HOSTS-style env var.
_HTTP_PORT = os.environ.get("HTTP_PORT", "80")
CSRF_TRUSTED_ORIGINS = [
    f"http://localhost:{_HTTP_PORT}",
    f"http://127.0.0.1:{_HTTP_PORT}",
]
