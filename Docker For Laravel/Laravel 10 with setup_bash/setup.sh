#!/bin/bash

echo "🚀 Setting up Laravel 10 with Docker (PHP 8.3, MySQL, Nginx)"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ] && [ ! -f "Docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found in current directory"
    echo "📂 Please run this script from the project directory containing docker-compose.yml"
    exit 1
fi

# Fix filename case if needed
if [ -f "Docker-compose.yml" ]; then
    echo "🔧 Fixing docker-compose filename case..."
    mv Docker-compose.yml docker-compose.yml
fi

# Create docker directories if they don't exist
mkdir -p docker/nginx docker/php docker/mysql

echo "📂 Created Docker configuration directories"

# Clean up any partial installation
echo "🧹 Cleaning up any existing Laravel files..."
rm -rf vendor composer.lock package-lock.json node_modules
find . -name "*.log" -delete

# Create Laravel 10 project in a temporary directory first
echo "📦 Creating Laravel 10 project..."
TEMP_DIR=$(mktemp -d)
docker run --rm \
    -v $TEMP_DIR:/opt \
    -w /opt \
    laravelsail/php83-composer:latest \
    bash -c "composer create-project laravel/laravel temp-laravel '^10.0'"

# Copy Laravel files to current directory, excluding our Docker files
echo "📁 Moving Laravel files to project directory..."
cp -r $TEMP_DIR/temp-laravel/* ./
cp $TEMP_DIR/temp-laravel/.* ./ 2>/dev/null || true

# Clean up temp directory with proper permissions
echo "🧹 Cleaning up temporary files..."
sudo rm -rf $TEMP_DIR 2>/dev/null || rm -rf $TEMP_DIR

echo "✅ Laravel 10 project created"

# Set up environment file
if [ -f ".env.docker" ]; then
    cp .env .env.backup 2>/dev/null || true
    cp .env.docker .env
    echo "🔧 Environment file configured for Docker"
else
    echo "⚠️  Warning: .env.docker not found, using default .env"
fi

# Generate application key
echo "🔑 Generating application key..."
docker run --rm \
    -v $(pwd):/var/www/html \
    -w /var/www/html \
    php:8.3-cli \
    php artisan key:generate

echo "🐳 Building and starting Docker containers..."
docker-compose up -d --build

echo "⏳ Waiting for containers to be ready..."
sleep 30

echo "📊 Installing Composer dependencies..."
docker-compose exec app composer install

echo "🗄️ Running database migrations..."
docker-compose exec app php artisan migrate

echo "🎯 Setting up storage permissions..."
docker-compose exec app php artisan storage:link

echo "🧹 Clearing caches..."
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan view:clear

echo "🎉 Setup complete!"
echo ""
echo "📋 Your Laravel 10 application is now running:"
echo "   🌐 Web: http://localhost:8080"
echo "   🗄️ PHPMyAdmin: http://localhost:8081"
echo "   📊 MySQL: localhost:3307"
echo "   🔴 Redis: localhost:6380"
echo ""
echo "🔧 Useful commands:"
echo "   📦 Install packages: docker-compose exec app composer require package/name"
echo "   🎨 Run artisan: docker-compose exec app php artisan command"
echo "   📊 Check logs: docker-compose logs -f"
echo "   🛑 Stop containers: docker-compose down"
echo "   🔄 Restart containers: docker-compose restart"
echo ""
echo "💡 Database credentials:"
echo "   Host: mysql (internal) or localhost:3307 (external)"
echo "   Database: laravel_db"
echo "   Username: laravel_user"
echo "   Password: laravel_password"
