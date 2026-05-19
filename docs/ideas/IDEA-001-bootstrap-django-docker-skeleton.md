---
id: 001
title: Bootstrap Django + Docker Compose Skeleton
status: idea
priority: high
supersedes: []
superseded_by: null
depends_on: []
related: []
created: 2026-05-19
completed: null
auto_safe: false
auto_safe_reason: "Foundation IDEA — establishes the Django settings layout, Docker network topology, Daphne+nginx wiring, Makefile shape, and Postgres/Redis service contracts. Every later IDEA inherits these decisions, so a human must eyeball the scaffold before it solidifies."
sensitive_paths_cleared: false
sensitive_paths_cleared_reason: "Touches infra by definition — Dockerfile, compose.yml, nginx config, .env.template (the secrets contract). These are exactly the zones the gate exists to flag."
---

# IDEA-001: Bootstrap Django + Docker Compose Skeleton

**Status**: 💡 Idea
**Priority**: High

**Problem** (or opportunity): The `tasker` repo is empty — zero commits, no source files. Before any feature IDEA can run, the project needs a working Django + Docker Compose stack that other IDEAs build on. This is the foundation commit.

**Proposal** (or idea): Land a single feature branch (`feature/idea-001-bootstrap`) that delivers:

- **Django 5.2.9 (LTS-track) project package** at `tasker/` with split settings (`base.py`, `dev.py`, `prod.py`), `asgi.py` configured for Channels, `urls.py` skeleton.
- **`apps/` directory** as the home for future domain apps (`projects`, `tasks`, `users`); empty at bootstrap, only an `apps/__init__.py`.
- **Dockerfile** — single-stage Python image with pyenv-installed CPython, project deps via `pip-tools` / `requirements.txt` (no Poetry unless reason emerges later).
- **`compose.yml`** — services: `web` (Daphne, ASGI, single server for HTTP+WS), `db` (Postgres 16), `redis` (cache + Channels layer), `nginx` (proxy in front of `web`, dev mirrors prod topology).
- **`nginx/`** — minimal `default.conf` with `proxy_pass` to `web:8000`, websocket upgrade headers, static + media volume mounts.
- **Makefile** — targets: `up`, `down`, `shell`, `test`, `migrate`, `makemigrations`, `logs`, `psql`, `redis-cli`. Every target wraps `docker compose exec` — no host-level Python or pip.
- **`.env.template`** — declared contract for every env var (`DJANGO_SECRET_KEY`, `POSTGRES_*`, `REDIS_URL`, `ALLOWED_HOSTS`, `DEBUG`). Real `.env` gitignored.
- **`.gitignore`** — Python + Django + Docker + editor + OS coverage: `__pycache__/`, `*.pyc`, `*.pyo`, `.pytest_cache/`, `.coverage`, `htmlcov/`, `staticfiles/`, `media/`, `db.sqlite3`, `*.log`, `.env`, `.env.*` (except `.env.template`), `.venv/`, `venv/`, `.python-version`, `.idea/`, `.vscode/`, `*.swp`, `.DS_Store`, `node_modules/` (for when frontend tooling lands). Keep the file curated — don't paste the GitHub mega-template; only what this stack actually produces.
- **`pytest.ini` + `conftest.py`** — pytest-django wired, sample passing test in `apps/__init__.py` adjacent location to prove the harness runs.
- **`docs/ideas/`, `docs/archive/`** — already present at this IDEA's landing (created by `/idea`); confirm the index README.

**Why now**:
- Without this, no other IDEA can ship — every feature needs a runnable stack.
- Establishes the conventions (Makefile-first, ASGI-single-server, split settings, `apps/` layout) before any feature locks in alternatives by accident.
- The project's stated purpose is mind-vault workflow dogfooding — bootstrapping through `/idea → /plan → /work → /wrap` proves the workflow on its own scaffolding.

**Non-goals**:
- No domain models, no `projects` or `tasks` app implementation — those are later IDEAs.
- No CI/CD pipeline (GitHub Actions) — separate IDEA once there's something worth testing in CI.
- No deployment target (staging VPS, SSL, Let's Encrypt) — separate IDEA once a host is chosen.
- No Celery — Redis is provisioned but Celery worker/beat services are deferred until an IDEA actually needs background jobs.
- No authentication / user model customisation — separate IDEA; the bootstrap uses `django.contrib.auth.User` as-is.
- No frontend tooling (Tailwind/Sass/Bulma build) — separate IDEA when the first template lands.

**Related**: First IDEA of the project; every subsequent IDEA depends on this one implicitly.
