#!/bin/bash

echo "🚀 Migrating Laravel 8 packages to Laravel 10..."

# Navigate to project directory (adjust path if needed)
cd ~/Laravel_version_test/LaravelPHP83Docker

# Backup current composer.json
echo "📦 Backing up current composer.json..."
docker-compose exec app cp composer.json composer.json.backup

# Copy the updated composer.json
echo "🔄 Updating composer.json..."
# You'll need to copy the updated composer.json content to the container

# Clear composer cache
echo "🧹 Clearing composer cache..."
docker-compose exec app composer clear-cache

# Remove vendor directory and composer.lock
echo "🗑️ Removing vendor directory and composer.lock..."
docker-compose exec app rm -rf vendor composer.lock

# Install new dependencies
echo "📥 Installing updated dependencies..."
docker-compose exec app composer install

# Update all packages with dependencies
echo "⬆️ Updating packages..."
docker-compose exec app composer update --with-all-dependencies

# Create helper directories if they don't exist
echo "📁 Creating helper directories..."
docker-compose exec app mkdir -p app/Helpers

# Clear various caches
echo "🧽 Clearing application caches..."
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan view:clear
docker-compose exec app php artisan route:clear

# Publish vendor assets
echo "📤 Publishing vendor assets..."
docker-compose exec app php artisan vendor:publish --all --force

# Run database migrations
echo "🗄️ Running database migrations..."
docker-compose exec app php artisan migrate

# Generate optimized autoloader
echo "⚡ Optimizing autoloader..."
docker-compose exec app composer dump-autoload -o

echo "✅ Migration completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Check for any compatibility issues in your code"
echo "   2. Update any deprecated Laravel 8 syntax"
echo "   3. Test your application thoroughly"
echo "   4. Review the Laravel 10 upgrade guide"
echo ""
echo "🔍 Useful commands to check status:"
echo "   docker-compose exec app composer show"
echo "   docker-compose exec app php artisan about"
echo "   docker-compose exec app php artisan route:list"
