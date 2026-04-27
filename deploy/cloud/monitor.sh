#!/bin/bash
# Cloud Deployment Monitoring and Health Check Script
# Provides real-time visibility into application and infrastructure health

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source config
if [ ! -f "$SCRIPT_DIR/ec2-config.env" ]; then
    echo -e "${RED}✗ Error: ec2-config.env not found${NC}"
    exit 1
fi

source "$SCRIPT_DIR/ec2-config.env"

COMMAND="${1:-status}"
DETAIL="${2:-basic}"

# ════════════════════════════════════════════════════════════════════════════════
# Docker Status on EC2
# ════════════════════════════════════════════════════════════════════════════════

show_docker_status() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Docker Container Status${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<'SSHSCRIPT'
cd ~/V12_Project/deploy/docker

echo "Containers:"
docker compose ps

echo ""
echo "Image details:"
docker images | grep docker-

echo ""
echo "Container health:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"
SSHSCRIPT
}

# ════════════════════════════════════════════════════════════════════════════════
# System Resources on EC2
# ════════════════════════════════════════════════════════════════════════════════

show_system_resources() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}System Resources (EC2)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<'SSHSCRIPT'
echo "CPU & Memory:"
free -h
echo ""
echo "Disk usage:"
df -h | grep -E "Filesystem|/$|/home"
echo ""
echo "Docker disk usage:"
docker system df
SSHSCRIPT
}

# ════════════════════════════════════════════════════════════════════════════════
# Container Logs
# ════════════════════════════════════════════════════════════════════════════════

show_logs() {
    local service="${1:-all}"
    local lines="${2:-20}"
    
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Container Logs (last $lines lines)${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<SSHSCRIPT
cd ~/V12_Project/deploy/docker

if [ "$service" = "all" ] || [ "$service" = "backend" ]; then
    echo "Backend:"
    docker compose logs --tail=$lines backend
    echo ""
fi

if [ "$service" = "all" ] || [ "$service" = "frontend" ]; then
    echo "Frontend:"
    docker compose logs --tail=$lines frontend
    echo ""
fi

if [ "$service" = "all" ] || [ "$service" = "mongo" ]; then
    echo "MongoDB:"
    docker compose logs --tail=$lines mongo
fi
SSHSCRIPT
}

# ════════════════════════════════════════════════════════════════════════════════
# Application Health
# ════════════════════════════════════════════════════════════════════════════════

show_health() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Application Health${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    
    # Frontend health
    echo "Frontend:"
    if curl -s -f "http://${PUBLIC_IP}:${FRONTEND_PORT}/health" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} http://${PUBLIC_IP}:${FRONTEND_PORT}/health"
    else
        echo -e "  ${RED}✗${NC} http://${PUBLIC_IP}:${FRONTEND_PORT}/health"
    fi
    
    # Backend health  
    echo "Backend:"
    if curl -s -f "http://${PUBLIC_IP}:${FRONTEND_PORT}/api/health" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} http://${PUBLIC_IP}:${FRONTEND_PORT}/api/health"
    else
        echo -e "  ${RED}✗${NC} http://${PUBLIC_IP}:${FRONTEND_PORT}/api/health"
    fi
    
    # Full health response
    echo ""
    echo "Health details:"
    if curl -s "http://${PUBLIC_IP}:${FRONTEND_PORT}/api/health" 2>/dev/null | grep -q status; then
        curl -s "http://${PUBLIC_IP}:${FRONTEND_PORT}/api/health" | python3 -m json.tool 2>/dev/null || \
            curl -s "http://${PUBLIC_IP}:${FRONTEND_PORT}/api/health"
    else
        echo "  (Health endpoint not responding)"
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# Full Status Report
# ════════════════════════════════════════════════════════════════════════════════

show_full_status() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Deployment Status Report${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Configuration:"
    echo "  Host:          ${PUBLIC_HOST} (${PUBLIC_IP})"
    echo "  Frontend URL:  http://${PUBLIC_IP}:${FRONTEND_PORT}"
    echo "  Backend API:   http://${PUBLIC_IP}:${FRONTEND_PORT}/api"
    echo ""
    
    show_health
    echo ""
    
    show_docker_status
    echo ""
    
    show_system_resources
}

# ════════════════════════════════════════════════════════════════════════════════
# Real-time Monitoring
# ════════════════════════════════════════════════════════════════════════════════

watch_containers() {
    echo -e "${BLUE}Watching containers (Ctrl+C to stop)...${NC}"
    echo ""
    
    while true; do
        clear
        ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<'SSHSCRIPT'
cd ~/V12_Project/deploy/docker
echo "Timestamp: $(date)"
echo ""
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
SSHSCRIPT
        sleep 5
    done
}

# ════════════════════════════════════════════════════════════════════════════════
# Help
# ════════════════════════════════════════════════════════════════════════════════

show_help() {
    cat <<'EOF'
Cloud Deployment Monitoring Script

Usage: bash monitor.sh [COMMAND] [OPTIONS]

COMMANDS:
  status                Show container and system status
  logs [service] [n]    Show last n lines of logs (default: backend, 20 lines)
  health                Show application health status
  resources             Show system resource usage
  watch                 Real-time container resource usage (like docker stats)

EXAMPLES:
  Current deployment status:
    bash monitor.sh status

  View backend logs (last 50 lines):
    bash monitor.sh logs backend 50

  View all container logs:
    bash monitor.sh logs all 20

  Watch resource usage (refreshes every 5s):
    bash monitor.sh watch

  Check if application is healthy:
    bash monitor.sh health
EOF
}

# ════════════════════════════════════════════════════════════════════════════════
# Main
# ════════════════════════════════════════════════════════════════════════════════

case $COMMAND in
    status)
        show_full_status
        ;;
    health)
        show_health
        ;;
    logs)
        show_logs "$DETAIL" "${3:-20}"
        ;;
    resources)
        show_system_resources
        ;;
    watch)
        watch_containers
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        show_help
        exit 1
        ;;
esac
