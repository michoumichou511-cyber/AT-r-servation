#!/usr/bin/env sh
set -eu

cd /app

PORT="${PORT:-8000}"

# Diagnostics visibles dans les logs Railway (Deploy → Runtime)
printf '%s\n' "[railway-entrypoint] PORT=${PORT} cwd=$(pwd)" >&2

if [ ! -f public/index.php ]; then
  echo "[railway-entrypoint] ERROR: missing public/index.php" >&2
  exit 1
fi

if [ ! -f vendor/autoload.php ]; then
  echo "[railway-entrypoint] ERROR: missing vendor/autoload.php (run composer install in image)" >&2
  exit 1
fi

# Laravel needs writable dirs at runtime
mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache 2>/dev/null || true
chmod -R ug+rwX storage bootstrap/cache 2>/dev/null || true

printf '%s\n' "[railway-entrypoint] exec php -S 0.0.0.0:${PORT} -t public public/index.php" >&2
exec php -S "0.0.0.0:${PORT}" -t public public/index.php
