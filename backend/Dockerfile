FROM php:8.2-cli

# System deps + PHP extensions required by project (maatwebsite/excel -> phpspreadsheet -> gd)
RUN apt-get update && apt-get install -y --no-install-recommends \
  git unzip pkg-config \
  libpng-dev libjpeg-dev libfreetype6-dev \
  libzip-dev \
  libpq-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" gd pdo pdo_pgsql zip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install composer deps first (better layer caching)
COPY composer.json composer.lock ./
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader --no-scripts

# Copy the rest of the app
COPY . .

RUN composer dump-autoload --optimize \
  && php artisan package:discover --ansi

# Répertoires runtime Laravel (évite erreurs silencieuses au premier hit)
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
  && chmod -R ug+rwX storage bootstrap/cache

COPY scripts/railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh

# Railway injecte PORT — PHP built-in server (document root public/)
CMD ["/usr/local/bin/railway-entrypoint.sh"]
