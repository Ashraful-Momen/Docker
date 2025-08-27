Here's how to test your Docker build image:

**1. Build your image with a tag:**
```bash
docker build -t ashrafulinstasure/instasure:v1.0.1 .
```

**2. Create a test docker-compose file** (`docker-compose.test.yml`):**3. Test your built image:**

```bash
# Test with the test compose file
docker-compose -f docker-compose.test.yml up -d

# Check if containers are running
docker ps

# Check logs for any errors
docker logs laravel_app_test
docker logs laravel_nginx_test

# Test the application
curl http://localhost:8090

# Or visit http://localhost:8090 in your browser
```

**4. Alternative: Test standalone PHP-FPM container:**
```bash
# Test just the PHP container
docker run -d --name test-php -p 9001:9000 ashrafulinstasure/instasure:v1.0.1

# Check if it's running
docker ps | grep test-php

# Check logs
docker logs test-php

# Test PHP is working
docker exec -it test-php php -v

# Clean up
docker stop test-php && docker rm test-php
```

**5. Verify your image contents:**
```bash
# Enter the container to inspect
docker run -it --rm ashrafulinstasure/instasure:v1.0.1 bash

# Check PHP extensions
php -m | grep -E "(intl|redis|gd|mysql)"

# Check Laravel files
ls -la /var/www/html

# Check permissions
ls -la /var/www/html/storage
```

**6. Clean up test environment:**
```bash
# Stop test containers
docker-compose -f docker-compose.test.yml down

# Remove test containers and networks
docker-compose -f docker-compose.test.yml down --volumes
```

**7. If tests pass, push to Docker Hub:**
```bash
docker login
docker push ashrafulinstasure/instasure:v1.0.1
```

This approach lets you test the exact image you'll push without affecting your current development environment.
