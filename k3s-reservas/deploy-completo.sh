#!/bin/bash

# ============================================
# Script de Despliegue Completo para K3s
# ============================================
# Este script despliega toda la aplicación
# Uso: chmod +x deploy-completo.sh && ./deploy-completo.sh
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🚀 Desplegando Aplicación en K3s"
echo "=========================================="

# Verificar si kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl no está instalado${NC}"
    echo "Instala K3s primero: curl -sfL https://get.k3s.io | sh -"
    exit 1
fi

# Verificar si el archivo de manifiestos existe
if [ ! -f "todos-los-manifiestos.yaml" ]; then
    echo -e "${RED}❌ El archivo todos-los-manifiestos.yaml no existe${NC}"
    echo "Asegúrate de tener el archivo en el directorio actual"
    exit 1
fi

echo -e "\n${YELLOW}[1/5]${NC} Aplicando todos los manifiestos..."
kubectl apply -f todos-los-manifiestos.yaml

echo -e "\n${YELLOW}[2/5]${NC} Esperando a que PostgreSQL esté listo..."
kubectl wait --for=condition=ready pod -l app=postgres -n reservas-app --timeout=300s

echo -e "\n${YELLOW}[3/5]${NC} Esperando a que el API esté listo..."
kubectl wait --for=condition=available deployment/api -n reservas-app --timeout=300s

echo -e "\n${YELLOW}[4/5]${NC} Esperando a que Analytics esté listo..."
kubectl wait --for=condition=available deployment/analytics -n reservas-app --timeout=300s

echo -e "\n${YELLOW}[5/5]${NC} Esperando a que el Frontend esté listo..."
kubectl wait --for=condition=available deployment/frontend -n reservas-app --timeout=300s

echo -e "\n${GREEN}=========================================="
echo "✅ Despliegue Completado Exitosamente"
echo "==========================================${NC}"

echo -e "\n${BLUE}📊 Estado de los Servicios:${NC}"
kubectl get all -n reservas-app

echo -e "\n${BLUE}🌐 Obtener URLs de acceso:${NC}"
kubectl get svc -n reservas-app

echo -e "\n${GREEN}Para acceder a tu aplicación:${NC}"
echo "1. Obtén la IP del nodo: kubectl get nodes -o wide"
echo "2. Accede a:"
echo "   - Frontend:   http://<IP-NODO>:5173"
echo "   - API:        http://<IP-NODO>:3000"
echo "   - Analytics:  http://<IP-NODO>:8080"

echo -e "\n${BLUE}📝 Comandos útiles:${NC}"
echo "Ver logs del API:       kubectl logs -f deployment/api -n reservas-app"
echo "Ver logs de Analytics:  kubectl logs -f deployment/analytics -n reservas-app"
echo "Ver logs del Frontend:  kubectl logs -f deployment/frontend -n reservas-app"
echo "Ver todos los pods:     kubectl get pods -n reservas-app"
echo "Ver eventos:            kubectl get events -n reservas-app --sort-by='.lastTimestamp'"

echo -e "\n${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "Antes de usar en producción, cambia las contraseñas en el archivo todos-los-manifiestos.yaml"
echo ""