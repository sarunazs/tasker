# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`tasker` — a simple project/task manager built with Django, deployable via Docker Compose.

The primary purpose of this repo is to serve as a **testbed for the mind-vault workflows** (`/idea`, `/plan`, `/work`, `/wrap`, `/compound`, `/sprint-auto`, review-loops). Feature scope is intentionally modest so the workflow plumbing — not the domain — is what gets exercised.

## Status

Bootstrapped — IDEA-001 shipped 2026-05-19 (PR #1). The repo has a runnable Django + Docker Compose stack, mind-vault workflow surface, and pytest smoke harness. Subsequent IDEAs build domain features (projects, tasks, users, etc.) on top of this foundation. See [`docs/archive/2026-05-DEVELOPMENT_LOG.md`](docs/archive/2026-05-DEVELOPMENT_LOG.md) for the chronological log and [`docs/ideas/README.md`](docs/ideas/README.md) for the rolling backlog + completed index.

## Stack (intended)

- Python via pyenv (no global pip)
- Django 5.2.9 + DRF
- Django Channels + Daphne
- PostgreSQL
- Redis (cache + Channels layer; Celery broker if/when added)
- Docker Compose for everything — no bare `docker` commands, no host-level installs
- Makefile-first; raw commands only when no target exists

## Mind-vault conventions

- Atomic IDEAs live in `docs/ideas/IDEA-NNN-<slug>.md`; index at `docs/ideas/README.md`.
- Per-IDEA archive at `docs/archive/YYYY-MM-idea-NNN-<slug>/` (plan, devlog, amendments).
- Sprint workflow: `/idea` → `/plan` → `/work` → review-loop → `/wrap` → `/compound`.
- Feature work on worktree-isolated branches; PRs target `main`; human merges (see `RULE_git-safety`).
- Self-sweep (pyflakes on touched `.py`) before every push (see `RULE_self-sweep-before-push`).

## Commands

Every target wraps `docker compose exec` — no host-level Python.

```
make up                    # bring stack up (-d)
make down                  # tear down (volumes persist)
make build                 # rebuild web image after Dockerfile/requirements changes
make shell                 # bash in the web container
make test                  # full pytest suite
make test ARGS=path::node  # single test by pytest nodeid (use ARGS=, not path=)
make migrate               # apply migrations
make makemigrations        # generate migrations
make logs svc=web          # follow logs for one service (svc= optional)
make psql                  # interactive Postgres shell
make redis-cli             # interactive Redis shell
make lint                  # pyflakes over tasker + apps (excludes settings/dev.py + prod.py)
make pip-compile           # regenerate requirements*.txt (runtime first, then dev)
```

Stack runs on `HTTP_PORT` from `.env` (default 80; bootstrap verification used 8088 because :80 was taken). Bootstrap quickstart in [`README.md`](README.md).

## What lives where

- `compose.yml` / `Dockerfile` / `nginx/default.conf` — container definitions; nginx fronts Daphne on `web:8000`.
- `Makefile` — developer shortcuts (see Commands above).
- `tasker/` — Django project package: `settings/{base,dev,prod}.py` (split; `__init__.py` empty by design so `DJANGO_SETTINGS_MODULE` is always explicit), `urls.py`, `views.py`, `asgi.py` (`ProtocolTypeRouter` with empty WS leg pre-wired).
- `apps/` — domain apps live here (currently empty; `__init__.py` only). The settings `INSTALLED_APPS` adds `apps.<name>`-style entries when domain apps land.
- `requirements*.in` / `requirements*.txt` — pip-tools managed; `.in` is the source of truth.
- `docs/ideas/` — backlog (per `RULE_ideas-location-status`); `docs/archive/YYYY-MM-idea-NNN-<slug>/` — in-progress + completed IDEAs with their plans + per-month `YYYY-MM-DEVELOPMENT_LOG.md`.
- `.env.template` — env contract; real `.env` is gitignored and off-limits to Claude.
- `pytest.ini` + `conftest.py` — pytest-django wiring; `testpaths = tasker apps`.

Keep this file focused on non-obvious architecture, not file inventories — extend it when a future IDEA introduces a non-obvious convention (e.g. multi-tenancy boundary, custom user model, channel routing topology).