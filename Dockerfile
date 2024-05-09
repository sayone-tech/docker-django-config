# ---- Base Python ----
FROM python:3.12-slim AS base

# Create app directory
WORKDIR /code

# ---- Copy Files/Build ----
FROM base AS builder

    
# Install tools required for project
# Run `docker build --no-cache .` to update dependencies
RUN apt-get update && apt-get install -y --no-install-recommends build-essential gcc libpq-dev && \
rm -rf /var/lib/apt/lists/*

# Install project dependencies
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels -r requirements.txt 

# Install uwsgi
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels uWSGI==2.0.25.1


# ---- Copy Files/Build ----
FROM base AS release

# Copy app user
COPY --from=builder /etc/passwd /etc/passwd

# Copy project dependencies
COPY --from=builder /wheels /wheels
COPY --from=builder /code .

RUN adduser -u 1001 --disabled-password --gecos "" appuser && chown -R appuser:appuser /code

# Install project dependencies
RUN pip install --no-cache /wheels/* 

# Change to non-root user
USER appuser

# Copy the Django application
COPY --chown=appuser:appuser . .
    