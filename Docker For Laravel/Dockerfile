# Use the official PHP image as a base image
FROM php:7.4-fpm

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    locales \
    zip \
    jpegoptim optipng pngquant gifsicle \
    vim \
    unzip \
    git \
    curl \
    libonig-dev

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www-data:www-data . /var/www

# Change current user to www
USER www-data

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]

# ---------------------------------------------------------------
# Copy existing application directory contents. Means copy all files from current directory to /var/www in my local machine
# COPY . /var/www







# FROM php:7.4-fpm

# # Install required system packages
# RUN apt-get update && apt-get install -y \
#     # Packages needed for PHP extensions and application dependencies
#     libpng-dev \
#     libjpeg62-turbo-dev \
#     libfreetype6-dev \
#     locales \
#     zip \
#     jpegoptim optipng pngquant gifsicle \
#     vim \
#     unzip \
#     git \
#     curl \
#     libonig-dev

# # Clear cache
# RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# # Install PHP extensions
# RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# # Install Composer : and copy it to /usr/bin | --from=composer:latest means copy from composer image and paste it to /usr/bin in my local machine
# COPY --from=composer:latest /usr/bin/composer /usr/bin/composer   

# # Set working directory
# WORKDIR /var/www

# # Ensure www-data user has appropriate permissions
# RUN chown -R www-data:www-data /var/www

# # Expose port 9000 and start php-fpm server
# EXPOSE 9000
# CMD ["php-fpm"]


#List of useful Docker commands:__________________________________________________________________

# docker build -t laravel-app . #build docker image | -t means name of image

# docker run -itd --name laravel-app -p 8000:80 laravel-app #run docker image | -itd means interactive and detach | -p means port mapping | 8000:80 means port 8000 on host to port 80 in container

# docker exec -it laravel-app bash #for console access this container.

# docker logs -f laravel-app #to see logs












