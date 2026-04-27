#!/bin/bash
# Main Deployment Script - Orchestrates full deployment to EC2
# RULE IT-01: Ensures every step in the pipeline succeeds
# RULE IT-05: Saves BOTH images together  
# RULE DR-05: Uses restart: unless-stopped for auto-restart
# RULE EP-01, EP-02: Generates .env with proper values for EC2

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"
DOCKER_DIR="$PROJECT_DIR/deploy/docker"

# Source configuration
if [ ! -f "$SCRIPT_DIR/ec2-config.env" ]; then
    echo -e "${RED}✗ Error: ec2-config.env not found in $SCRIPT_DIR${NC}"
    echo "  Create it from the template: cp ec2-config.env.example ec2-config.env"
    exit 1
fi

source "$SCRIPT_DIR/ec2-config.env"

# Parse arguments
MODE="${1:-default}"
SKIP_BUILD=false
SKIP_TRANSFER=false
SETUP_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --setup)
            SETUP_ONLY=true
            ;;
        --skip-build)
            SKIP_BUILD=true
            ;;
        --skip-transfer)
            SKIP_TRANSFER=true
            ;;
        --help)
            show_help
            exit 0
            ;;
    esac
    shift
done

# ════════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ════════════════════════════════════════════════════════════════════════════════

show_help() {
    cat <<EOF
Usage: bash deploy.sh [OPTIONS]

OPTIONS:
  --setup           First-time deployment: setup EC2, build, transfer, start
  --skip-build      Transfer pre-built images without rebuilding
  --skip-transfer   Skip image transfer (images already on EC2)
  --help            Show this help message

EXAMPLES:
  First-time deployment:
    bash deploy.sh --setup

  Standard redeployment (rebuild everything):
    bash deploy.sh

  Quick update (skip rebuild, use existing images):
    bash deploy.sh --skip-build

Default mode builds, transfers, and starts containers.
EOF
}

