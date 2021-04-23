FROM debian:buster

# Set build and runtime arguments (with default values, if nothing is passed)
ARG DEBIAN_FRONTEND=noninteractive
ARG set_timezone=false
ARG tz_data="Asia/Manila"
ARG virtual_host=localhost

ENV SET_TIMEZONE=$set_timezone
ENV TIMEZONE=$tz_data
ENV VIRTUAL_HOST=$virtual_host

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
        tzdata cron unzip apache2 libapache2-mod-xsendfile libapache2-mod-php7.4 php7.4 php7.4-cli php7.4-fpm \
        php7.4-imagick php7.4-curl php7.4-bz2 php7.4-gd php7.4-imap php7.4-intl php7.4-mbstring \
        php7.4-mysql php7.4-zip php7.4-apcu-bc php7.4-apcu php7.4-xml php7.4-ldap php7.4-sqlite3 \
    && a2enconf php7.4-fpm \
    && a2enmod rewrite php7.4 \
    && a2enmod proxy_fcgi setenvif \
    && echo "ServerName $VIRTUAL_HOST\n<Directory /var/www/html/>\nOptions Indexes FollowSymLinks\nAllowOverride All\nRequire all granted\n</Directory>\n" >> /etc/apache2/apache2.conf \
    && service apache2 restart

# Set timezone
RUN if [ "$SET_TIMEZONE" = "true" ]; \
    then echo ${TIMEZONE} > /etc/timezone && \
        ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
        dpkg-reconfigure -f noninteractive tzdata && \
        echo "Container timezone set to: $TIMEZONE"; \
    else echo "Container timezone not modified"; \
    fi

# Add custom PHP configuration
# COPY php.ini /etc/php/7.4/php.ini

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Changed ownership on working directory
RUN chown -R www-data:www-data /var/www/html

# Expose default ports
EXPOSE 80 443

# Run Apache in the foregound automatically
CMD apachectl -D FOREGROUND