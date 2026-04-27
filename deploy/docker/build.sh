#!/bin/bash
# Build script for optimized Docker images
# Uses BuildKit for better caching and parallel builds
# RULE-P012: Use BuildKit for faster builds

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="${PROJECT_ROOT:-.}"
REGISTRY_PREFIX="${REGISTRY_PREFIX:-}" # e.g., "myregistry/" or empty for local builds

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Docker Image Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Verify docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Enable BuildKit (required for syntax=docker/dockerfile:1, cache mounts, etc.)
export DOCKER_BUILDKIT=1

echo -e "${BLUE}Building backend image...${NC}"
docker build \
    --file "${PROJECT_ROOT}/deploy/docker/Dockerfile.backend" \
    --tag "${REGISTRY_PREFIX}support_tickets_backend:latest" \
    --tag "${REGISTRY_PREFIX}support_tickets_backend:buildcache" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --progress=plain \
    "${PROJECT_ROOT}/backend"
echo -e "${GREEN}✓ Backend image built${NC}"
echo ""

echo -e "${BLUE}Building frontend image...${NC}"
docker build \
    --file "${PROJECT_ROOT}/deploy/docker/Dockerfile.frontend" \
    --tag "${REGISTRY_PREFIX}support_tickets_frontend:latest" \
    --tag "${REGISTRY_PREFIX}support_tickets_frontend:buildcache" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    --progress=plain \
    "${PROJECT_ROOT}/frontend"
echo -e "${GREEN}✓ Frontend image built${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All images built successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Show image sizes
echo -e "${BLUE}Image sizes:${NC}"
docker images | grep support_tickets | awk '{printf "%-40s %10s\n", $1":"$2, $7}'
echo ""

# Suggest next steps
echo -e "${BLUE}Next steps:${NC}"
echo "1. Create .env file from .env.example:"
echo "   cp ${PROJECT_ROOT}/deploy/docker/.env.example ${PROJECT_ROOT}/deploy/docker/.env"
echo ""
echo "2. Update .env with your configuration"
echo ""
echo "3. Start containers:"
echo "   cd ${PROJECT_ROOT}/deploy/docker"
echo "   docker-compose -f docker-compose.yml up -d"
echo ""
