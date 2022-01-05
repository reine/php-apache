# Build: BASE WITH PHP AND APACHE
FROM debian:buster AS base

# Set on-build arguments
ARG DEBIAN_FRONTEND=noninteractive
ARG TIME_ZONE=Asia/Manila
ARG VIRTUAL_HOST=localhost

# Set up working directory
WORKDIR /var/www/html

# Add SURY PHP PPA repository
RUN apt update \
    && apt -y install lsb-release apt-transport-https ca-certificates wget \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list

# Install and setup Apache with PHP
RUN apt-get update \
    && apt-get install -y \
        tzdata cron git unzip apache2 libapache2-mod-xsendfile libapache2-mod-php7.4 php7.4 php7.4-cli php7.4-fpm \
        php7.4-imagick php7.4-curl php7.4-bz2 php7.4-gd php7.4-imap php7.4-intl php7.4-mbstring \
        php7.4-mysql php7.4-zip php7.4-apcu-bc php7.4-apcu php7.4-xml php7.4-ldap php7.4-sqlite3 \
    && a2enconf php7.4-fpm \
    && a2enmod rewrite php7.4 \
    && a2enmod proxy_fcgi setenvif \
    && echo "ServerName $VIRTUAL_HOST\n<Directory /var/www/html/>\nOptions Indexes FollowSymLinks\nAllowOverride All\nRequire all granted\n</Directory>\n" >> /etc/apache2/apache2.conf \
        && echo "Container virtual host set to: $VIRTUAL_HOST" \
    && service apache2 restart \
    && echo $TIME_ZONE > /etc/timezone && \
        ln -sf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && \
        dpkg-reconfigure -f noninteractive tzdata && \
        echo "Container time zone set to: $TIME_ZONE" \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*
    
# Build: FINAL WITH COMPOSER
FROM base AS final

# Install Composer
COPY --from=composer:2.2.2 /usr/bin/composer /usr/bin/composer

# Changed ownership on working directory
RUN chown -R www-data:www-data /var/www/html

# Expose default ports
EXPOSE 80 443

# Run Apache in the foregound automatically
CMD apachectl -D FOREGROUND