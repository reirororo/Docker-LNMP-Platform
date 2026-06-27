FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    curl \
    linux-headers \
    $PHPIZE_DEPS \
    && docker-php-ext-install \
    pdo_mysql \
    mysqli \
    pcntl \
    && pecl install redis \
    && docker-php-ext-enable redis

# Install composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Create php-fpm healthcheck script
RUN echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck \
    && echo 'php-fpm -t > /dev/null 2>&1' >> /usr/local/bin/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

WORKDIR /var/www/html
EXPOSE 9000
CMD ["php-fpm"]
