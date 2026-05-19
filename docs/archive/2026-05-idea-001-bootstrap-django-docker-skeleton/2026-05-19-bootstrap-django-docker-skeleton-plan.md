---
stage: plan
slug: bootstrap-django-docker-skeleton
created: 2026-05-19
source: ./IDEA-001-bootstrap-django-docker-skeleton.md
status: draft
project: tasker
---

# Bootstrap Django + Docker Compose Skeleton — Implementation Plan

## Context

`tasker` is empty — only `CLAUDE.md`, `.gitignore`, and the IDEA-001 capture exist (the genesis commit). Every subsequent IDEA depends on a working Django + Docker Compose stack: a runnable web service, a database, a cache/channel layer, and the developer-facing harness (Makefile, pytest, settings split) to iterate on top of. This plan delivers that foundation in one feature branch and one PR.

The project's larger purpose is mind-vault workflow dogfooding, so the plan is also a test of `/plan → /work → /wrap → /compound` discipline. The scaffold itself is conventional; the workflow flowing through it is the point.

## Problem Frame

- No source code → no runnable `manage.py`, no test harness, no admin, no migrations.
- No Docker artefacts → no reproducible dev environment; a teammate cloning the repo has nothing to `docker compose up`.
- No declared env-var contract → the first feature IDEA would have to invent one ad-hoc.
- No conventions locked in (settings layout, app directory, Daphne-single-server, Makefile-first) → every IDEA risks introducing alternatives by accident.

Every later IDEA is blocked on these. Fix it once, properly, before any feature work begins.

## Requirements Trace

