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
#    Le contenu est normalisé (retours à la ligne perdus au copier-coller, "\n" littéraux,
#    espaces insécables, en-têtes traduits par le navigateur...) : seuls les caractères
#    base64 entre les délimiteurs "-----...-----" sont conservés,
#    puis réécrits en lignes de 64 caractères.
# 2. migrations (sans seeders : pas de réinitialisation des mots de passe)
# 3. serveur PHP sur le port imposé par l'hébergeur ($PORT)
CMD if [ -n "$MYSQL_CA_CERT" ]; then \
      php -r '$r=str_replace(["\\r\\n","\\n","\\r"],"\n",(string)getenv("MYSQL_CA_CERT")); $r=preg_replace("/[^\x20-\x7E\n]/","",$r); $bs=preg_match_all("/-----[^-]+-----(.*?)-----[^-]+-----/s",$r,$m)?$m[1]:[$r]; $pem=""; foreach($bs as $b){$b=preg_replace("/[^A-Za-z0-9+\/=]/","",$b); $pem.="-----BEGIN CERTIFICATE-----\n".chunk_split($b,64,"\n")."-----END CERTIFICATE-----\n";} file_put_contents("/tmp/mysql-ca.pem",$pem); $c=@openssl_x509_parse($pem); echo $c ? "DIAG CA MySQL OK: ".$c["name"]." (expire ".date("Y-m-d",$c["validTo_time_t"]).")\n" : "DIAG CA MySQL ILLISIBLE: ".strlen($r)." car., debut=".json_encode(substr($r,0,40))." fin=".json_encode(substr($r,-40))."\n";'; \
      export MYSQL_ATTR_SSL_CA=/tmp/mysql-ca.pem; \
    else \
      echo 'DIAG CA MySQL ABSENT: variable MYSQL_CA_CERT vide'; \
    fi; \
    php -r '$h=getenv("DB_HOST"); $p=(int)getenv("DB_PORT"); $s=@fsockopen($h,$p,$e,$m,5); echo $s ? "DIAG reseau MySQL OK: $h:$p joignable\n" : "DIAG reseau MySQL ECHEC: $h:$p ($m)\n";'; \
    php artisan config:clear; \
    php artisan migrate --force || echo 'ATTENTION: migrations en echec'; \
    exec php -S 0.0.0.0:${PORT:-8000} -t public public/index.php
