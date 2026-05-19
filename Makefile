.PHONY: up down build shell test migrate makemigrations logs psql redis-cli lint pip-compile

# Pass pytest nodeids (including `::`) without make interpreting them:
#   make test ARGS=tasker/tests/test_smoke.py::test_landing_view_returns_200
# Bare `make test` runs the full suite.
ARGS ?=

# Optional service filter for `make logs svc=web`. Default tails all.
svc ?=

up:
	docker compose up -d

down:
	docker compose down

build:
	docker compose build

shell:
	docker compose exec web bash

test:
	docker compose exec -T web pytest $(ARGS)

migrate:
	docker compose exec web python manage.py migrate

makemigrations:
	docker compose exec web python manage.py makemigrations

logs:
	docker compose logs -f $(svc)

psql:
	docker compose exec db sh -c 'psql -U $$POSTGRES_USER -d $$POSTGRES_DB'

redis-cli:
	docker compose exec redis redis-cli

lint:
	docker compose exec -T web python -m pyflakes tasker apps

# Order matters: runtime first (generates requirements.txt), then dev
# (which `-c`'s requirements.txt as a constraint).
pip-compile:
	docker compose run --rm web pip-compile --strip-extras --output-file=requirements.txt requirements.in
	docker compose run --rm web pip-compile --strip-extras --output-file=requirements-dev.txt requirements-dev.in
