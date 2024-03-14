FROM python:3.9-slim

# Set work directory
WORKDIR /code

# Install dependencies
RUN apt-get update
RUN pip install --upgrade pip

# Add here if any system packages are needed
RUN apt-get install gcc libpq-dev -y 
COPY ./requirements.txt /code/
RUN pip install -r requirements.txt
RUN pip install  uwsgi
RUN adduser -u 1001 --disabled-password --gecos "" appuser
COPY . /code/
RUN chown -R appuser:appuser /code
USER appuser
