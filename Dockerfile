FROM debian:stretch

ENV DEBIAN_FRONTEND noninteractive

# Sources.
RUN \
  echo "deb http://ftp.de.debian.org/debian/ stretch main non-free contrib" > /etc/apt/sources.list && \
  echo "deb-src http://ftp.de.debian.org/debian/ stretch main non-free contrib" >> /etc/apt/sources.list && \
  echo "deb http://security.debian.org/ stretch/updates main contrib non-free" >> /etc/apt/sources.list && \
  echo "deb-src http://security.debian.org/ stretch/updates main contrib non-free" >> /etc/apt/sources.list && \
  apt-get -qq update && apt-get -qqy upgrade

# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
RUN sed -i "s/^exit 101$/exit 0/" /usr/sbin/policy-rc.d

# Tools.
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg \
    mariadb-client \
    nano && \
    rm -rf /var/lib/apt/lists/*

# Apache.
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    apache2 && \
    rm -rf /var/lib/apt/lists/*

# Configure Apache.
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

ADD etc/apache2/ssl/ /etc/apache2/ssl/
ADD etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf

RUN a2enmod proxy_fcgi rewrite ssl

# PHP.
RUN curl https://packages.sury.org/php/apt.gpg | apt-key add -
RUN echo 'deb https://packages.sury.org/php/ stretch main' > /etc/apt/sources.list.d/deb.sury.org.list

# Install PHP 7.0
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    php7.0 \
    php7.0-cli \
    php7.0-curl \
    php7.0-fpm \
    php7.0-gd \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-mysqlnd \
    php7.0-soap \
    php7.0-zip \
    php-xdebug \
    php7.0-xml && \
    rm -rf /var/lib/apt/lists/*

# Install PHP 5.6
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    php5.6 \
    php5.6-cli \
    php5.6-curl \
    php5.6-fpm \
    php5.6-gd \
    php5.6-mbstring \
    php5.6-mcrypt \
    php5.6-mysqlnd \
    php5.6-soap \
    php5.6-zip \
    php5.6-xml && \
    rm -rf /var/lib/apt/lists/*

# Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# (Docker-specific) install supervisor so we can run everything together
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    supervisor && \
    rm -rf /var/lib/apt/lists/*
COPY supervisor.conf /etc/supervisor/supervisord.conf
RUN mkdir -p /run/php

# Cleanup.
RUN \
    apt-get -q autoclean && \
    rm -rf /var/lib/apt/lists/*

# Change www-data user to match the host system UID and GID and chown www directory
RUN usermod --non-unique --uid 1000 www-data \
  && groupmod --non-unique --gid 1000 www-data \
  && chown -R www-data:www-data /var/www

EXPOSE 80 443
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]