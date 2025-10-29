# docker-django-config

A Django web application with Docker configuration using **uv** for fast dependency management.

## Prerequisites

+ Install Docker (26.0 or above) & Docker Compose (2.27.0 or above)
+ Install Make (optional but recommended for easier commands)

## Quick Start with Makefile

The easiest way to run this project locally is using the provided Makefile:

### Initial Setup
```bash
make setup
```
This will:
- Create `.env` and `.env.db` files from examples
- Build Docker images
- Start containers
- Run initial migrations

### Common Commands
```bash
make help              # Show all available commands
make up                # Start development server with hot reload
make down              # Stop all containers
make logs              # View logs from all containers
make shell             # Open shell in web container
```

### Database Operations
```bash
make migrate           # Apply database migrations
make makemigrations    # Create new migrations (auto-copies to local)
make createsuperuser   # Create Django admin user
```

### Development Commands
```bash
make startapp name=myapp  # Create new Django app (auto-copies to local)
make test                 # Run tests
make coverage             # Run tests with coverage report
make django-shell         # Open Django shell
make manage cmd="COMMAND" # Run custom management command
```

### Custom Management Commands
Run any Django management command using the `manage` target:
```bash
# Flush database
make manage cmd="flush --no-input"

# Load fixtures
make manage cmd="loaddata fixtures/initial_data.json"

# Clear cache
make manage cmd="clear_cache"

# Run custom command
make manage cmd="my_custom_command --arg1 value1"

# See all available commands
make django-commands
```

## Manual Setup (without Makefile)

### Environment Variables

Create `.env` and `.env.db` files based on the example files:

#### Docker envs (.env)
```
APP_NAME : Application name
IMAGE_NAME : Docker image name
WEB_TAG : Docker image tag name for webapp
NGINX_TAG : Docker image tag name for nginx (For Dev and prod only)
```
#### Port envs to be used for local connection (.env)
```
DB_PORT : Db port for external connection
WEB_PORT : web app port for local external connection
REDIS_PORT : Redis port for external connection
```

### Build and Run

Build and start containers:
```bash
docker compose up --watch
```

To run in detached mode:
```bash
docker compose up --watch -d
```

### Make Migrations

⚠️ **Important**: When using Docker Compose watch mode with sync, migrations created inside the container won't be copied back to your local filesystem. Use this command to create migrations:

```bash
docker compose run --rm -u 0 -v "$PWD":/app -w /app web python manage.py makemigrations
```

Or simply use: `make makemigrations`

### Apply Migrations

```bash
docker compose exec web python manage.py migrate
```

### Creating a Superuser

```bash
docker compose exec web python manage.py createsuperuser
```

### Creating an app

⚠️ **Important**: Similar to migrations, use this command to ensure the app is created in your local filesystem:

```bash
docker compose run --rm -u 0 -v "$PWD":/app -w /app web python manage.py startapp appname
```

Or simply use: `make startapp name=appname`

### Mount volume
Files inside the container will be lost once container is recreated. If you need to persist files like media files, mount that folder as a volume in `docker-compose.yml`:

```yaml
web:
  ....
  volumes:
    - ./media:/code/project-name/same-path-as-MEDIA_URL
```

Fix permissions if needed:
```bash
make fix-permissions
# or manually:
docker compose exec -u 0 web chmod -R 777 media
```

### Restarting the Application

If you make changes to the `Dockerfile` or `docker-compose.yml` file, rebuild the containers:

```bash
make rebuild
# or manually:
docker compose up --build --watch
```

Access the application at: **http://localhost:8000/**

### Stop the containers

```bash
make down
# or manually:
docker compose down
```

## Dependency Management

This project uses **uv** for fast Python dependency management with a `pyproject.toml` file and `uv.lock` lockfile.

### How It Works

The Dockerfile uses `uv sync --frozen --no-dev` which:
1. Creates a virtual environment at `/code/.venv`
2. Installs dependencies from `uv.lock` (exact versions)
3. The virtual environment is added to PATH via `ENV PATH="/code/.venv/bin:$PATH"`
4. Python automatically finds packages in the virtual environment

### Adding Dependencies

1. Add the package to `pyproject.toml` under `[project.dependencies]`
2. Update the lockfile:
   ```bash
   docker run --rm -v "$PWD":/app -w /app python:3.12-slim sh -c "pip install uv && uv lock"
   # Or use: make lock
   ```
3. Rebuild the containers:
   ```bash
   make rebuild
   ```

### Development Dependencies

1. Add dev dependencies under `[project.optional-dependencies]` in `pyproject.toml`
2. Update the lockfile (same command as above)
3. For local development with dev dependencies:
   ```bash
   # In docker-compose.yml, change the RUN command to:
   # RUN uv sync --frozen  (without --no-dev)
   ```

### Lockfile Benefits

- **Reproducible builds**: `uv.lock` ensures exact same versions across all environments
- **Faster installs**: uv uses the lockfile for optimized dependency resolution
- **Security**: Pin exact versions to prevent supply chain attacks
- **Virtual environment**: Clean isolation with `/code/.venv` in PATH
- **Consistency**: Same dependencies in dev, staging, and production

## Additional Makefile Commands

### Database Management
```bash
make db-shell          # Open PostgreSQL shell
make backup-db         # Backup database to SQL file
make restore-db file=backup.sql  # Restore from backup
```

### Utilities
```bash
make clean             # Remove Python cache files
make check             # Run Django system checks
make status            # Show container status
make stats             # Show container resource usage
```

## Notes

+ This project uses **uv** for faster dependency installation compared to pip
+ Update Python and service Docker image versions when setting up for the first time
+ Refer to [Docker Hub](https://hub.docker.com/) for latest images with fewer vulnerabilities
+ Remove db volume to recreate/remove all DB contents: `docker volume rm <volume_name>`
+ The Makefile handles the sync issue where files created in containers aren't copied back to local filesystem
