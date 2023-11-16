FROM python:3.11-slim

RUN mkdir /app
COPY pyproject.toml /app/
RUN cd /app && pip install .

ENTRYPOINT  ["python",  "/app/manage.py", "runserver", "0.0.0.0:8000"]

