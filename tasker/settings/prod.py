"""Production settings — skeleton. Expected to be amended by the deployment IDEA.

Anything that depends on the actual hosting environment (real ALLOWED_HOSTS,
HSTS preload, logging handlers, error reporting) belongs there, not here.
"""

import os

from .base import *  # noqa: F401,F403

DEBUG = False

# Comma-separated list in the env; falls back to empty so a misconfigured
# prod fails loudly with DisallowedHost instead of silently allowing all.
ALLOWED_HOSTS = [h.strip() for h in os.environ.get("ALLOWED_HOSTS", "").split(",") if h.strip()]

SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]  # KeyError at startup if unset — intentional

# Behind nginx we terminate TLS at the proxy and forward X-Forwarded-Proto.
# Without this, SECURE_SSL_REDIRECT loops forever (Django sees the inner
# connection as http and redirects).
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 60 * 60 * 24 * 30  # 30 days; bump after the deployment IDEA verifies HSTS
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_CONTENT_TYPE_NOSNIFF = True
