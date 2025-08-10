#!/bin/bash

echo "🔍 Laravel Installation Diagnostics"
echo "==================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
print_info "1. Container Status"
echo "=================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep laravel

echo ""
print_info "2. PHP Version & Extensions"
echo "=========================="
docker-compose exec app php -v
echo ""
print_info "Installed PHP Extensions:"
docker-compose exec app php -m | grep -E "(pdo|mysql|gd|zip|mbstring|xml|curl|json|openssl)" | sort

echo ""
print_info "3. Composer Status"
echo "================="
docker-compose exec app composer --version
docker-compose exec app composer diagnose 2>/dev/null | head -10

echo ""
print_info "4. Current Laravel Installation"
echo "============================="
if docker-compose exec app php artisan --version 2>/dev/null; then
    print_success "Laravel is installed and working"
else
    print_error "Laravel is not properly installed"
fi

echo ""
print_info "5. Current Packages"
echo "=================="
print_info "Core Laravel packages:"
docker-compose exec app composer show | grep laravel | head -10

echo ""
print_info "6. Composer.json Analysis"
echo "========================"
docker-compose exec app cat composer.json | grep -A 5 -B 5 '"require"'

echo ""
print_info "7. Recent Composer Errors"
echo "========================"
if docker-compose exec app test -f /root/.composer/cache/repo/packagist.org/packages.json; then
    print_info "Composer cache exists"
else
    print_warning "Composer cache might be corrupted"
fi

echo ""
print_info "8. Storage & Permissions"
echo "======================="
docker-compose exec app ls -la storage/
docker-compose exec app ls -la bootstrap/cache/

echo ""
print_info "9. Memory & System Resources"
echo "============================"
docker-compose exec app php -ini | grep memory_limit
docker-compose exec app df -h /

echo ""
print_info "10. Network Connectivity"
echo "======================="
if docker-compose exec app curl -s https://packagist.org > /dev/null; then
    print_success "Packagist.org is reachable"
else
    print_error "Cannot reach Packagist.org"
fi

echo ""
print_info "11. Suggested Fix Commands"
echo "========================="
echo "# Clear everything and start fresh:"
echo "docker-compose exec app rm -rf vendor composer.lock"
echo "docker-compose exec app composer clear-cache"
echo ""
echo "# Install Laravel 10 step by step:"
echo "docker-compose exec app composer require laravel/framework:^10.0 --no-scripts"
echo "docker-compose exec app composer require laravel/sanctum:^3.2 --no-scripts"
echo ""
echo "# Check for specific errors:"
echo "docker-compose exec app composer require laravel/framework:^10.0 -vvv"

echo ""
print_warning "🔧 Quick Fix Recommendation:"
echo "1. Run the robust migration script: ./robust_migration.sh"
echo "2. Or manually install Laravel 10 first, then add packages one by one"
echo "3. Check the detailed error output with -vvv flag in composer"
