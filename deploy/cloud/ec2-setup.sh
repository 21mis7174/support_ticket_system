#!/bin/bash
# EC2 Setup Script - Initialize a fresh EC2 instance for application deployment
# RULE DR-01: Uses dnf for Amazon Linux 2023 Docker installation
# RULE DR-02: Installs Docker Compose as CLI plugin (docker compose, not docker-compose)
# RULE DR-03: Adds ec2-user to docker group (no sudo for docker commands)
# RULE DR-04: Enables Docker to auto-start on EC2 reboot

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}EC2 Instance Setup Script${NC}"
echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
echo "This script initializes a fresh EC2 instance for Docker deployment"
echo ""

# Check if running on EC2
if ! curl -s --connect-timeout 1 http://169.254.169.254/latest/meta-data/instance-id &> /dev/null; then
    echo -e "${YELLOW}Warning: Not detected as running on EC2 (metadata not available)${NC}"
fi

# ════════════════════════════════════════════════════════════════════════════════
# STEP 1: Update system packages
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[1/7]${NC} Updating system packages..."
sudo dnf update -y --quiet > /dev/null 2>&1 || sudo yum update -y --quiet > /dev/null 2>&1
echo -e "${GREEN}✓${NC} System packages updated"

# ════════════════════════════════════════════════════════════════════════════════
# STEP 2: Install Docker
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[2/7]${NC} Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo dnf install -y docker --quiet > /dev/null 2>&1 || sudo yum install -y docker --quiet > /dev/null 2>&1
    echo -e "${GREEN}✓${NC} Docker installed"
else
    echo -e "${GREEN}✓${NC} Docker already installed"
fi

# ════════════════════════════════════════════════════════════════════════════════
# STEP 3: Install Docker Compose CLI Plugin
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[3/7]${NC} Installing Docker Compose..."
DOCKER_COMPOSE_PLUGIN="/usr/local/lib/docker/cli-plugins/docker-compose"
if [ ! -f "$DOCKER_COMPOSE_PLUGIN" ]; then
    # Download latest Docker Compose release
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o "$DOCKER_COMPOSE_PLUGIN" 2>/dev/null
    sudo chmod +x "$DOCKER_COMPOSE_PLUGIN"
    echo -e "${GREEN}✓${NC} Docker Compose installed (version ${COMPOSE_VERSION})"
else
    echo -e "${GREEN}✓${NC} Docker Compose already installed"
fi

# Verify docker compose command works
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗${NC} docker compose command failed. Trying alternative installation..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /tmp/docker-compose
    sudo mv /tmp/docker-compose "$DOCKER_COMPOSE_PLUGIN"
    sudo chmod +x "$DOCKER_COMPOSE_PLUGIN"
fi

# ════════════════════════════════════════════════════════════════════════════════
# STEP 4: Start Docker daemon and enable auto-start
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[4/7]${NC} Configuring Docker daemon..."
sudo systemctl start docker
sudo systemctl enable docker > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Docker daemon running and enabled on boot"

# ════════════════════════════════════════════════════════════════════════════════
# STEP 5: Add ec2-user to docker group (no sudo for docker commands)
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[5/7]${NC} Configuring docker group permissions..."
if ! id -Gn ec2-user | grep -q docker; then
    sudo usermod -aG docker ec2-user
    echo -e "${GREEN}✓${NC} Added ec2-user to docker group (log out and back in for effect)"
else
    echo -e "${GREEN}✓${NC} ec2-user already in docker group"
fi

# ════════════════════════════════════════════════════════════════════════════════
# STEP 6: Install useful system tools
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[6/7]${NC} Installing system utilities..."
sudo dnf install -y git curl wget htop --quiet > /dev/null 2>&1 \
    || sudo yum install -y git curl wget htop --quiet > /dev/null 2>&1
echo -e "${GREEN}✓${NC} System utilities installed"

# ════════════════════════════════════════════════════════════════════════════════
# STEP 7: Create storage directories
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${BLUE}[7/7]${NC} Creating storage directories..."
STORAGE_BASE="/home/ec2-user/V12_Project/storage"
mkdir -p "$STORAGE_BASE"/{logs,sqlite,cache,instruments}
# Set proper permissions so containers can write
chmod 755 "$STORAGE_BASE"
chmod 755 "$STORAGE_BASE"/{logs,sqlite,cache,instruments}
echo -e "${GREEN}✓${NC} Storage directories created"

# ════════════════════════════════════════════════════════════════════════════════
# Final Status
# ════════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ EC2 Instance Setup Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Verification commands:"
echo "  docker --version"
echo "  docker compose version"
echo "  docker ps"
echo ""
echo "IMPORTANT: Log out and back in for docker group changes to take effect:"
echo "  exit  (or disconnect from SSH)"
echo "  ssh back in"
echo "  docker ps  (should work without sudo)"
echo ""
echo "Next steps:"
echo "  1. Clone the project: git clone https://github.com/21mis7174/support_ticket_system.git ~/V12_Project"
echo "  2. Copy .env: cp ~/V12_Project/deploy/docker/.env.example ~/V12_Project/deploy/docker/.env"
echo "  3. Check config: cat ~/V12_Project/deploy/docker/.env"
echo "  4. Start services: cd ~/V12_Project/deploy/docker && docker compose up -d"
echo ""
