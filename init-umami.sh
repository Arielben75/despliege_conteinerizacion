#!/bin/sh
set -e

echo "==========================================="
echo "Inicializando configuración de Umami"
echo "==========================================="

# Variables de entorno con valores por defecto
UMAMI_USERNAME="${UMAMI_USERNAME:-admin}"
UMAMI_PASSWORD="${UMAMI_PASSWORD:-umami}"
WEBSITE_DOMAIN="${WEBSITE_DOMAIN:-localhost:5173}"
WEBSITE_NAME="${WEBSITE_NAME:-Reservas App}"
UMAMI_HOST="${UMAMI_HOST:-http://analytics:3000}"
MAX_RETRIES=60
RETRY_COUNT=0

echo "Configuración:"
echo "  - Usuario: ${UMAMI_USERNAME}"
echo "  - Dominio: ${WEBSITE_DOMAIN}"
echo "  - Nombre: ${WEBSITE_NAME}"
echo "  - Host: ${UMAMI_HOST}"
echo ""

# Función para esperar a que Umami esté disponible
wait_for_umami() {
  echo "Esperando a que Umami esté disponible..."
  echo "Esto puede tomar varios minutos en la primera ejecución..."
  
  # Primero intentar resolver el nombre DNS
  echo "Verificando conectividad DNS..."
  if ! nslookup analytics >/dev/null 2>&1; then
    echo "⚠ Advertencia: No se puede resolver 'analytics' por DNS"
    echo "Intentando con getent..."
    getent hosts analytics || echo "getent también falló"
  fi
  
  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    # Intentar conectar con más detalle
    if curl -sf --connect-timeout 5 "${UMAMI_HOST}/api/auth/login" > /dev/null 2>&1; then
      echo "✓ Umami está disponible"
      return 0
    fi
    
    # Mostrar más información en caso de error
    if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
      echo "Intento ${RETRY_COUNT}/${MAX_RETRIES} - Debug info:"
      curl -v --connect-timeout 2 "${UMAMI_HOST}/api/auth/login" 2>&1 | head -10 || true
    else
      echo "Intento ${RETRY_COUNT}/${MAX_RETRIES} - Esperando 5 segundos..."
    fi
    
    sleep 5
  done
  
  echo "✗ Error: Umami no respondió después de ${MAX_RETRIES} intentos"
  echo "Último intento con verbose:"
  curl -v "${UMAMI_HOST}/api/auth/login" 2>&1 || true
  exit 1
}

# Resto del script igual...
# [... copiar el resto de funciones ...]

# Ejecución principal
main() {
  wait_for_umami
  get_auth_token
  
  if ! check_existing_website; then
    create_website
  fi
  
  save_config
  
  echo ""
  echo "==========================================="
  echo "✓ Inicialización completada exitosamente"
  echo "==========================================="
  echo "WEBSITE_ID: ${WEBSITE_ID}"
  echo ""
}

# Ejecutar
main