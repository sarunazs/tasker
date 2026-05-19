# Development Log — 2026-05

Chronological log of merged work (newest first). One entry per IDEA-bearing PR, with links to the archive dir and PR. Maintained by `/wrap`.

---

## 2026-05-19 — IDEA-001: Bootstrap Django + Docker Compose Skeleton (PR #1)

**Scope**: First IDEA of the project. Lays the Django + Docker Compose foundation every later IDEA builds on. Empty repo → runnable, healthchecked, smoke-tested stack in one PR, with the mind-vault sprint workflow (idea → plan → architect-review → work → wrap) exercised end-to-end against its own scaffolding.

### What shipped

- **Django 5.2.9 project package** at `tasker/` with split settings (`base.py` / `dev.py` / `prod.py`), `manage.py`, `asgi.py` (`ProtocolTypeRouter` with HTTP + empty WS leg ready for future Channels routes), admin + landing view at `/`.
- **`apps/` directory** scaffolded empty (`apps/__init__.py` only) — domain apps (projects, tasks, users) belong to later IDEAs.
- **Dockerfile**: `python:3.13-slim`, `ARG UID` for host-UID matching, `libpq-dev` + `curl` (the latter for the healthcheck), non-root `app` user, Daphne entrypoint.
- **`compose.yml`** four services: `web` (Daphne, healthchecked on `GET /`), `db` (Postgres 16-alpine, `pg_isready` healthcheck), `redis` (7-alpine, `redis-cli ping`), `nginx` (1.27-alpine, gated on `web` `service_healthy`). `HTTP_PORT` parameterised via env so parallel stacks don't collide.
- **`nginx/default.conf`**: `proxy_pass` to `web:8000`, WebSocket upgrade headers, `X-Forwarded-Proto`, static + media aliases backed by named volumes (`static_data`, `media_data`).
- **Makefile**: `up`, `down`, `build`, `shell`, `test ARGS=…` (supports pytest nodeids with `::`), `migrate`, `makemigrations`, `logs svc=…`, `psql`, `redis-cli`, `lint`, `pip-compile`.
- **Test harness**: `pytest.ini` with `DJANGO_SETTINGS_MODULE=tasker.settings.dev` and `testpaths = tasker apps`; smoke test in `tasker/tests/test_smoke.py` exercising the full nginx → daphne → django chain.
- **Dependency management**: `requirements{,-dev}.in` + `.txt` via pip-tools (`channels[daphne]`, `channels-redis`, `psycopg[binary]` 3.x, DRF, `pip-tools>=7.4`, pytest-django, pyflakes).
- **`.env.template`** declared contract (DJANGO_SECRET_KEY, POSTGRES_*, REDIS_URL, HTTP_PORT, UID with `$(id -u)` guidance), `.dockerignore`, and a README quickstart.

### Architect-review revisions applied during /plan

`AGENT_architect` reviewer pass on the draft plan — verdict `REQUIRES REVISION`. All 10 concrete findings applied before `/work` started:

- UID-mismatch on bind-mounted source (blocker) → `ARG UID` + compose `args.UID="${UID:-1000}"`.
- Makefile `path=` fragile with pytest `::` nodeids (blocker) → renamed to `ARGS ?=`.
- nginx starts before daphne ready → `web` healthcheck + nginx `depends_on: { web: { condition: service_healthy } }`.
- `settings/__init__.py` left empty (no re-export ambiguity).
- Dropped `tasker/wsgi.py` (dead code; Daphne single-server) and `python-dotenv` (compose `env_file:` covers it).
- `prod.py` `SECURE_PROXY_SSL_HEADER` (prevent SSL-redirect loop behind nginx).
- `pip-tools>=7.4` pin (reliable extras resolution).
- `HTTP_PORT` parameterised (forward-compat with parallel stacks).
- Smoke test dropped unnecessary `@pytest.mark.django_db`.

### Runtime fixes landed in the same PR

Two additional fix commits during `/work` verification:

- **`fix(make): exclude split-settings overrides from pyflakes target`** — pyflakes false-positives on the deliberate `from .base import *` in `settings/dev.py` and `settings/prod.py` (Django split-settings convention; pyflakes can't introspect and doesn't honor `# noqa`). Excluded by name; `base.py` + `__init__.py` stay in scope.
- **`fix(settings): set CSRF_TRUSTED_ORIGINS in dev so admin login works`** — Django 4.0+ rejects POSTs whose `Origin` isn't in `CSRF_TRUSTED_ORIGINS`. Out of the box, admin login returned 403 with `Origin checking failed`. Derived from `HTTP_PORT` env so the dev stack works on whatever port the host assigned.

### Verification

- Stack: `db`, `redis`, `web` healthy; `nginx` running.
- `make migrate`: contrib migrations apply clean.
- `make test`: 1 passed (full suite) + `make test ARGS=tasker/tests/test_smoke.py::test_landing_view_returns_200` (surgical nodeid) also passes.
- HTTP: `GET /` → 200 + body `tasker is alive`; `/admin/` → 302; admin login POST → 302 (after CSRF fix).
- `make lint`: clean (exit 0) after pyflakes scope fix.
- UID bind-mount: host can create/delete files in `./` without sudo.
- Postgres volume persists across `make down && make up`; second `make migrate` reports "no migrations to apply".
- Host port surprise: `:80` and `:8080` were in use on the verification host; `HTTP_PORT=8088` absorbed it without touching `compose.yml` — exactly the case the architect review's port parameterisation protected against.

### Related

- [IDEA-001 archive](./2026-05-idea-001-bootstrap-django-docker-skeleton/)
- [PR #1](https://github.com/sarunazs/tasker/pull/1)
