#!/bin/bash
# Script completo para desplegar con Docker Secrets

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     DESPLIEGUE CON DOCKER SECRETS                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1. Verificar Swarm
# ============================================
echo -e "${YELLOW} Paso 1: Verificando Docker Swarm...${NC}"
if ! docker info | grep -q "Swarm: active"; then
    echo "⚠️  Swarm no está activo. Inicializando..."
    docker swarm init
    echo -e "${GREEN}✅ Swarm inicializado${NC}"
else
    echo -e "${GREEN}✅ Swarm ya está activo${NC}"
fi
echo ""

# ============================================
# 2. Crear Secrets
# ============================================
echo -e "${YELLOW} Paso 2: Creando secrets...${NC}"

create_secret() {
    local name=$1
    local value=$2
    
    if docker secret inspect "$name" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⏭️  Secret '$name' ya existe${NC}"
    else
        echo "$value" | docker secret create "$name" -
        echo -e "  ${GREEN}✅ Secret '$name' creado${NC}"
    fi
}

create_secret "postgres_password" "PruebasPosgres"
create_secret "jwt_secret" "q^WUUG7NAex9Da5eT@Y4YKv"
create_secret "database_url" "postgresql://postgres:PruebasPosgres@db:5432/reservas_db?schema=public"
create_secret "database_url_umami" "postgresql://postgres:PruebasPosgres@db:5432/umami_db?schema=public"
create_secret "umami_hash_salt" "pruenas_ariel_salt"

echo ""

# ============================================
# 3. Crear Configs
# ============================================
echo -e "${YELLOW}  Paso 3: Creando configs...${NC}"

create_config() {
    local name=$1
    local file=$2
    
    if docker config inspect "$name" >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⏭️  Config '$name' ya existe${NC}"
    else
        if [ -f "$file" ]; then
            docker config create "$name" "$file"
            echo -e "  ${GREEN}✅ Config '$name' creado${NC}"
        else
            echo -e "  ${RED}❌ Error: Archivo '$file' no encontrado${NC}"
            exit 1
        fi
    fi
}

create_config "init_db_v1" "init-db.sh"
create_config "umami_entrypoint_v1" "entrypoint-umami.sh"

echo ""

# ============================================
# 4. Desplegar Stack
# ============================================
echo -e "${YELLOW} Paso 4: Desplegando stack 'reservas'...${NC}"

if [ ! -f "stack-deploy-secrets.yml" ]; then
    echo -e "${RED} Error: No se encontró stack-deploy-secrets.yml${NC}"
    exit 1
fi

docker stack deploy -c stack-deploy-secrets.yml reservas
echo -e "${GREEN} Stack desplegado${NC}"
echo ""

# ============================================
# 5. Verificar Despliegue
# ============================================
echo -e "${YELLOW} Paso 5: Verificando servicios...${NC}"
echo "Esperando 5 segundos..."
sleep 5

docker stack services reservas
echo ""

echo -e "${GREEN}✅ Despliegue completado!${NC}"
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              INFORMACIÓN DE SEGURIDAD                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN} Secrets creados:${NC}"
docker secret ls
echo ""
echo -e "${GREEN}  Configs creados:${NC}"
docker config ls
echo ""
echo -e "${GREEN} Comandos útiles:${NC}"
echo "  • Ver servicios:        docker stack services reservas"
echo "  • Ver logs de API:      docker service logs -f reservas_api"
echo "  • Ver logs de Analytics: docker service logs -f reservas_analytics"
echo "  • Listar secrets:       docker secret ls"
echo "  • Inspeccionar secret:  docker secret inspect database_url"
echo "  • Remover stack:        docker stack rm reservas"
echo ""
echo -e "${YELLOW} Los servicios pueden tardar 1-2 minutos en estar listos${NC}"
echo ""