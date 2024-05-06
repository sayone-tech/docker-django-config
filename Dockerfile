FROM python:3.9-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /code

# Install dependencies and Add here if any system packages are needed
RUN apt-get update && \
apt-get install gcc libpq-dev -y && \
rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt /code/
# Installing python packages
RUN pip install --upgrade pip && pip install -r requirements.txt && pip install  uwsgi

COPY . /code/

# Setup a non-root user
RUN adduser -u 1001 --disabled-password --gecos "" appuser && chown -R appuser:appuser /code

USER appuser 
