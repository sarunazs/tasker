---
id: 002
title: Zero-touch bootstrap — migrate, collectstatic, dev superuser on first `make up`
status: idea
priority: high
supersedes: []
superseded_by: null
depends_on: [001]
related: [001]
created: 2026-05-20
completed: null
auto_safe: false
auto_safe_reason: "Touches container start path + image; reversibility is fine but the entrypoint script + Makefile wiring need a human eyeball on the exact migrate/collectstatic ordering, and the dev-superuser env contract is a UX call worth confirming before sprint-auto runs it unattended."
sensitive_paths_cleared: false
sensitive_paths_cleared_reason: "Introduces an entrypoint script that runs schema migrations on every `web` start and provisions an admin user from env in dev — both are infra + auth-adjacent surfaces and warrant explicit human review (the prod settings split must guarantee the dev superuser path is unreachable in production)."
---

# IDEA-002: Zero-touch bootstrap — migrate, collectstatic, dev superuser on first `make up`

**Status**: 💡 Idea
**Priority**: High

**Problem** (or opportunity): After IDEA-001 landed the stack, a fresh `make up` against an empty `postgres_data` volume left three latent failures that surfaced as confusing 500s the moment anyone opened `/admin/`:

1. **Migrations weren't applied** — `relation "django_session" does not exist` on first login.
2. **Statics weren't collected** — admin CSS 404s and unstyled pages until someone remembered `collectstatic`.
3. **No superuser** — even after the two fixes, `/admin/login/` rejects every credential because the user table is empty.

Each of these is one command away from working, but the bootstrap quickstart in `README.md` only lists `make migrate` + `make test`. Statics and superuser creation are unwritten tribal knowledge. The cost: every fresh checkout (CI ephemeral runner, new contributor, post-`docker compose down -v` reset, agent worktree spin-up under `sprint-auto`) eats the same three-strike debugging round.

**Proposal** (or idea): Make first-boot of the `web` container land in a *runnable* state with zero manual follow-up.

- Introduce a `docker-entrypoint.sh` (or `manage.py`-driven equivalent) that runs on every `web` container start:
  1. `python manage.py migrate --noinput`
  2. `python manage.py collectstatic --noinput`
  3. **In dev only** (`DJANGO_SETTINGS_MODULE=tasker.settings.dev`): conditionally provision a superuser from `DJANGO_SUPERUSER_USERNAME` / `DJANGO_SUPERUSER_EMAIL` / `DJANGO_SUPERUSER_PASSWORD` env vars if no user with that username already exists. Idempotent.
  4. `exec daphne …` (current CMD).
- Wire the three superuser env vars into `.env.template` with safe placeholder values + a comment explaining they are dev-only.
- Guard the superuser branch on `settings.DEBUG` (or an explicit `DEV_AUTO_CREATE_SUPERUSER` flag) so a misconfigured prod deploy can never accidentally provision an admin account from env.
- Update `README.md` quickstart: drop the `make migrate` step + the "create a superuser via `make shell`" footnote; replace with a single line noting that `make up` brings the stack to a logged-in-able state and points at `.env.template` for the dev creds.
- Keep `make migrate` / `make makemigrations` targets — they remain the right tool for *intentional* schema changes during development.

**Why now**:
- Every IDEA from here forward inherits this bootstrap path. The cost of leaving it broken compounds with each fresh worktree (`sprint-auto` spins up N parallel worktrees per batch; each one is currently three broken commands away from `/admin/` working).
- The fix is small (one entrypoint script + one env-template stanza + a README trim) but the unblocking effect is global.
- It removes a class of "is the stack broken or did I forget a step" diagnostic noise from every future review-loop.

**Non-goals**:
- Not introducing a generic init-container or `depends_on: condition: service_completed_successfully` choreography — the entrypoint inside `web` is enough.
- Not solving prod-time migration policy (prod uses a separate deploy script per the deployment skill; this IDEA scopes to dev).
- Not auto-creating fixtures or seed data beyond the single superuser — domain fixtures belong in per-IDEA work.
- Not changing the existing `make migrate` / `make test` targets' semantics.

**Related**: Builds directly on [IDEA-001](../archive/2026-05-idea-001-bootstrap-django-docker-skeleton/IDEA-001-bootstrap-django-docker-skeleton.md) (bootstrap stack) — closes the gap between "containers are up" and "the app is usable end-to-end".