- **R1.** Django 5.2.9 project package at `tasker/` with split settings (`tasker/settings/{base,dev,prod}.py`), `asgi.py` configured for Channels, `urls.py` skeleton, `manage.py` at repo root.
- **R2.** `apps/` directory established as the home for future domain apps; empty at bootstrap (only `apps/__init__.py`).
- **R3.** Single-stage `Dockerfile` (Python 3.13-slim base) installing project deps via `pip-tools`-generated `requirements.txt` + `requirements-dev.txt`.
- **R4.** `compose.yml` with services: `web` (Daphne ASGI, single server for HTTP + WS), `db` (Postgres 16), `redis` (cache + Channels layer), `nginx` (HTTP-facing proxy).
- **R5.** `nginx/default.conf` with `proxy_pass` to `web:8000`, WebSocket upgrade headers, `/static/` + `/media/` aliases backed by named volumes.
- **R6.** `Makefile` with targets: `up`, `down`, `build`, `shell`, `test`, `migrate`, `makemigrations`, `logs`, `psql`, `redis-cli`, `lint`. Every target wraps `docker compose exec` — no host-level Python or pip.
- **R7.** `.env.template` declaring every env var (`DJANGO_SECRET_KEY`, `DJANGO_SETTINGS_MODULE`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`, `REDIS_URL`, `ALLOWED_HOSTS`, `DEBUG`). Real `.env` gitignored (already covered).
- **R8.** `pytest.ini` + `conftest.py` with `pytest-django` wired (`DJANGO_SETTINGS_MODULE = tasker.settings.dev`). Sample smoke test that hits a landing view and asserts HTTP 200 — proves the harness runs end-to-end.
- **R9.** `.gitignore` already in place (genesis commit); confirm coverage extends to anything new this plan introduces (`requirements*.txt`-stamps, `staticfiles/`, etc.).
- **R10.** `docs/ideas/` + `docs/archive/` already present; no work required for this requirement at the file system level (just confirm during verification).

## Scope Boundaries

**In scope:**

- All files listed in the Execution Sequence below.
- A minimal `landing` view at `/` (returns "tasker is alive" or similar) — present **only** to give the smoke test something to hit through the full nginx → daphne → django chain.
- Channels + channels-redis wired into `asgi.py` with a `ProtocolTypeRouter`, even though no WebSocket routes exist yet — adding the first WS route should be a single-file change in a future IDEA, not a re-wiring.
- DRF declared in `INSTALLED_APPS` (no viewsets yet) — same logic as Channels: present so the first API IDEA doesn't have to amend settings.

**Out of scope:**

- Domain models (`projects`, `tasks`, `users`) — later IDEAs.
- Custom auth user model — uses `django.contrib.auth.User` as-is; swap is a later IDEA if needed.
- CI/CD pipeline (GitHub Actions) — separate IDEA once there's something worth testing in CI.
- Production deployment (staging VPS, SSL, Let's Encrypt, deploy scripts) — separate IDEA once a host is chosen.
- Celery (worker + beat services) — Redis is provisioned but Celery deferred until an IDEA needs background jobs.
- Frontend tooling (Bulma/Tailwind/Sass build, Alpine, HTMX includes) — separate IDEA when the first non-trivial template lands.
- `compose.override.yml` split — single `compose.yml` for now; override-pattern lands when the deployment IDEA materialises.

**Explicit non-goals:**

- Do not configure a Gunicorn + Daphne split. Daphne is the single ASGI server, full stop (IDEA-explicit).
- Do not introduce Poetry, uv, or any non-pip-tools dependency manager.
- Do not create a domain app skeleton (`apps/projects/`, etc.) as a "head start" — `apps/` stays empty by design until a domain IDEA fills it.
- Do not enable production hardening (`SECURE_*` flags, HSTS, etc.) in `dev.py`. They belong in `prod.py` and only matter once a deployment IDEA hooks it up.

## Context & Research

### Existing code and patterns to reuse

- `CLAUDE.md` — declares the stack and naming conventions; the plan stays consistent with it (Daphne single-server, Makefile-first, `tasker/` project package + `apps/` domain dir, `.env.template` contract).
- `.gitignore` (genesis commit) — already covers `__pycache__`, `staticfiles/`, `media/`, `.env`, editor/OS noise, `node_modules/`, `.claude/settings.local.json`. No additions needed for this plan.
- `docs/ideas/README.md` — index pattern; already maintained by `/idea`.

### Institutional learnings

- `mind-vault/skills/django/SKILL.md` — Django backend conventions (BaseModel abstractions, DRF viewsets, ORM optimisation). Not exercised at bootstrap (no models yet) but governs every later IDEA.
- `mind-vault/skills/django-frontend/SKILL.md` — HTMX + Alpine + Bulma + Cotton. Not exercised at bootstrap (no templates beyond the smoke landing) but governs frontend IDEAs.
- `mind-vault/skills/deployment/SKILL.md` — Docker Compose conventions, change-aware scripts. Bootstrap establishes the shape (Daphne, nginx, named volumes) the deployment IDEA will build on.
- `mind-vault/skills/surgical-tdd/SKILL.md` — fully-qualified pytest nodeids over the full suite. `pytest.ini` + `Makefile test` target structured so `make test path=apps/foo/tests/test_x.py::TestY::test_z` works.
- `RULE_self-sweep-before-push` — `pyflakes` runs in-container before commit. Makefile gets a `lint` target wrapping `python -m pyflakes`.
- `RULE_git-safety` — every commit on the feature branch; PR targets `main`; human merges.

### External references

- Django 5.2 release notes (Python 3.10+ supported, Python 3.13 supported).
- Channels 4.x — `ProtocolTypeRouter`, `URLRouter`, `AuthMiddlewareStack` for future WS routes.
- `channels-redis` — Redis-backed channel layer config shape.
- `psycopg[binary]` (psycopg 3) — preferred over `psycopg2-binary` for new Django projects.

## Key Technical Decisions

- **Python 3.13.** Latest stable; Django 5.2 supports it. Locked in the `Dockerfile`'s `FROM python:3.13-slim` and reflected in `requirements.in` comments.
- **Single-stage Dockerfile.** Readability > image size at this stage. Multi-stage (separate builder/runtime) can come in a later optimisation IDEA if image size becomes a problem.
- **`pip-tools` (`pip-compile`) for dep management.** `requirements.in` + `requirements-dev.in` checked in; `requirements.txt` + `requirements-dev.txt` generated and checked in. Reproducible builds; clear pin-history; aligns with the `RULE_self-sweep-before-push` pyflakes-pipe pattern (no Poetry surface to learn).
- **Split settings (`tasker/settings/{base,dev,prod}.py`) with `__init__.py` re-export.** `DJANGO_SETTINGS_MODULE` defaults to `tasker.settings.dev` in dev; `tasker.settings.prod` in prod. Cleaner than `if DEBUG:` branching in a flat `settings.py`.
- **Daphne as the single ASGI server.** No Gunicorn. Daphne handles HTTP + WS in one process; nginx proxies to it. IDEA-explicit.
- **Channels wired from day one** even with no WS routes. `asgi.py` uses `ProtocolTypeRouter({"http": django_asgi_app, "websocket": ...})`; the websocket leg points at an empty `URLRouter([])` until a future IDEA adds routes.
- **DRF in `INSTALLED_APPS` from day one.** Same logic — cheaper to wire now than to amend settings later.
- **Postgres 16-alpine, Redis 7-alpine.** Smaller images, well-supported. Named volume for Postgres data (`tasker_postgres_data`); Redis is ephemeral.
- **Healthchecks on `db` and `redis`; `web` `depends_on: { db: { condition: service_healthy } }`.** Avoids the classic "web starts before postgres is ready" race in fresh stacks.
- **nginx config bind-mounted in dev.** `./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro` — edits land without rebuilding the image. Production IDEA will switch to a `COPY`-baked nginx image.
- **Non-root container user inside the Django image.** `useradd app` + `USER app`; the project source is bind-mounted at `/app` and owned by that uid.
- **`requirements.txt` checked in, `requirements.in` is the source of truth.** Bump-via-`pip-compile --upgrade` is the documented workflow (Makefile target: `make pip-compile`).
- **Single `compose.yml`.** No override file at bootstrap; deployment IDEA decides whether to introduce one.

## Open Questions

- **Q1. Landing view: full HTML page or plain-text "ok"?**
  - **Default:** Plain-text `"tasker is alive"` returned from a function-based view at `/`. Cheap; the smoke test just asserts 200 + body contains "alive".
  - **Trade-off:** A real homepage tempts scope creep (templates, base layout, static assets). Plain-text keeps the bootstrap minimal; the first templated page is a later IDEA's concern.

- **Q2. `apps/` directory: ship empty with `apps/__init__.py` only, or also a `.gitkeep`?**
  - **Default:** Just `apps/__init__.py` (empty). Makes `apps` importable as a Python package; git tracks the file (non-empty would also work but adds nothing). Skip `.gitkeep`.
  - **Trade-off:** None material.

- **Q3. Pin `psycopg[binary]` (psycopg 3, modern) or `psycopg2-binary` (still ubiquitous)?**
  - **Default:** `psycopg[binary]` (psycopg 3). Django 5.2 supports it natively; psycopg2 is in maintenance mode. Slightly faster, better async story (matters for Channels later).
  - **Trade-off:** Marginally less Stack Overflow coverage for novel errors. Acceptable.

- **Q4. Should `make test` default to the full suite or require an explicit `path=`?**
  - **Default:** Full suite when no `path=` is passed; `make test path=apps/foo/tests/test_x.py::TestY::test_z` for surgical runs. Keeps the CI-equivalent invocation as the bare `make test`.
  - **Trade-off:** Surgical-first default would be `RULE_surgical-tdd`-pure but breaks the "run all tests before push" expectation.

- **Q5. Should the smoke test live in `tasker/tests/test_smoke.py` or in a new `apps/_smoke/`?**
  - **Default:** `tasker/tests/test_smoke.py` (alongside the project package). The smoke test is about the framework wiring, not a domain concern. When the first domain app lands, its own tests live in `apps/<app>/tests/`.
  - **Trade-off:** Mixing test layout (some tests under `tasker/`, others under `apps/<app>/`) — but `pytest.ini`'s `testpaths` covers both, so collection works uniformly.

## Execution Sequence

All work on branch `feature/idea-001-bootstrap-django-docker-skeleton` (already created). Each commit is a logical chunk; the branch ends with one PR to `main`.

### Commit 1 — Dependency declarations (`build(deps): declare base dependencies`)

- `requirements.in` — runtime deps:
  ```
  django==5.2.9
  djangorestframework
  channels[daphne]
  channels-redis
  psycopg[binary]
  redis
  python-dotenv
  ```
- `requirements-dev.in` — dev deps:
  ```
  -c requirements.txt
  pytest
  pytest-django
  pip-tools
  pyflakes
  ```
- `requirements.txt`, `requirements-dev.txt` — generated by `pip-compile` (run via a temporary container later; or generate on host with `pipx install pip-tools` for the first compile).

### Commit 2 — Django project package (`feat(tasker): project package scaffold`)

- `manage.py` — standard Django entrypoint, defaults to `tasker.settings.dev`.
- `tasker/__init__.py` — empty.
- `tasker/settings/__init__.py` — `from .base import *` (so `tasker.settings` resolves for tooling that doesn't know the split).
- `tasker/settings/base.py`:
  - `INSTALLED_APPS`: contrib + `daphne` (must precede `django.contrib.staticfiles` for Channels), `channels`, `rest_framework`.
  - `DATABASES` from env (`POSTGRES_*`).
  - `CACHES` → `django.core.cache.backends.redis.RedisCache` reading `REDIS_URL`.
  - `CHANNEL_LAYERS` → `channels_redis.core.RedisChannelLayer` reading `REDIS_URL`.
  - `ASGI_APPLICATION = "tasker.asgi.application"`.
  - `AUTH_PASSWORD_VALIDATORS`, `LANGUAGE_CODE`, `TIME_ZONE`, `USE_I18N`, `USE_TZ`.
  - `STATIC_URL = "/static/"`, `STATIC_ROOT = BASE_DIR / "staticfiles"`.
  - `MEDIA_URL = "/media/"`, `MEDIA_ROOT = BASE_DIR / "media"`.
  - `TEMPLATES` default.
  - `SECRET_KEY` from env; raise if missing in prod.
- `tasker/settings/dev.py`: `DEBUG=True`, `ALLOWED_HOSTS=["*"]`, no secure cookies.
- `tasker/settings/prod.py`: `DEBUG=False`, `ALLOWED_HOSTS` from env, `SECURE_SSL_REDIRECT=True`, etc. (Not wired to a deployment yet; lives ready for the deployment IDEA.)
- `tasker/urls.py`: `path("admin/", admin.site.urls), path("", views.landing)`.
- `tasker/views.py`: `def landing(request): return HttpResponse("tasker is alive")`.
- `tasker/asgi.py`: `ProtocolTypeRouter` with `http` → `get_asgi_application()` and `websocket` → `AuthMiddlewareStack(URLRouter([]))`.
- `tasker/wsgi.py`: minimal, for tooling that expects it (no runtime use).

### Commit 3 — `apps/` scaffold (`feat(apps): create empty domain apps directory`)

- `apps/__init__.py` (empty).

### Commit 4 — Docker container definitions (`build(docker): web/db/redis/nginx services`)

- `Dockerfile`:
  ```dockerfile
  FROM python:3.13-slim
  ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
  RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libpq-dev curl \
      && rm -rf /var/lib/apt/lists/*
  WORKDIR /app
  COPY requirements.txt requirements-dev.txt /app/
  RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt
  RUN useradd --create-home --shell /bin/bash app && chown -R app:app /app
  USER app
  EXPOSE 8000
  CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "tasker.asgi:application"]
  ```
- `.dockerignore`: `.git/`, `__pycache__/`, `*.pyc`, `.pytest_cache/`, `.coverage`, `.env`, `staticfiles/`, `media/`, `docs/`, `node_modules/`.
- `compose.yml`:
  ```yaml
  services:
    web:
      build: .
      env_file: .env
      volumes:
        - ./:/app
        - static_data:/app/staticfiles
        - media_data:/app/media
      depends_on:
        db: { condition: service_healthy }
        redis: { condition: service_healthy }
      expose: ["8000"]
    db:
      image: postgres:16-alpine
      env_file: .env
      volumes: [postgres_data:/var/lib/postgresql/data]
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
        interval: 5s
        retries: 10
    redis:
      image: redis:7-alpine
      healthcheck:
        test: ["CMD", "redis-cli", "ping"]
        interval: 5s
        retries: 10
    nginx:
      image: nginx:1.27-alpine
      ports: ["80:80"]
      volumes:
        - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
        - static_data:/var/www/static:ro
        - media_data:/var/www/media:ro
      depends_on: [web]
  volumes:
    postgres_data:
    static_data:
    media_data:
  ```
- `nginx/default.conf`: `server { listen 80; location /static/ { alias /var/www/static/; } location /media/ { alias /var/www/media/; } location / { proxy_pass http://web:8000; proxy_set_header Host $host; proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; proxy_set_header X-Forwarded-Proto $scheme; proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade"; } }`.
- `.env.template`: every variable named in settings (`DJANGO_SECRET_KEY`, `DJANGO_SETTINGS_MODULE=tasker.settings.dev`, `DEBUG=1`, `ALLOWED_HOSTS=*`, `POSTGRES_DB=tasker`, `POSTGRES_USER=tasker`, `POSTGRES_PASSWORD=changeme`, `POSTGRES_HOST=db`, `POSTGRES_PORT=5432`, `REDIS_URL=redis://redis:6379/0`). Comments explain each.

### Commit 5 — Makefile + test harness (`build(make): developer shortcuts`, `test: pytest-django wiring + smoke`)

- `Makefile`:
  ```make
  .PHONY: up down build shell test migrate makemigrations logs psql redis-cli lint pip-compile

  up:            ; docker compose up -d
  down:          ; docker compose down
  build:         ; docker compose build
  shell:         ; docker compose exec web bash
  test:          ; docker compose exec -T web pytest $(if $(path),$(path),)
  migrate:       ; docker compose exec web python manage.py migrate
  makemigrations:; docker compose exec web python manage.py makemigrations
  logs:          ; docker compose logs -f $(svc)
  psql:          ; docker compose exec db psql -U $$POSTGRES_USER -d $$POSTGRES_DB
  redis-cli:     ; docker compose exec redis redis-cli
  lint:          ; docker compose exec -T web python -m pyflakes tasker apps
  pip-compile:   ; docker compose run --rm web pip-compile requirements.in && docker compose run --rm web pip-compile requirements-dev.in
  ```
- `pytest.ini`:
  ```ini
  [pytest]
  DJANGO_SETTINGS_MODULE = tasker.settings.dev
  python_files = test_*.py
  testpaths = tasker apps
  ```
- `conftest.py` — empty placeholder for future global fixtures.
- `tasker/tests/__init__.py` — empty.
- `tasker/tests/test_smoke.py`:
  ```python
  import pytest

  @pytest.mark.django_db
  def test_landing_view_returns_200(client):
      response = client.get("/")
      assert response.status_code == 200
      assert b"alive" in response.content
  ```

### Commit 6 — README + PR

- `README.md`: one-screen quickstart — clone, `cp .env.template .env`, `make build && make up`, `make migrate`, `make test`, point at `CLAUDE.md` and `docs/ideas/` for everything else.
- Open PR `feature/idea-001-bootstrap-django-docker-skeleton → main` via `gh pr create`.

## Verification

Run from the project root with `.env` populated from `.env.template`:

- `make build` — image builds without errors.
- `make up` — all four services come up; `docker compose ps` shows `web`, `db`, `redis`, `nginx` healthy (or running, for `nginx` which has no healthcheck).
- `docker compose ps --format json | jq '.[].Health'` — `db` and `redis` report `healthy` within ~30s.
- `make migrate` — applies the contrib migrations against Postgres, no errors.
- `make test` — pytest discovers `tasker/tests/test_smoke.py`, the smoke test passes.
- `curl -s -o /dev/null -w "%{http_code}\n" http://localhost/` — returns `200`.
- `curl -s http://localhost/` — body contains `alive`.
- `curl -s -o /dev/null -w "%{http_code}\n" http://localhost/admin/` — returns `302` (redirect to admin login).
- `make lint` — pyflakes reports nothing on `tasker/` and `apps/`.
- `make down` — clean teardown, `docker compose ps` empty.
- After teardown + `make up` again, the Postgres named volume persists (migrations don't have to re-run).

PR-level verification:

- All commits land on `feature/idea-001-bootstrap-django-docker-skeleton`.
- PR description references this plan path.
- Branch passes the self-sweep (pyflakes) before push per `RULE_self-sweep-before-push`.

---

**Status:** draft — awaiting user-approval (architect-review optional given the scope is conventional Django + Docker scaffolding with no novel architectural decisions; user can request the review pass if desired) before execution via `/work`.
