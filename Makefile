.PHONY: help build up down restart logs shell migrate makemigrations createsuperuser test coverage clean prune manage lock

# Default target
help:
	@echo "Available commands:"
	@echo "  make build              - Build Docker images"
	@echo "  make up                 - Start containers with watch mode"
	@echo "  make up-detached        - Start containers in detached mode with watch"
	@echo "  make down               - Stop and remove containers"
	@echo "  make restart            - Restart all containers"
	@echo "  make logs               - View logs from all containers"
	@echo "  make logs-web           - View logs from web container"
	@echo "  make logs-db            - View logs from database container"
	@echo "  make shell              - Open shell in web container"
	@echo "  make shell-root         - Open shell in web container as root"
	@echo "  make migrate            - Run database migrations"
	@echo "  make makemigrations     - Create new migrations (copies to local)"
	@echo "  make createsuperuser    - Create Django superuser"
	@echo "  make collectstatic      - Collect static files"
	@echo "  make startapp name=APP  - Create new Django app (copies to local)"
	@echo "  make test               - Run tests"
	@echo "  make coverage           - Run tests with coverage report"
	@echo "  make clean              - Remove Python cache files"
	@echo "  make prune              - Remove all unused Docker resources"
	@echo "  make lock               - Update uv.lock after changing pyproject.toml"
	@echo "  make rebuild            - Rebuild and restart containers"
	@echo "  make manage cmd='COMMAND' - Run custom Django management command"

# Build Docker images
build:
	docker compose build

# Start containers with watch mode
up:
	docker compose up --watch

# Start containers in detached mode with watch
up-detached:
	docker compose up --watch -d

# Stop and remove containers
down:
	docker compose down

# Restart all containers
restart:
	docker compose restart

# View logs from all containers
logs:
	docker compose logs -f

# View logs from web container
logs-web:
	docker compose logs -f web

# View logs from database container
logs-db:
	docker compose logs -f db

# Open shell in web container
shell:
	docker compose exec web /bin/bash

# Open shell in web container as root
shell-root:
	docker compose exec -u 0 web /bin/bash

# Run database migrations
migrate:
	docker compose exec web python manage.py migrate

# Create new migrations and copy them to local filesystem
# This handles the sync issue where migrations created in container aren't copied back
makemigrations:
	@echo "Creating migrations in container..."
	docker compose run --rm -u 0 -v "$$(pwd)":/app -w /app web python manage.py makemigrations
	@echo "Migrations created and copied to local filesystem"

# Create Django superuser
createsuperuser:
	docker compose exec web python manage.py createsuperuser

# Collect static files
collectstatic:
	docker compose exec -u 0 web python manage.py collectstatic --no-input

# Create new Django app and copy to local filesystem
# Usage: make startapp name=myapp
startapp:
	@if [ -z "$(name)" ]; then \
		echo "Error: Please provide app name. Usage: make startapp name=myapp"; \
		exit 1; \
	fi
	@echo "Creating Django app: $(name)"
	docker compose run --rm -u 0 -v "$$(pwd)":/app -w /app web python manage.py startapp $(name)
	@echo "App '$(name)' created and copied to local filesystem"

# Run tests
test:
	docker compose exec web python manage.py test

# Run tests with coverage
coverage:
	docker compose exec web coverage run --source='.' manage.py test
	docker compose exec web coverage report
	docker compose exec web coverage html
	@echo "Coverage report generated in htmlcov/"

# Remove Python cache files
clean:
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	find . -type f -name "*.pyo" -delete 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "htmlcov" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".coverage" -delete 2>/dev/null || true

# Remove all unused Docker resources
prune:
	docker system prune -af --volumes

# Rebuild and restart containers
rebuild:
	docker compose up --build --watch

# Update uv lockfile after changing pyproject.toml
lock:
	@echo "Updating uv.lock..."
	docker run --rm -v "$(PWD)":/app -w /app python:3.12-slim sh -c "pip install -q uv && uv lock"
	@echo "✅ uv.lock updated successfully"

# Install/Update dependencies (when pyproject.toml changes)
install: lock
	docker compose build --no-cache
	docker compose up -d
	@echo "Dependencies installed. Containers restarted."

# Database commands
db-shell:
	docker compose exec db psql -U $${POSTGRES_USER:-postgres} -d $${POSTGRES_DB:-postgres}

# Redis CLI
redis-cli:
	docker compose exec redis redis-cli

# Check container status
status:
	docker compose ps

# View container resource usage
stats:
	docker stats

# Backup database
backup-db:
	@echo "Creating database backup..."
	docker compose exec -T db pg_dump -U $${POSTGRES_USER:-postgres} $${POSTGRES_DB:-postgres} > backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "Backup created successfully"

# Restore database from backup
# Usage: make restore-db file=backup_20240101_120000.sql
restore-db:
	@if [ -z "$(file)" ]; then \
		echo "Error: Please provide backup file. Usage: make restore-db file=backup.sql"; \
		exit 1; \
	fi
	@echo "Restoring database from $(file)..."
	docker compose exec -T db psql -U $${POSTGRES_USER:-postgres} $${POSTGRES_DB:-postgres} < $(file)
	@echo "Database restored successfully"

# Fix permissions for media/static files
fix-permissions:
	docker compose exec -u 0 web chmod -R 777 /code/media 2>/dev/null || true
	docker compose exec -u 0 web chmod -R 777 /code/static 2>/dev/null || true
	@echo "Permissions fixed"

# Show Django version
django-version:
	docker compose exec web python -c "import django; print(django.get_version())"

# Show Python version
python-version:
	docker compose exec web python --version

# Run Django check
check:
	docker compose exec web python manage.py check

# Run Django shell
django-shell:
	docker compose exec web python manage.py shell

# Show all Django management commands
django-commands:
	docker compose exec web python manage.py help

# Run custom Django management command
# Usage: make manage cmd="command_name arg1 arg2"
# Example: make manage cmd="flush --no-input"
# Example: make manage cmd="loaddata fixtures/initial_data.json"
manage:
	@if [ -z "$(cmd)" ]; then \
		echo "Error: Please provide a command. Usage: make manage cmd='command_name args'"; \
		echo "Example: make manage cmd='flush --no-input'"; \
		echo "Example: make manage cmd='loaddata fixtures/data.json'"; \
		echo "Run 'make django-commands' to see all available commands"; \
		exit 1; \
	fi
	docker compose exec web python manage.py $(cmd)

# Initial setup for new developers
setup:
	@echo "Setting up development environment..."
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
		echo "Please update .env with your configuration"; \
	fi
	@if [ ! -f .env.db ]; then \
		echo "Creating .env.db file from .env.db.example..."; \
		cp .env.db.example .env.db; \
		echo "Please update .env.db with your configuration"; \
	fi
	@echo "Building Docker images..."
	docker compose build
	@echo "Starting containers..."
	docker compose up -d
	@echo "Waiting for database to be ready..."
	sleep 5
	@echo "Running migrations..."
	docker compose exec web python manage.py migrate
	@echo ""
	@echo "Setup complete! Run 'make createsuperuser' to create an admin user."
	@echo "Then run 'make up' to start development with watch mode."

