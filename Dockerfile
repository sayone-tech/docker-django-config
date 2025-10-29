# ---- Base Python ----
FROM python:3.12-slim AS base

# Create app directory
WORKDIR /code

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# ---- Copy Files/Build ----
FROM base AS builder

# Install tools required for project
# Run `docker build --no-cache .` to update dependencies
RUN apt-get update && apt-get install -y --no-install-recommends build-essential gcc libpq-dev && \
rm -rf /var/lib/apt/lists/*

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies using uv sync
# --frozen: Don't update the lockfile, use exact versions from uv.lock
# --no-dev: Don't install development dependencies
RUN uv sync --frozen --no-dev

# Install uWSGI separately (deployment tool, not app dependency)
RUN uv pip install --system uwsgi==2.0.30

# ---- Copy Files/Build ----
FROM base AS release

# Copy virtual environment from builder
COPY --from=builder /code/.venv /code/.venv

# Copy uWSGI from builder (installed to system Python)
COPY --from=builder /usr/local/lib/python3.12/site-packages/uwsgi* /usr/local/lib/python3.12/site-packages/
COPY --from=builder /usr/local/bin/uwsgi /usr/local/bin/uwsgi

# Add virtual environment to PATH
ENV PATH="/code/.venv/bin:$PATH"
ENV VIRTUAL_ENV="/code/.venv"

RUN adduser -u 1001 --disabled-password --gecos "" appuser && chown -R appuser:appuser /code

# Copy the Django application
COPY --chown=appuser:appuser . .

# Change to non-root user
USER appuser
    