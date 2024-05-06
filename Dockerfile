FROM python:3.9-slim

# Set work directory
WORKDIR /code

# Install dependencies and Add here if any system packages are needed
RUN apt-get update && apt-get install gcc libpq-dev -y
COPY . /code/

# Installing python packages
RUN pip install --upgrade pip && pip install -r requirements.txt && pip install  uwsgi

# Setup a non-root user
RUN adduser -u 1001 --disabled-password --gecos "" appuser && chown -R appuser:appuser /code

USER appuser 
