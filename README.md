# php-apache
A docker image of PHP 7.4 with Apache. Composer 2 included.

Use command via console:

```bash
docker build -t php_apache . --build-arg VIRTUAL_HOST="site.dev.local" TIME_ZONE="America/Chicago"
```

Or, via docker-compose.yml:

```bash
version: "3.6"
services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        TIME_ZONE: "America/Chicago"
        VIRTUAL_HOST: "site.dev.local"
    ports:
      - "80:80"
      - "443:443"
```

If no arguments were sent during build, the default values for virtual host and timezone are **localhost** and **Asia/Manila** respectively.