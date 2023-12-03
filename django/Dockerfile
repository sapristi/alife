# FROM python:3.11-slim
FROM archlinux:base

# RUN pacman -Sy
RUN pacman -Sy python python-pip --noconfirm

RUN mkdir /app
COPY pyproject.toml /app/
RUN cd /app && pip install . --no-cache-dir --break-system-packages

ENTRYPOINT  ["python",  "/app/manage.py", "runserver", "0.0.0.0:8000"]

