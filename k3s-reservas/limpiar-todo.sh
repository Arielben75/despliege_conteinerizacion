#!/bin/bash

# ============================================
# Script de Limpieza Completa
# ============================================
# Este script elimina toda la aplicación de K3s
# Uso: chmod +x limpiar-todo.sh && ./limpiar-todo.sh
# ============================================

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=========================================="
echo "🗑️  Limpieza de Aplicación en K3s"
echo "=========================================="

echo -e "\n${RED}⚠️  ADVERTENCIA ⚠️${NC}"
echo "Esto eliminará:"
echo "  ❌ Todos los deployments"
echo "  ❌ Todos los services"
echo "  ❌ Todos los secrets y configmaps"
echo "  ❌ El PersistentVolumeClaim (¡PERDERÁS LOS DATOS DE LA BASE DE DATOS!)"
echo "  ❌ El namespace completo"
echo ""

read -p "¿Estás ABSOLUTAMENTE SEGURO? Escribe 'SI' para confirmar: " confirmacion

if [ "$confirmacion" != "SI" ]; then
    echo -e "${GREEN}✅ Operación cancelada. No se eliminó nada.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}¿Quieres hacer un backup de la base de datos antes? (s/n)${NC}"
read -p "Respuesta: " backup

if [ "$backup" = "s" ] || [ "$backup" = "S" ]; then
    echo -e "\n${YELLOW}Creando backup...${NC}"
    kubectl exec deployment/postgres -n reservas-app -- pg_dump -U postgres reservas_db > backup_$(date +%Y%m%d_%H%M%S).sql
    echo -e "${GREEN}✅ Backup guardado en: backup_$(date +%Y%m%d_%H%M%S).sql${NC}"
fi

echo -e "\n${RED}Eliminando namespace y todos los recursos...${NC}"
kubectl delete namespace reservas-app

echo -e "\n${GREEN}=========================================="
echo "✅ Limpieza Completada"
echo "==========================================${NC}"

echo -e "\nVerificando que no queden recursos:"
kubectl get all -n reservas-app 2>/dev/null || echo -e "${GREEN}✅ No hay recursos restantes${NC}"

echo ""