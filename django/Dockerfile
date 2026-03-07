FROM python:3.12-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN mkdir /app
COPY pyproject.toml uv.lock /app/
RUN cd /app && uv sync --frozen --no-dev

ENTRYPOINT  ["uv", "run", "--no-sync", "python", "/app/manage.py", "runserver", "0.0.0.0:8000"]
