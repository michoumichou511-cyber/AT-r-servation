FROM php:8.2-cli

# System deps + PHP extensions required by project (maatwebsite/excel -> phpspreadsheet -> gd)
RUN apt-get update && apt-get install -y --no-install-recommends \
  git unzip pkg-config \
  libpng-dev libjpeg-dev libfreetype6-dev \
  libzip-dev \
  libpq-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j"$(nproc)" gd pdo pdo_mysql pdo_pgsql zip opcache \
  && rm -rf /var/lib/apt/lists/*

# OPcache : le code PHP compilé reste en mémoire (le code ne change pas dans le conteneur)
RUN { \
    echo "opcache.enable=1"; \
    echo "opcache.memory_consumption=128"; \
    echo "opcache.interned_strings_buffer=16"; \
    echo "opcache.max_accelerated_files=20000"; \
    echo "opcache.validate_timestamps=0"; \
  } > /usr/local/etc/php/conf.d/opcache-prod.ini

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
#    Le contenu est normalisé (retours à la ligne perdus au copier-coller, "\n" littéraux,
#    espaces insécables, en-têtes traduits par le navigateur...) : seuls les caractères
#    base64 entre les délimiteurs "-----...-----" sont conservés,
#    puis réécrits en lignes de 64 caractères.
# 2. migrations (sans seeders : pas de réinitialisation des mots de passe)
# 3. caches Laravel (routes, événements)
# 4. serveur PHP sur le port imposé par l'hébergeur ($PORT), 4 workers en parallèle
CMD if [ -n "$MYSQL_CA_CERT" ]; then \
      php -r '$r=str_replace(["\\r\\n","\\n","\\r"],"\n",(string)getenv("MYSQL_CA_CERT")); $r=preg_replace("/[^\x20-\x7E\n]/","",$r); $bs=preg_match_all("/-----[^-]+-----(.*?)-----[^-]+-----/s",$r,$m)?$m[1]:[$r]; $pem=""; foreach($bs as $b){$b=preg_replace("/[^A-Za-z0-9+\/=]/","",$b); $pem.="-----BEGIN CERTIFICATE-----\n".chunk_split($b,64,"\n")."-----END CERTIFICATE-----\n";} file_put_contents("/tmp/mysql-ca.pem",$pem); $c=@openssl_x509_parse($pem); echo $c ? "DIAG CA MySQL OK: ".$c["name"]." (expire ".date("Y-m-d",$c["validTo_time_t"]).")\n" : "DIAG CA MySQL ILLISIBLE: ".strlen($r)." car., debut=".json_encode(substr($r,0,40))." fin=".json_encode(substr($r,-40))."\n";'; \
      export MYSQL_ATTR_SSL_CA=/tmp/mysql-ca.pem; \
    else \
      echo 'DIAG CA MySQL ABSENT: variable MYSQL_CA_CERT vide'; \
    fi; \
    php -r '$h=getenv("DB_HOST"); $p=(int)getenv("DB_PORT"); $s=@fsockopen($h,$p,$e,$m,5); echo $s ? "DIAG reseau MySQL OK: $h:$p joignable\n" : "DIAG reseau MySQL ECHEC: $h:$p ($m)\n";'; \
    php artisan config:clear; \
    php artisan migrate --force || echo 'ATTENTION: migrations en echec'; \
    php artisan db:seed --class=RoleSeeder --force || echo 'ATTENTION: roles en echec'; \
    php artisan db:seed --class=ATUsersSeeder --force || echo 'ATTENTION: users en echec'; \
    php artisan db:seed --class=PrestatairesSeeder --force || echo 'ATTENTION: prestataires en echec'; \
    php artisan db:seed --class=HotelConventionSeeder --force || echo 'ATTENTION: hotels en echec'; \
    php artisan db:seed --class=VehiculeSeeder --force || echo 'ATTENTION: vehicules en echec'; \
    if [ -n "$ADMIN_EMAIL" ] && [ -n "$ADMIN_PASSWORD" ]; then \
      php artisan tinker --execute='$u = App\Models\User::firstOrCreate(["email" => getenv("ADMIN_EMAIL")], ["password" => Illuminate\Support\Facades\Hash::make(getenv("ADMIN_PASSWORD")), "nom" => "Admin", "prenom" => "Systeme", "role_id" => App\Models\Role::where("name", "admin")->value("id"), "is_active" => true]); echo "DIAG admin ".$u->email.($u->wasRecentlyCreated ? " cree" : " existe deja (inchange)").PHP_EOL;' || echo 'ATTENTION: creation admin en echec'; \
    fi; \
    php artisan route:cache || echo 'ATTENTION: route:cache en echec'; \
    php artisan event:cache || echo 'ATTENTION: event:cache en echec'; \
    PHP_CLI_SERVER_WORKERS=${PHP_CLI_SERVER_WORKERS:-4} exec php -S 0.0.0.0:${PORT:-8000} -t public public/index.php