log_step() {
    local step=$1
    local message=$2
    echo -e "${BLUE}[${step}]${NC} ${message}"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Validate SSH access
validate_ssh() {
    log_step "1" "Validating SSH access..."
    if ! ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" "echo ok" > /dev/null 2>&1; then
        log_error "SSH connection failed"
        echo "  Check: EC2_USER, EC2_HOST, EC2_PEM in ec2-config.env"
        echo "  Test: ssh -i '$EC2_PEM' $EC2_USER@$EC2_HOST"
        exit 1
    fi
    log_success "SSH connection successful"
}

# Run EC2 setup (first-time only)
run_ec2_setup() {
    log_step "2" "Running EC2 setup (installing Docker, etc)..."
    if [ ! -f "$SCRIPT_DIR/ec2-setup.sh" ]; then
        log_error "ec2-setup.sh not found"
        exit 1
    fi
    
    # Transfer and run setup script
    scp $SSH_OPTIONS -i "$EC2_PEM" "$SCRIPT_DIR/ec2-setup.sh" "$EC2_USER@$EC2_HOST:/tmp/ec2-setup.sh"
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" "bash /tmp/ec2-setup.sh"
    log_success "EC2 setup complete"
    echo ""
    echo -e "${YELLOW}IMPORTANT: Log out of SSH and back in for docker group changes to take effect${NC}"
    echo "  ssh -i '$EC2_PEM' $EC2_USER@$EC2_HOST"
    echo ""
}

# Clone/update project on EC2
update_project_on_ec2() {
    log_step "3" "Ensuring project exists on EC2..."
    
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<'SSHSCRIPT'
if [ -d ~/V12_Project/.git ]; then
    cd ~/V12_Project
    git fetch origin
    git reset --hard origin/main
else
    git clone https://github.com/21mis7174/support_ticket_system.git ~/V12_Project
fi
SSHSCRIPT
    
    log_success "Project synced on EC2"
}

# Build Docker images locally
build_images_locally() {
    if [ "$SKIP_BUILD" = true ]; then
        log_step "4" "Skipping local build (--skip-build)"
        return
    fi
    
    log_step "4" "Building Docker images locally..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker not found locally"
        exit 1
    fi
    
    cd "$DOCKER_DIR"
    
    # Enable BuildKit for better caching
    export DOCKER_BUILDKIT=1
    
    # Build both images
    if docker compose build --progress=plain 2>&1 | tee /tmp/build.log; then
        log_success "Images built successfully"
        
        # Check image sizes
        echo "Image sizes:"
        docker images | grep "docker-" | awk '{printf "  %-25s %s\n", $1":"$2, $7}'
    else
        log_error "Docker build failed"
        tail -20 /tmp/build.log
        exit 1
    fi
}

# Transfer images to EC2
transfer_images_to_ec2() {
    if [ "$SKIP_TRANSFER" = true ]; then
        log_step "5" "Skipping image transfer (--skip-transfer)"
        return
    fi
    
    log_step "5" "Transferring images to EC2..."
    
    cd "$DOCKER_DIR"
    
    # Save images
    echo "  Saving images..."
    if ! docker save docker-backend:latest docker-frontend:latest | \
         gzip > "$ARCHIVE_PATH"; then
        log_error "Failed to save images"
        exit 1
    fi
    
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    echo "  Archive size: $ARCHIVE_SIZE"
    
    # Transfer archive
    echo "  Transferring to EC2:/tmp/v12-images.tar.gz..."
    if ! scp $SSH_OPTIONS -i "$EC2_PEM" "$ARCHIVE_PATH" "$EC2_USER@$EC2_HOST:/tmp/v12-images.tar.gz"; then
        log_error "SCP transfer failed"
        rm -f "$ARCHIVE_PATH"
        exit 1
    fi
    
    # Load images on EC2
    echo "  Loading images on EC2..."
    if ! ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" \
         "gunzip -c /tmp/v12-images.tar.gz | docker load"; then
        log_error "Failed to load images on EC2"
        exit 1
    fi
    
    # Cleanup
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" "rm -f /tmp/v12-images.tar.gz"
    rm -f "$ARCHIVE_PATH"
    
    log_success "Images transferred and loaded successfully"
}

# Generate .env on EC2 (RULE EP-01, EP-02)
generate_env_on_ec2() {
    log_step "6" "Generating .env file on EC2..."
    
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<SSHENV
cat > ~/V12_Project/deploy/docker/.env <<'ENVEOF'
# Generated by deploy.sh - $(date)
# RULE EP-01: Contains EC2-specific values, not localhost
# WARNING: Do not commit .env to git!

MONGO_USERNAME=${MONGO_USERNAME}
MONGO_PASSWORD=${MONGO_PASSWORD}
MONGO_DB=${MONGO_DB}
MONGO_PORT=${MONGO_PORT}

FRONTEND_PORT=${FRONTEND_PORT}
BACKEND_PORT=${BACKEND_PORT}

PUBLIC_HOST=${PUBLIC_HOST}
PUBLIC_IP=${PUBLIC_IP}

NODE_ENV=${NODE_ENV}
TZ=${TZ}
LOG_LEVEL=${LOG_LEVEL}

NEXT_PUBLIC_API_URL=http://${PUBLIC_HOST}:${FRONTEND_PORT}

ENVEOF

chmod 600 ~/V12_Project/deploy/docker/.env
SSHENV
    
    log_success ".env generated on EC2"
}

# Start containers on EC2
start_containers_on_ec2() {
    log_step "7" "Starting containers on EC2..."
    
    ssh $SSH_OPTIONS -i "$EC2_PEM" "$EC2_USER@$EC2_HOST" bash <<'SSHSTART'
cd ~/V12_Project/deploy/docker

# Clean up old images (RULE IT-13)
docker image prune -f > /dev/null 2>&1

# Stop old containers if running
docker compose down --remove-orphans > /dev/null 2>&1

# Start new containers (--no-build: don't try to build on EC2)
docker compose up -d --no-build

# Wait for containers to become healthy
echo "Waiting for containers to become healthy..."
sleep 10

# Show status
docker compose ps
SSHSTART
    
    log_success "Containers started on EC2"
}

# Health check
perform_health_check() {
    log_step "8" "Performing health check..."
    
    # Try health endpoint
    for i in {1..5}; do
        if curl -s -f "http://${PUBLIC_IP}:${FRONTEND_PORT}/health" > /dev/null; then
            log_success "Application is healthy"
            return 0
        fi
        if [ $i -lt 5 ]; then
            echo "  Attempt $i/5 failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    log_error "Health check failed after 5 attempts"
    echo "  Try: curl http://${PUBLIC_IP}:${FRONTEND_PORT}/health"
    echo "  Or: ssh -i '$EC2_PEM' $EC2_USER@$EC2_HOST 'docker compose -f ~/V12_Project/deploy/docker/docker-compose.yml logs'"
    return 1
}

# ════════════════════════════════════════════════════════════════════════════════
# Main Deployment Flow
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}V12 Application Deployment Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Show configuration
echo "Configuration:"
echo "  EC2_USER:      $EC2_USER"
echo "  EC2_HOST:      $EC2_HOST"
echo "  FRONTEND_PORT: $FRONTEND_PORT"
echo "  BACKEND_PORT:  $BACKEND_PORT"
echo "  PUBLIC_IP:     $PUBLIC_IP"
echo ""

# Main flow
validate_ssh

if [ "$SETUP_ONLY" = true ]; then
    run_ec2_setup
    exit 0
fi

update_project_on_ec2
build_images_locally
transfer_images_to_ec2
generate_env_on_ec2
start_containers_on_ec2

# Health check (optional, continue even if it fails)
if ! perform_health_check; then
    echo -e "${YELLOW}Warning: Health check didn't complete, but deployment may still succeed${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Application is running at:"
echo "  Frontend: http://${PUBLIC_IP}:${FRONTEND_PORT}"
echo "  Backend API: http://${PUBLIC_IP}:${FRONTEND_PORT}/api"
echo ""
echo "Useful commands:"
echo "  View logs:       ssh -i '$EC2_PEM' $EC2_USER@$EC2_HOST 'cd ~/V12_Project/deploy/docker && docker compose logs -f'"
echo "  Check status:    ssh -i '$EC2_PEM' $EC2_USER@$EC2_HOST 'docker ps'"
echo "  Health check:    curl http://${PUBLIC_IP}:${FRONTEND_PORT}/health"
echo "  Quick restart:   ssh -i '$EC2_PEM' $EC2_USER@$EC2_HOST 'cd ~/V12_Project/deploy/docker && docker compose restart'"
echo ""
