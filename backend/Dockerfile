FROM php:8.2-cli

# System deps + PHP extensions required by project (maatwebsite/excel -> phpspreadsheet -> gd)
RUN apt-get update && apt-get install -y --no-install-recommends \
  git unzip pkg-config \
  libpng-dev libjpeg-dev libfreetype6-dev \
  libzip-dev \
  libpq-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" gd pdo pdo_mysql pdo_pgsql zip \
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

# Démarrage (Render / hébergeur Docker) :
# 1. MYSQL_CA_CERT (contenu du certificat CA Aiven) -> fichier PEM + MYSQL_ATTR_SSL_CA
#    Le contenu est normalisé (retours à la ligne perdus au copier-coller, "\n" littéraux)
#    puis réécrit en lignes de 64 caractères.
# 2. migrations (sans seeders : pas de réinitialisation des mots de passe)
# 3. serveur PHP sur le port imposé par l'hébergeur ($PORT)
CMD if [ -n "$MYSQL_CA_CERT" ]; then \
      body=$(printf '%s' "$MYSQL_CA_CERT" | sed -e 's/\\n//g' -e 's/-----BEGIN CERTIFICATE-----//g' -e 's/-----END CERTIFICATE-----//g' | tr -d ' \r\n\t'); \
      { echo '-----BEGIN CERTIFICATE-----'; printf '%s' "$body" | fold -w 64; echo; echo '-----END CERTIFICATE-----'; } > /tmp/mysql-ca.pem; \
      export MYSQL_ATTR_SSL_CA=/tmp/mysql-ca.pem; \
    fi; \
    php artisan config:clear; \
    php artisan migrate --force || echo 'ATTENTION: migrations en echec'; \
    exec php -S 0.0.0.0:${PORT:-8000} -t public public/index.php
