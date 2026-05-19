# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`tasker` — a simple project/task manager built with Django, deployable via Docker Compose.

The primary purpose of this repo is to serve as a **testbed for the mind-vault workflows** (`/idea`, `/plan`, `/work`, `/wrap`, `/compound`, `/sprint-auto`, review-loops). Feature scope is intentionally modest so the workflow plumbing — not the domain — is what gets exercised.

## Status

Pre-scaffolding. No code yet. The first commits will lay down:

- Django 5.2.9 project skeleton (LTS track)
- Docker Compose stack: Django + Postgres + Redis (Celery later if/when needed)
- Daphne as the single ASGI server (HTTP + WebSocket), not Gunicorn+Daphne split
- nginx with `proxy_pass` in front, dev mirrors production
- Makefile with the usual shortcuts (`up`, `down`, `shell`, `test`, `migrate`, `makemigrations`)
- `docs/ideas/`, `docs/archive/` for mind-vault artefacts
- `.env.template` (never a real `.env` in git)

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

To be filled in as the Makefile lands. The expected shape:

```
make up         # docker compose up -d
make down       # docker compose down
make shell      # docker compose exec web bash
make test       # docker compose exec -T web pytest
make migrate    # docker compose exec web python manage.py migrate
```

Run a single test (planned): `docker compose exec -T web pytest path/to/test_file.py::TestClass::test_name`.

## What lives where (planned)

- `compose.yml` / `Dockerfile` — container definitions
- `Makefile` — developer shortcuts
- `tasker/` — Django project package (settings, urls, asgi)
- `apps/` — domain apps (projects, tasks, users)
- `docs/ideas/`, `docs/archive/` — mind-vault artefacts
- `.env.template` — env var contract; real `.env` is gitignored and off-limits to Claude

This file is a seed. Update it as real structure lands — keep it focused on non-obvious architecture, not file inventories.