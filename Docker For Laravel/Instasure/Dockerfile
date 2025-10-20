# Use PHP 8.3 FPM image
FROM php:8.3-fpm

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    zip \
    unzip \
    git \
    curl \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libssl-dev \
    pkg-config \
    default-mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        mbstring \
        zip \
        exif \
        pcntl \
        gd \
        xml \
        bcmath \
        soap \
        intl \
        mysqli \
        opcache

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy PHP configuration
COPY ./docker/php/local.ini /usr/local/etc/php/conf.d/local.ini

# Create user for Laravel application
RUN groupadd -g 1000 www \
    && useradd -u 1000 -ms /bin/bash -g www www

# -------------------------------
# 👉 COPY THE ENTIRE APP FIRST
# -------------------------------
COPY . .

# -------------------------------
# 👉 NOW RUN composer install
# -------------------------------
USER root

RUN composer install --no-dev --optimize-autoloader --no-interaction

# -------------------------------
# 👉 Set permissions
# -------------------------------
RUN chown -R www:www /var/www/html && \
    chmod -R 755 storage bootstrap/cache

# -------------------------------
# 👉 Switch to non-root user
# -------------------------------
USER www

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Start PHP-FPM server
CMD ["php-fpm"]
