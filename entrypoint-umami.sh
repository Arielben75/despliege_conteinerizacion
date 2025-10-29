#!/bin/sh
set -e

echo "� Cargando secrets para Umami..."

if [ -f /run/secrets/database_url_umami ]; then
    export DATABASE_URL=$(cat /run/secrets/database_url_umami)
    echo "✅ DATABASE_URL cargado"
else
    echo "❌ Error: secret no encontrado"
    exit 1
fi

if [ -f /run/secrets/umami_hash_salt ]; then
    export HASH_SALT=$(cat /run/secrets/umami_hash_salt)
    echo "✅ HASH_SALT cargado"
else
    echo "❌ Error: secret no encontrado"
    exit 1
fi

echo "� Iniciando Umami..."
exec yarn start-docker
