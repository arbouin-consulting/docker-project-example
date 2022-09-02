ARG ALPINE_VERSION=3.16
ARG NGINX_VERSION=1.22.0
ARG PHP_VERSION=8.1.9
ARG COMPOSER_VERSION=2.2.9
ARG BOOKSTACK_VERSION=21.4.5
ARG BOOKSTACK_HOME="/srv/bookstack"

#------------------------------------------------------------------------------
# Install vendors
#------------------------------------------------------------------------------
FROM composer:${COMPOSER_VERSION} AS composer

ARG BOOKSTACK_VERSION
ARG BOOKSTACK_HOME

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    BOOKSTACK=BookStack

ENV PATH="${PATH}:/root/.composer/vendor/bin"

RUN set -eux \
    && wget https://github.com/BookStackApp/BookStack/archive/v${BOOKSTACK_VERSION}.tar.gz -O ${BOOKSTACK}.tar.gz \
    && tar -xf ${BOOKSTACK}.tar.gz \
    && mv BookStack-${BOOKSTACK_VERSION} ${BOOKSTACK_HOME}

WORKDIR $BOOKSTACK_HOME

RUN composer install --prefer-dist --no-dev --no-progress --no-suggest --ignore-platform-reqs \
    && composer clear-cache
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Install app
#------------------------------------------------------------------------------
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS php

ARG BUILD_DATE
ARG VCS_REF
ARG BOOKSTACK_VERSION
ARG BOOKSTACK_HOME

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.license="MIT" \
      org.label-schema.name="bookstack" \
      org.label-schema.vendor="arbouin-consulting" \
      org.label-schema.url="https://github.com/arbouin-consulting/bookstack-docker/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/arbouin-consulting/bookstack-docker.git" \
      org.label-schema.vcs-type="Git"

ENV BOOKSTACK_HOME=${BOOKSTACK_HOME} \
    DOCKERIZE_VERSION=v0.6.1

RUN apk --no-cache update \
    && apk upgrade \
    && apk add --no-cache --virtual git \
        openssl-dev \
        openssl \
        libzip-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        jpeg \
        openldap-dev \
        libmcrypt-dev \
        wget \
        tidyhtml-dev \
        libxml2-dev \
        libstdc++ \
        libx11 \
        libxrender \
        libxext \
        libssl1.1 \
        ca-certificates \
        fontconfig \
        freetype \
        ttf-dejavu \
        ttf-droid \
        ttf-freefont \
        ttf-liberation \
#        ttf-ubuntu-font-family \
    && update-ca-certificates
RUN docker-php-ext-configure zip \
    && docker-php-ext-install opcache mysqli pdo pdo_mysql zip ldap xml tidy \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd
RUN apk add --no-cache \
    icu-dev \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-enable intl \
    && wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm -f dockerize-alpine-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && echo "date.timezone=${PHP_TIMEZONE:-UTC}" > $PHP_INI_DIR/conf.d/date_timezone.ini \
    && rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

COPY --from=composer $BOOKSTACK_HOME $BOOKSTACK_HOME

RUN chown -R www-data:www-data $BOOKSTACK_HOME

ADD ["./.docker/php/php.ini", "./.docker/php/opcache.ini", "$PHP_INI_DIR/conf.d/"]
ADD ["./docker-entrypoint.sh", "/root/"]

WORKDIR $BOOKSTACK_HOME

VOLUME ["$BOOKSTACK_HOME/public", "$BOOKSTACK_HOME/public/uploads", "$BOOKSTACK_HOME/storage"]

ENTRYPOINT ["/bin/sh", "/root/docker-entrypoint.sh"]

EXPOSE 9000

CMD ["php-fpm"]

# ===============================================================================================
# NGINX
# ===============================================================================================
FROM nginx:${NGINX_VERSION}-alpine AS nginx

ARG BOOKSTACK_HOME

RUN apk --no-cache update \
    && apk upgrade \
    && mkdir -p ${BOOKSTACK_HOME}

COPY --from=php --chown=nginx:nginx "${BOOKSTACK_HOME}/public" ${BOOKSTACK_HOME}/public

RUN chmod -R 755 ${BOOKSTACK_HOME}

COPY .docker/nginx/default-prod.conf /etc/nginx/conf.d/default.conf
