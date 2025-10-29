#!/bin/bash

# ============================================
# Script de Verificación de Estado
# ============================================
# Uso: chmod +x verificar-estado.sh && ./verificar-estado.sh
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "📊 Estado de la Aplicación en K3s"
echo "=========================================="

# Verificar si el namespace existe
if ! kubectl get namespace reservas-app &> /dev/null; then
    echo -e "${RED}❌ El namespace 'reservas-app' no existe${NC}"
    echo "Ejecuta primero: ./deploy-completo.sh"
    exit 1
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 DEPLOYMENTS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl get deployments -n reservas-app

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💾 ALMACENAMIENTO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl get pvc -n reservas-app

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 ESTADO DE CADA POD${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

PODS=$(kubectl get pods -n reservas-app -o jsonpath='{.items[*].metadata.name}')

for POD in $PODS; do
    STATUS=$(kubectl get pod $POD -n reservas-app -o jsonpath='{.status.phase}')
    READY=$(kubectl get pod $POD -n reservas-app -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
    RESTARTS=$(kubectl get pod $POD -n reservas-app -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
    
    if [ "$STATUS" = "Running" ] && [ "$READY" = "true" ]; then
        echo -e "${GREEN}✅${NC} $POD"
        echo "   Estado: Running | Listo: Sí | Reinicios: $RESTARTS"
    elif [ "$STATUS" = "Running" ]; then
        echo -e "${YELLOW}⚠️${NC} $POD"
        echo "   Estado: Running | Listo: No | Reinicios: $RESTARTS"
    else
        echo -e "${RED}❌${NC} $POD"
        echo "   Estado: $STATUS | Listo: No | Reinicios: $RESTARTS"
    fi
done

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🌐 URLs DE ACCESO${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Obtener IP del nodo
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Obtener puertos de los servicios
FRONTEND_PORT=$(kubectl get svc frontend-service -n reservas-app -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
API_PORT=$(kubectl get svc api-service -n reservas-app -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
ANALYTICS_PORT=$(kubectl get svc analytics-service -n reservas-app -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")

echo ""
echo "📱 Frontend:   http://$NODE_IP:$FRONTEND_PORT"
echo "🔧 API:        http://$NODE_IP:$API_PORT"
echo "📊 Analytics:  http://$NODE_IP:$ANALYTICS_PORT"
echo ""
echo "💡 Tip: Si estás usando LoadBalancer, espera a que se asignen las IPs externas"

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}⚡ EVENTOS RECIENTES (últimos 10)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl get events -n reservas-app --sort-by='.lastTimestamp' | tail -10

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}💻 USO DE RECURSOS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if kubectl top pods -n reservas-app &> /dev/null; then
    kubectl top pods -n reservas-app
else
    echo -e "${YELLOW}⚠️  metrics-server no está instalado${NC}"
    echo "Para instalar: kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
fi

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔧 COMANDOS ÚTILES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📝 Ver logs:"
echo "   kubectl logs -f deployment/api -n reservas-app"
echo "   kubectl logs -f deployment/analytics -n reservas-app"
echo "   kubectl logs -f deployment/frontend -n reservas-app"
echo "   kubectl logs -f deployment/postgres -n reservas-app"
echo ""
echo "🔄 Reiniciar servicios:"
echo "   kubectl rollout restart deployment/api -n reservas-app"
echo "   kubectl rollout restart deployment/analytics -n reservas-app"
echo "   kubectl rollout restart deployment/frontend -n reservas-app"
echo ""
echo "📈 Escalar replicas:"
echo "   kubectl scale deployment/api --replicas=3 -n reservas-app"
echo ""
echo "🔍 Acceder a un pod:"
echo "   kubectl exec -it deployment/postgres -n reservas-app -- /bin/bash"
echo ""
echo "💾 Backup de base de datos:"
echo "   kubectl exec deployment/postgres -n reservas-app -- pg_dump -U postgres reservas_db > backup.sql"
echo ""

# Verificar si hay problemas
PROBLEM_PODS=$(kubectl get pods -n reservas-app --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | tail -n +2)

if [ ! -z "$PROBLEM_PODS" ]; then
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}⚠️  ADVERTENCIA: HAY PODS CON PROBLEMAS${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Para más detalles ejecuta:"
    for POD in $PROBLEM_PODS; do
        POD_NAME=$(echo $POD | awk '{print $1}')
        echo "  kubectl describe pod $POD_NAME -n reservas-app"
        echo "  kubectl logs $POD_NAME -n reservas-app"
    done
    echo ""
fi

echo "=========================================="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📦 PODS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl get pods -n reservas-app -o wide

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔌 SERVICIOS Y PUERTOS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
kubectl get svc -n reservas-app

echo -e "\n${BLUE}━━━━━━