# tasker

A simple project/task manager on Django, deployable with Docker Compose. The project's primary purpose is to dogfood the [mind-vault](../mind-vault) sprint workflow — every change lands through atomic IDEAs (`docs/ideas/`), a plan (`docs/archive/<dir>/<date>-<slug>-plan.md`), and a single PR to `main`.

For agent conventions and the workflow contract, see [`CLAUDE.md`](CLAUDE.md).
For the rolling backlog and in-progress IDEAs, see [`docs/ideas/README.md`](docs/ideas/README.md).

## Stack

- Django 5.2.9 (LTS-track) + Django REST framework + Channels (Daphne single ASGI server)
- PostgreSQL 16 (Alpine)
- Redis 7 (Alpine) — cache + Channels layer
- nginx 1.27 (Alpine) — HTTP-facing proxy
- Python 3.13, pip-tools

All services run in Docker Compose. There is no host-level Python or pip — the Makefile wraps `docker compose exec`.

## Quickstart

```bash
# 1. Copy the env contract and customise.
cp .env.template .env
# On Linux, match the container app UID to your host UID to avoid
# bind-mount permission surprises:
echo "UID=$(id -u)" >> .env

# 2. Build the image and bring up the stack.
make build
make up

# 3. Apply migrations and run the smoke test.
make migrate
make test
```

Then open <http://localhost/> — you should see `tasker is alive`. The Django admin is at <http://localhost/admin/> (create a superuser via `make shell` → `python manage.py createsuperuser`).

## Common targets

| Command | What it does |
|---|---|
| `make up` / `make down` | Start / stop the stack |
| `make build` | Rebuild the `web` image after Dockerfile or requirements changes |
| `make shell` | Open a bash shell in the `web` container |
| `make test` | Run the full pytest suite |
| `make test ARGS=tasker/tests/test_smoke.py::test_landing_view_returns_200` | Run a single test by pytest nodeid |
| `make migrate` / `make makemigrations` | Django migration commands |
| `make logs svc=web` | Follow logs for one service (omit `svc=` for all) |
| `make psql` / `make redis-cli` | Interactive DB / Redis shells |
| `make lint` | Run `pyflakes` over `tasker/` and `apps/` |
| `make pip-compile` | Regenerate `requirements*.txt` after editing `requirements*.in` |

## Layout

```
.
├── CLAUDE.md                 # agent guidance, workflow conventions
├── Dockerfile, compose.yml   # container definitions (web/db/redis/nginx)
├── Makefile                  # developer shortcuts
├── nginx/default.conf        # proxy config
├── requirements.in, .txt     # pip-tools managed deps (runtime)
├── requirements-dev.in, .txt # pip-tools managed deps (dev)
├── manage.py                 # Django entrypoint
├── tasker/                   # Django project package
│   ├── settings/             # split: base, dev, prod
│   ├── asgi.py               # ProtocolTypeRouter (http + ws)
│   ├── urls.py, views.py     # admin + landing
│   └── tests/test_smoke.py   # end-to-end smoke test
├── apps/                     # domain apps live here (empty at bootstrap)
└── docs/
    ├── ideas/                # backlog (atomic IDEA-NNN-<slug>.md files)
    └── archive/              # in-progress + completed IDEAs (plans, devlogs)
```

## Contributing

Work flows through the mind-vault sprint workflow:

1. `/idea` — capture an atomic backlog item under `docs/ideas/`.
2. `/plan IDEA-NNN` — design the implementation, get architect review, flip to `ready`.
3. `/work` — execute the plan on a `feature/idea-NNN-<slug>` branch; open one PR per IDEA.
4. `/wrap` — flip frontmatter to `complete`, update the index + devlog, merge.
5. `/compound` — route the lesson learned (project-local doc, mind-vault skill/rule, or memory).

`main` is the human-merge gate; the agent never commits to it directly.
