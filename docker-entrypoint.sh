#!/usr/bin/env bash
# Bring the web container to a usable state on every start:
#   1. apply migrations
#   2. collect static files
#   3. (dev only) provision a superuser from env if absent
#   4. exec the requested CMD (daphne by default)
#
# Idempotent — safe to re-run on every container start.

set -euo pipefail

echo "[entrypoint] applying migrations…"
python manage.py migrate --noinput

echo "[entrypoint] collecting static files…"
python manage.py collectstatic --noinput --verbosity 0

# Dev-only superuser bootstrap. Guarded on the settings module to make it
# impossible to accidentally provision an admin from env in production.
if [ "${DJANGO_SETTINGS_MODULE:-}" = "tasker.settings.dev" ] \
   && [ -n "${DJANGO_SUPERUSER_USERNAME:-}" ] \
   && [ -n "${DJANGO_SUPERUSER_PASSWORD:-}" ]; then
    echo "[entrypoint] ensuring dev superuser '${DJANGO_SUPERUSER_USERNAME}' exists…"
    python manage.py shell <<PY
from django.contrib.auth import get_user_model
import os
U = get_user_model()
username = os.environ["DJANGO_SUPERUSER_USERNAME"]
email = os.environ.get("DJANGO_SUPERUSER_EMAIL", "")
password = os.environ["DJANGO_SUPERUSER_PASSWORD"]
u, created = U.objects.get_or_create(
    username=username,
    defaults={"email": email, "is_staff": True, "is_superuser": True},
)
if created:
    u.set_password(password)
    u.save()
    print(f"[entrypoint] created superuser '{username}'")
else:
    print(f"[entrypoint] superuser '{username}' already present — leaving as-is")
PY
fi

echo "[entrypoint] starting: $*"
exec "$@"
