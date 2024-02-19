# docker-django-config

+ Install Docker & Docker Compose in your local machine based on your local machine operating system. 

+ Create docker-compose.yml with the required services for the project using the given template. 

+ Use latest docket image verison for the services from the docker hub, eg: for postgres get the latest image tag from here https://hub.docker.com/_/postgres

+ Create environment variable files .env & env.db for web and db services of docker-compose respectively, based on the env.example file in the project's root directory

## Build the project using docker-compose

+ From root folder & run: docker compose up --build, to run in detached mode: docker compose up -d --build

+ Create migrate files : docker compose exec web python manage.py makemigrations

+ Migrate the tables to database: docker compose exec web python manage.py migrate

+ Create Superuser: docker compose exec web python manage.py createsuperuser

+ Go to http://localhost:8000/ on your browser

+ To stop the containers: docker compose down