FROM python:3.13-slim

# Match the container app user's UID to the host user so bind-mounted
# source files (./:/app) don't end up owned by an alien UID. Pass via
# compose: build.args.UID = "${UID:-1000}".
ARG UID=1000

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt requirements-dev.txt /app/
RUN pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt

RUN useradd --create-home --shell /bin/bash --uid ${UID} app \
    && chown -R app:app /app

USER app

EXPOSE 8000

CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "tasker.asgi:application"]
