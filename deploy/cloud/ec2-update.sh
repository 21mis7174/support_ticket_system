#!/bin/bash
# Quick Redeploy Script - Deploy code changes to already-setup EC2 instance
# RULE IT-07: Supports partial transfers (--backend or --frontend)
# RULE IT-08, IT-09: Ensures transfer integrity and cleanup
# Faster than deploy.sh for routine updates (no EC2 setup, just rebuild + transfer)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"
DOCKER_DIR="$PROJECT_DIR/deploy/docker"

# Source config
if [ ! -f "$SCRIPT_DIR/ec2-config.env" ]; then
    echo -e "${RED}✗ Error: ec2-config.env not found${NC}"
    exit 1
fi

source "$SCRIPT_DIR/ec2-config.env"

# Parse arguments
DEPLOY_TARGET="both"  # both, backend, frontend
SKIP_BUILD=false
CONFIG_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --backend)
            DEPLOY_TARGET="backend"
            ;;
        --frontend)
            DEPLOY_TARGET="frontend"
            ;;
        --config)
            CONFIG_ONLY=true
            ;;
        --skip-build)
            SKIP_BUILD=true
            ;;
        --help)
            cat <<'EOF'
Usage: bash ec2-update.sh [OPTIONS]

Fast redeployment for code changes (no EC2 setup needed).

OPTIONS:
  --backend       Deploy only backend service
  --frontend      Deploy only frontend service
  --config        Only update config (no rebuild, no image transfer)
  --skip-build    Skip local build (use existing images)
  --help          Show this help

EXAMPLES:
  Full rebuild of both services:
    bash ec2-update.sh

  Update only backend after code change:
    bash ec2-update.sh --backend

  Update only frontend after code change:
    bash ec2-update.sh --frontend

  Update only configuration (api_keys.json, env vars):
    bash ec2-update.sh --config

  Use pre-built images (don't rebuild):
    bash ec2-update.sh --skip-build
EOF
            exit 0
            ;;
    esac
    shift
done

log_step() {
    echo -e "${BLUE}[${1}]${NC} ${2}"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Quick Redeploy Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Deploy target: $DEPLOY_TARGET"
echo "Config only:   $CONFIG_ONLY"
echo "Skip build:    $SKIP_BUILD"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# CONFIG-ONLY MODE: Just copy config and restart
# ════════════════════════════════════════════════════════════════════════════════

if [ "$CONFIG_ONLY" = true ]; then
    log_step "1" "Copying configuration files to EC2..."
    
    # Copy api_keys.json if it exists
    if [ -f "$PROJECT_DIR/backend/config/api_keys.json" ]; then
        scp $SSH_OPTIONS -i "$EC2_PEM" \
            "$PROJECT_DIR/backend/config/api_keys.json" \
            "$EC2_USER@$EC2_HOST:~/V12_Project/backend/config/api_keys.json"
        log_success "api_keys.json copied"
    fi
    
    # Sync compose file
    scp $SSH_OPTIONS -i "$EC2_PEM" \
        "$DOCKER_DIR/docker-compose.yml" \
        "$EC2_USER@$EC2_HOST:~/V12_Project/deploy/docker/docker-compose.yml"
    log_success "docker-compose.yml synced"
    
    log_step "2" "Restarting containers..."
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<'SSHSCRIPT'
cd ~/V12_Project/deploy/docker
docker compose restart
sleep 3
docker compose ps
SSHSCRIPT
    
    log_success "Containers restarted"
    echo ""
    echo -e "${GREEN}✓ Config update complete!${NC}"
    exit 0
fi

# ════════════════════════════════════════════════════════════════════════════════
# STANDARD MODE: Build, transfer, restart
# ════════════════════════════════════════════════════════════════════════════════

log_step "1" "Building images locally..."

cd "$DOCKER_DIR"
export DOCKER_BUILDKIT=1

if [ "$SKIP_BUILD" = false ]; then
    case $DEPLOY_TARGET in
        backend)
            if ! docker build -f "$PROJECT_DIR/backend/Dockerfile" \
                 -t docker-backend:latest "$PROJECT_DIR/backend"; then
                log_error "Backend build failed"
                exit 1
            fi
            ;;
        frontend)
            if ! docker build -f "$PROJECT_DIR/frontend/Dockerfile" \
                 -t docker-frontend:latest "$PROJECT_DIR/frontend"; then
                log_error "Frontend build failed"
                exit 1
            fi
            ;;
        both)
            if ! docker compose build --progress=plain; then
                log_error "Build failed"
                exit 1
            fi
            ;;
    esac
    log_success "Build complete"
else
    log_success "Skipping build (--skip-build)"
fi

# Save and transfer images
log_step "2" "Saving and transferring images..."

case $DEPLOY_TARGET in
    backend)
        docker save docker-backend:latest | gzip > "$ARCHIVE_PATH"
        echo "  Backend image size: $(du -h $ARCHIVE_PATH | cut -f1)"
        ;;
    frontend)
        docker save docker-frontend:latest | gzip > "$ARCHIVE_PATH"
        echo "  Frontend image size: $(du -h $ARCHIVE_PATH | cut -f1)"
        ;;
    both)
        docker save docker-backend:latest docker-frontend:latest | gzip > "$ARCHIVE_PATH"
        echo "  Archive size: $(du -h $ARCHIVE_PATH | cut -f1)"
        ;;
esac

if ! scp $SSH_OPTIONS -i "$EC2_PEM" "$ARCHIVE_PATH" "$EC2_USER@$EC2_HOST:/tmp/v12-images.tar.gz"; then
    log_error "Transfer failed"
    rm -f "$ARCHIVE_PATH"
    exit 1
fi

# Load on EC2
if ! ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" \
     "gunzip -c /tmp/v12-images.tar.gz | docker load"; then
    log_error "Failed to load images on EC2"
    exit 1
fi

ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" "rm -f /tmp/v12-images.tar.gz"
rm -f "$ARCHIVE_PATH"

log_success "Images transferred successfully"

# Restart services on EC2
log_step "3" "Restarting containers on EC2..."

ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<SSHSCRIPT
cd ~/V12_Project/deploy/docker

# Prune old images
docker image prune -f > /dev/null 2>&1

# Restart services
case $DEPLOY_TARGET in
    backend)
        docker compose up -d --no-build backend
        ;;
    frontend)
        docker compose up -d --no-build frontend
        ;;
    both)
        docker compose down --remove-orphans > /dev/null 2>&1
        docker compose up -d --no-build
        ;;
esac

sleep 5
docker compose ps
SSHSCRIPT

log_success "Containers restarted"

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Redeploy Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Verify:"
echo "  curl http://${PUBLIC_IP}:${FRONTEND_PORT}/health"
echo "  ssh -i '$EC2_PEM' $EC2_USER@$EC2_HOST 'docker ps'"
echo ""
