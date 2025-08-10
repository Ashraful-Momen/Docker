#!/bin/bash

echo "📦 Installing Laravel 7 packages into Laravel 10 container"
echo "=========================================================="

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

# Function to install package with fallback
install_package() {
    local package=$1
    local version=$2
    local fallback_version=$3
    local package_name="${package}:${version}"

    print_info "Installing ${package_name}..."

    if docker-compose exec app composer require "${package_name}" --no-scripts; then
        print_success "✅ ${package} installed successfully"
        return 0
    elif [ -n "$fallback_version" ]; then
        print_warning "Primary version failed, trying fallback: ${package}:${fallback_version}"
        if docker-compose exec app composer require "${package}:${fallback_version}" --no-scripts; then
            print_success "✅ ${package} installed with fallback version"
            return 0
        else
            print_error "❌ ${package} installation failed completely"
            return 1
        fi
    else
        print_error "❌ ${package} installation failed"
        return 1
    fi
}

# Check if container is running
if ! docker ps | grep -q laravel_app; then
    print_error "Container laravel_app is not running. Please start it first."
    exit 1
fi

print_info "Current Laravel version:"
docker-compose exec app php artisan --version

echo ""
print_info "🚀 Starting package installation..."

# Create helper directories
print_info "📁 Creating helper directories..."
docker-compose exec app mkdir -p app/Helpers

# Install packages in order of dependency complexity

echo ""
print_info "=== GROUP 1: CORE UTILITIES ==="

# HTTP Client
install_package "guzzlehttp/guzzle" "^7.5"

# Image manipulation
install_package "intervention/image" "^2.7"

# Excel handling
install_package "maatwebsite/excel" "^3.1"

# CORS handling (Laravel 10 has different requirement)
install_package "fruitcake/laravel-cors" "^3.0" "^2.0"

echo ""
print_info "=== GROUP 2: PDF & DOCUMENT GENERATION ==="

# PDF generation
install_package "barryvdh/laravel-dompdf" "^2.0" "^1.0"
install_package "carlos-meneses/laravel-mpdf" "^2.1"

echo ""
print_info "=== GROUP 3: UI & NOTIFICATIONS ==="

# Toast notifications
install_package "brian2694/laravel-toastr" "^5.57" "^5.54"

# Laravel UI
install_package "laravel/ui" "^4.0" "^3.0"

echo ""
print_info "=== GROUP 4: AUTHENTICATION & PERMISSIONS ==="

# API authentication
install_package "laravel/passport" "^11.0" "^10.0"

# Permissions
install_package "spatie/laravel-permission" "^5.10" "^4.0"

echo ""
print_info "=== GROUP 5: FRONTEND & INTERACTIVE ==="

# Livewire (major version change!)
print_warning "Installing Livewire 3.x (BREAKING CHANGES from 2.x)"
install_package "livewire/livewire" "^3.0" "^2.12"

# DataTables
install_package "yajra/laravel-datatables-oracle" "^10.0" "^9.0"

echo ""
print_info "=== GROUP 6: THIRD-PARTY SERVICES ==="

# reCAPTCHA
install_package "biscolab/laravel-recaptcha" "^6.0" "^5.0"

# Email service
install_package "mailjet/mailjet-apiv3-php" "^1.5"

# Shopping cart
install_package "olimortimer/laravelshoppingcart" "^4.0"

# API documentation
install_package "knuckleswtf/scribe" "^4.0" "^3.0"

echo ""
print_info "=== GROUP 7: SPECIALIZED SERVICES ==="

# Firebase
print_warning "Installing Firebase SDK (may have breaking changes)"
install_package "kreait/laravel-firebase" "^5.0" "^4.0"

# Payment gateways (Bangladesh specific)
install_package "karim007/laravel-bkash-tokenize" "^2.3"
install_package "karim007/laravel-nagad" "^1.1"

# GRPC (optional, might fail)
print_info "Installing GRPC (optional, may fail)..."
docker-compose exec app composer require "grpc/grpc:^1.50" --no-scripts --ignore-platform-req=ext-grpc || print_warning "GRPC installation failed (this is usually OK)"

echo ""
print_info "=== GROUP 8: DEVELOPMENT PACKAGES ==="

# Development tools
install_package "barryvdh/laravel-debugbar" "^3.8" "^3.6"
install_package "laravel/pint" "^1.0"
install_package "laravel/sail" "^1.18"

# Testing
docker-compose exec app composer require "fakerphp/faker:^1.21" --dev --no-scripts || print_warning "Faker installation failed"
docker-compose exec app composer require "mockery/mockery:^1.5" --dev --no-scripts || print_warning "Mockery installation failed"
docker-compose exec app composer require "nunomaduro/collision:^7.0" --dev --no-scripts || print_warning "Collision installation failed"
docker-compose exec app composer require "phpunit/phpunit:^10.1" --dev --no-scripts || print_warning "PHPUnit installation failed"

# Replace facade/ignition with spatie/laravel-ignition
docker-compose exec app composer require "spatie/laravel-ignition:^2.0" --dev --no-scripts || print_warning "Ignition installation failed"

echo ""
print_info "=== FINALIZATION ==="

# Create Laravel 10 directory structure
print_info "📁 Setting up Laravel 10 directory structure..."
docker-compose exec app mkdir -p database/factories database/seeders

# Update autoloader paths if needed
print_info "🔄 Updating autoloader..."
docker-compose exec app composer dump-autoload

# Run package discovery
print_info "🔍 Running package discovery..."
docker-compose exec app php artisan package:discover --ansi

# Clear all caches
print_info "🧹 Clearing caches..."
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan view:clear
docker-compose exec app php artisan route:clear

echo ""
print_success "🎉 Package installation completed!"

echo ""
print_info "📊 Installation Summary:"
echo "========================"
docker-compose exec app composer show | grep -E "(laravel|livewire|spatie|yajra|barryvdh|intervention|kreait)" | head -15

echo ""
print_warning "⚠️  IMPORTANT POST-INSTALLATION STEPS:"
echo ""
echo "1. 🔧 LIVEWIRE 3.X MIGRATION (BREAKING CHANGES):"
echo "   - Update all Livewire components syntax"
echo "   - Check: https://livewire.laravel.com/docs/upgrading"
echo ""
echo "2. 🔐 PASSPORT SETUP:"
echo "   docker-compose exec app php artisan passport:install --force"
echo ""
echo "3. 🗄️ RUN MIGRATIONS:"
echo "   docker-compose exec app php artisan migrate"
echo ""
echo "4. 📤 PUBLISH VENDOR ASSETS:"
echo "   docker-compose exec app php artisan vendor:publish --all --force"
echo ""
echo "5. 🔧 UPDATE YOUR CODE FOR:"
echo "   - Spatie Permissions 5.x syntax changes"
echo "   - DataTables 10.x new methods"
echo "   - Livewire 3.x component structure"
echo "   - Laravel 10 specific features"
echo ""
echo "6. 🧪 TEST YOUR APPLICATION:"
echo "   docker-compose exec app php artisan route:list"
echo "   docker-compose exec app php artisan config:show"
echo ""
print_success "✅ Ready to start developing with Laravel 10!"
