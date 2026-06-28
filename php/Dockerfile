FROM php:8.2-fpm-alpine

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

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Create log directories + real process-based healthcheck
RUN mkdir -p /var/log/php /var/log/php-fpm \
    && echo '#!/bin/sh' > /usr/local/bin/php-fpm-healthcheck \
    && echo 'exec 2>/dev/null' >> /usr/local/bin/php-fpm-healthcheck \
    && echo '# Check if PHP-FPM master process (PID 1) is alive' >> /usr/local/bin/php-fpm-healthcheck \
    && echo 'grep -q php-fpm /proc/1/cmdline || exit 1' >> /usr/local/bin/php-fpm-healthcheck \
    && chmod +x /usr/local/bin/php-fpm-healthcheck

WORKDIR /var/www/html
EXPOSE 9000
CMD ["php-fpm"]
