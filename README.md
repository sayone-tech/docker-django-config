# docker-django-config

+ Install Docker(26.0 or above) & Docker Compose(2.27.0 or above) in your local machine based on your local machine operating system. 

+ Create docker-compose.yml with the required services for the project using the given template.

+ Set appropriate conatainer names and service name. 

+ Use latest docket image verison for the services from the docker hub, eg: for postgres get the latest image tag from here https://hub.docker.com/_/postgres

+ Create environment variable files .env & env.db for web and db services of docker-compose respectively, based on the env.example file in the project's root directory

## Build the project using docker-compose

+ From root folder & run: 
```
docker compose up --watch
```
+ To build in detached mode: 

```
docker compose up --watch -d
```


### Make Migrations

To create database migrations, run the following command:

```
docker compose exec -u 0 web python manage.py makemigrations
```
### Apply Migrations

To apply database migrations, run the following command:

```
docker compose exec web python manage.py migrate
```

### Creating a Superuser

To create a superuser for the Django admin interface, run:

```
docker compose exec web python manage.py createsuperuser
```

### Creating an app

To create a new app , run:

```
docker compose exec -u 0 web python manage.py startapp appname
```

### Mount volume
Files inside the container will be lost once container is recreated, if you need to persist some file, like media files ,you need to mount that folder as volume in `docker-compose.yml`

```
web:
  ....
  volumes:
    - media:/code/project-name/same-path-as-MEDIA_URL

```
Run `docker compose exec -u 0 web chmod -R 777 media` if you are having permission issues.

### Restarting the Application

If you make changes to the `Dockerfile` or `docker-compose.yml` file, you may need to rebuild the Docker containers:

```
docker compose up --build --watch
```


+ Go to http://localhost:8000/ on your browser

+ ### To stop the containers: 

```
docker compose down
```

## Note

+ Update the python and other services docker image version to the latest when you are setting up the project for the first time
+ Refer [docker hub](https://hub.docker.com/) and get the lastest image with less vulnerabilities.  
+ Remove db volume to recreate/remove all the DB contents.