FROM nginx:1.25.4-alpine-slim

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./app.conf /etc/nginx/sites-available/

RUN mkdir -p /etc/nginx/sites-enabled/\
   && ln -s /etc/nginx/sites-available/app.conf /etc/nginx/sites-enabled/

CMD ["nginx", "-g", "daemon off;"]