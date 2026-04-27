# Cloud Deployment Guide

Complete guide for deploying the Support Ticket System to AWS EC2. Follows all enterprise best practices from the cloud deployment rules.

## Quick Start

### First-Time Deployment (5-10 minutes)

```bash
cd deploy/cloud

# 1. Configure your EC2 instance details
cp ec2-config.env.example ec2-config.env
# Edit ec2-config.env with your EC2 host, IP, PEM key path

# 2. Run deployment (handles everything)
bash deploy.sh --setup
```

### Standard Redeployment (for code updates)

```bash
cd deploy/cloud
bash ec2-update.sh        # Full rebuild
# or
bash ec2-update.sh --backend   # Only backend changed
bash ec2-update.sh --frontend  # Only frontend changed
```

## Configuration

### ec2-config.env Template

Create `ec2-config.env` with your EC2 details:

```bash
# EC2 connection
EC2_USER=ec2-user
EC2_HOST=ec2-13-232-0-240.ap-south-1.compute.amazonaws.com
EC2_PEM=/path/to/your.pem
REMOTE_PROJECT_DIR=/home/ec2-user/V12_Project

# Ports
FRONTEND_PORT=5000
BACKEND_PORT=5001

# Public network (RULE EP-04: needed for CORS)
PUBLIC_HOST=ec2-13-232-0-240.ap-south-1.compute.amazonaws.com
PUBLIC_IP=13.232.0.240

# MongoDB
MONGO_USERNAME=mongo
MONGO_PASSWORD=mongopass  # CHANGE THIS!
MONGO_DB=support_tickets
```

### Finding EC2 Details

```bash
# Public IP and hostname
aws ec2 describe-instances \
  --instance-ids i-1234567890abcdef0 \
  --query 'Reservations[0].Instances[0].{PublicIP:PublicIpAddress,Hostname:PublicDnsName}'

# Or manually in AWS Console:
# EC2 Dashboard → Your Instance → Public IPv4 address / Public IPv4 DNS
```

## Deployment Scripts

### `deploy.sh` - Full Deployment Orchestrator

Handles entire deployment pipeline: validate → setup EC2 → build → transfer → start

```bash
# First-time setup (includes EC2 setup)
bash deploy.sh --setup

# Standard redeployment
bash deploy.sh

# Skip rebuild (use existing images)
bash deploy.sh --skip-build

# Skip transfer (images already on EC2)
bash deploy.sh --skip-transfer
```

**What it does:**
1. Validates SSH access to EC2
2. Optionally runs EC2 setup (install Docker, etc.)
3. Builds Docker images locally
4. Transfers images to EC2 via scp + gunzip
5. Generates `.env` file on EC2 (RULE EP-01)
6. Starts containers with health checks
7. Verifies application is healthy

**Time:** ~5 minutes (includes 1-2 min build, 1-2 min transfer, 10s startup)

### `ec2-update.sh` - Fast Redeployment

For code changes when EC2 is already setup. Skips EC2 initialization.

```bash
# Rebuild both services
bash ec2-update.sh

# Only backend changed
bash ec2-update.sh --backend

# Only frontend changed  
bash ec2-update.sh --frontend

# Only config changed (no rebuild)
bash ec2-update.sh --config

# Use pre-built images
bash ec2-update.sh --skip-build
```

**Time:** 1-2 minutes (much faster than full deploy.sh)

### `monitor.sh` - Health & Monitoring

Real-time monitoring and troubleshooting:

```bash
# Full status report
bash monitor.sh status

# Application health
bash monitor.sh health

# View logs (last 20 lines)
bash monitor.sh logs backend 20
bash monitor.sh logs frontend 50
bash monitor.sh logs all 30

# Watch resource usage (like docker stats)
bash monitor.sh watch

# System resources on EC2
bash monitor.sh resources
```

### `ec2-setup.sh` - EC2 Initialization

Run on fresh EC2 instance to install Docker, Docker Compose, etc.

Normally called automatically by `deploy.sh --setup`, but can run manually:

```bash
# Transfer and run
scp -i your.pem ec2-setup.sh ec2-user@ec2-host:/tmp/
ssh -i your.pem ec2-user@ec2-host "bash /tmp/ec2-setup.sh"

# Then log out and back in for docker group changes to take effect
```

## Deployment Flow

### First-Time Deployment

```
Local Machine                              EC2 Instance
                                           (Fresh instance, Docker not installed)
                                           
1. Check SSH access ─────────────────→ Check if reachable
   
2. Run EC2 setup ────────────────────→ Install Docker + Compose
                                        Enable Docker auto-start
                                        Add ec2-user to docker group
                                        Create storage directories
                                        ← Deployment paused: log out/back in

3. Update project on EC2────────────→ Clone/pull latest from GitHub

4. Build images locally
   docker compose build
   
5. Save images ─────────────────────→ Transfer via scp
   docker save | gzip
   
6. Load on EC2 ─────────────────────→ gunzip | docker load

7. Generate .env on EC2────────────→ With PUBLIC_HOST, PUBLIC_IP
                                        (RULE EP-01: not localhost)
   
8. Start containers ────────────────→ docker compose up -d --no-build

9. Health check ────────────────────→ curl http://EC2:5000/health
                                        
                                        ← Success! Application running
```

### Standard Redeployment (Code Changes)

```
Local Machine                              EC2 Instance
                                           (Already setup)

1. Verify Docker    docker ps
   
2. Build locally    docker compose build
   
3. Save images      docker save | gzip
   
4. Transfer via scp ────────────────→ /tmp/v12-images.tar.gz

5. Load images ─────────────────────→ gunzip | docker load

6. Restart containers ──────────────→ docker compose down
                                        docker compose up -d --no-build
                                        
                                        ← Redeployment complete
```

## Deployment Checklist

### Pre-Deployment (on your machine)

- [ ] Local Docker works: `cd deploy/docker && docker compose up -d`
- [ ] EC2 instance is running (check AWS Console)
- [ ] ec2-config.env exists with correct values
- [ ] SSH access verified: `ssh -i $PEM ec2-user@$EC2_HOST "echo ok"`
- [ ] Security group allows:
  - Port 22 (SSH) from your IP
  - Port 5000 (frontend) from 0.0.0.0/0
- [ ] api_keys.json exists in backend/config/
- [ ] No syntax errors: `cd deploy/docker && docker compose config > /dev/null`

### During Deployment

- [ ] `deploy.sh` shows "✓ SSH connection successful"
- [ ] Docker build completes without errors
- [ ] Image transfer shows "✓ Images transferred"
- [ ] Containers start: "✓ Containers started"
- [ ] Health check passes: "✓ Health check passed" (or continues even if delayed)

### Post-Deployment

- [ ] Access frontend: http://{PUBLIC_IP}:5000
- [ ] API works: http://{PUBLIC_IP}:5000/api/health
- [ ] Check containers: `bash monitor.sh status`
- [ ] View logs: `bash monitor.sh logs backend 50`
- [ ] Monitor resources: `bash monitor.sh watch`

## Troubleshooting

### SSH Connection Fails

```bash
# Check SSH config
ssh -v -i $PEM ec2-user@$EC2_HOST "echo ok"

# Verify PEM path is correct in ec2-config.env
cat ec2-config.env | grep EC2_PEM

# Check PEM permissions
ls -l ~/.aws_keys/*.pem  # Should be 600

# Check security group
# AWS Console → EC2 → Security Groups → Inbound → Port 22 from your IP
```

### Docker Build Fails

```bash
# Clean and retry
docker image prune -a -f
docker compose build --no-cache

# Check disk space
docker system df

# Check build logs
docker compose build 2>&1 | tail -50
```

### Images Fail to Transfer

```bash
# Check SSH connection
ssh -i $PEM ec2-user@$EC2_HOST "df -h /tmp"  # 350MB needed

# Verify disk space on EC2
bash monitor.sh resources

# Try manual transfer
scp -i $PEM /tmp/v12-images.tar.gz ec2-user@$EC2_HOST:/tmp/

# Check archive integrity
du -h /tmp/v12-images.tar.gz
docker image ls | grep docker-  # Verify images exist locally
```

### Containers Won't Start

```bash
# Check logs
bash monitor.sh logs

# Manual check on EC2
ssh -i $PEM ec2-user@$EC2_HOST
cd ~/V12_Project/deploy/docker
docker compose logs backend
docker compose logs frontend
docker compose logs mongo

# Restart manually
docker compose down
docker compose up -d --no-build

# Check if images exist
docker images | grep docker-
```

### Application Unreachable

```bash
# Check health
bash monitor.sh health

# Verify port is open
curl -v http://{PUBLIC_IP}:5000

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Manually on EC2
netstat -tlnp | grep 5000
docker ps

# Check container logs
bash monitor.sh logs all 50
```

### Out of Memory (OOM)

```bash
# Check memory usage
bash monitor.sh resources

# See which container crashed
bash monitor.sh logs

# If OOM, upgrade EC2 instance type:
# t2.micro (1GB) → t3.small (2GB) or larger

# Or reduce application memory:
# Edit backend code to process smaller datasets
# Reduce log retention
```

### Disk Full

```bash
# Check disk space
bash monitor.sh resources

# Clean up images
ssh -i $PEM ec2-user@$EC2_HOST "docker system prune -f"

# Clean old logs
ssh -i $PEM ec2-user@$EC2_HOST "rm ~/V12_Project/storage/logs/*.bak"

# If still full, expand EBS volume via AWS Console
```

## Best Practices

### RULE EP-01: Never Use localhost in Production Config

✅ Correct:
```bash
PUBLIC_HOST=ec2-13-232-0-240.region.compute.amazonaws.com
PUBLIC_IP=13.232.0.240
CORS_ORIGINS=${PUBLIC_HOST},${PUBLIC_IP}
```

❌ Wrong:
```bash
PUBLIC_HOST=localhost
PUBLIC_IP=127.0.0.1
```

### RULE IT-02: Ensure Architecture Matches

```bash
# Check local machine
uname -m  # Should print x86_64

# Check local image
docker inspect docker-backend:latest | grep Architecture

# Check EC2 (if it has Docker already)
ssh -i $PEM ec2-user@$EC2_HOST "uname -m"

# If different, rebuild with explicit platform
docker buildx build --platform linux/amd64 -f Dockerfile.backend backend/
```

### RULE IT-05: Transfer Both Images Together

```bash
# ✅ Correct: Both images in one archive
docker save docker-backend:latest docker-frontend:latest | gzip

# ❌ Wrong: Transferring only one
docker save docker-backend:latest | gzip  # Frontend stays old!
```

### RULE DR-04: Auto-Restart on Reboot

Containers automatically restart after EC2 reboot because:
1. Docker daemon is enabled: `systemctl enable docker`
2. Containers have policy: `restart: unless-stopped`
3. After reboot: Docker starts → containers auto-start

No manual intervention needed!

### RULE DR-15: Monitor Disk Usage

```bash
# Regularly check
bash monitor.sh resources

# Clean up old images
ssh -i $PEM ec2-user@$EC2_HOST "docker system prune -f"

# Archive logs if they grow large
ssh -i $PEM ec2-user@$EC2_HOST "gzip ~/V12_Project/storage/logs/*.log"
```

## Monitoring Commands

### Real-Time Updates

```bash
# Live resource usage (updates every 5s)
bash monitor.sh watch

# Live logs
ssh -i $PEM ec2-user@$EC2_HOST "cd ~/V12_Project/deploy/docker && docker compose logs -f"

# Live health
while true; do curl -s http://{PUBLIC_IP}:5000/health | jq .; sleep 5; done
```

### Periodic Checks

```bash
# Health status
bash monitor.sh health

# Container status
bash monitor.sh status

# Full report
bash monitor.sh status

# Resource usage
bash monitor.sh resources
```

## Maintenance

### Updating Application Code

```bash
# 1. Make changes locally
# 2. Test in local Docker
cd deploy/docker && docker compose up -d
# 3. Commit to git
git add -A && git commit -m "Feature: xyz"
git push

# 4. Deploy to EC2 (with rebuild)
bash ec2-update.sh

# 5. Verify
bash monitor.sh health
```

### Adding New Dependencies

```bash
# Python package
pip install <package>
pip freeze | grep <package> >> backend/requirements.txt
git add -A && git commit -m "Add package"
bash ec2-update.sh --backend

# npm package  
npm install <package> --prefix frontend
git add -A && git commit -m "Add package"
bash ec2-update.sh --frontend
```

### Upgrading EC2 Instance Type

```bash
# If running out of resources (t2.micro is only 1GB RAM)

# 1. Stop instance (AWS Console)
# 2. Change instance type (t2.micro → t3.small)
# 3. Start instance
# 4. Update ec2-config.env with new PUBLIC_IP if it changed
# 5. Verify containers restarted
ssh -i $PEM ec2-user@$EC2_HOST "docker ps"
```

### Rotating Credentials

```bash
# 1. Update backend/config/api_keys.json locally
# 2. Test locally
cd deploy/docker && docker compose restart backend

# 3. Deploy only config
bash ec2-update.sh --config

# 4. Verify
bash monitor.sh health
```

### Backing Up Data

```bash
# Backup MongoDB database
ssh -i $PEM ec2-user@$EC2_HOST "cd ~/V12_Project/deploy/docker && docker compose exec mongo mongodump --out /tmp/backup"
scp -r -i $PEM ec2-user@$EC2_HOST:/tmp/backup ./backups/

# Backup SQLite
scp -i $PEM -r ec2-user@$EC2_HOST:~/V12_Project/storage/sqlite ./backups/

# Backup logs
scp -i $PEM -r ec2-user@$EC2_HOST:~/V12_Project/storage/logs ./backups/
```

## Reference

### Useful SSH Commands

```bash
# View logs
ssh -i $PEM ec2-user@$EC2_HOST "cd ~/V12_Project/deploy/docker && docker compose logs --tail=50"

# Restart containers
ssh -i $PEM ec2-user@$EC2_HOST "cd ~/V12_Project/deploy/docker && docker compose restart"

# Check resource usage
ssh -i $PEM ec2-user@$EC2_HOST "docker stats --no-stream"

# View all images
ssh -i $PEM ec2-user@$EC2_HOST "docker images"

# Clean up
ssh -i $PEM ec2-user@$EC2_HOST "docker system prune -f"
```

### Directory Structure on EC2

```
/home/ec2-user/
├── V12_Project/                  # Project root
│   ├── deploy/
│   │   ├── docker/
│   │   │   ├── docker-compose.yml
│   │   │   ├── .env              # Generated by deploy.sh
│   │   │   ├── Dockerfile.backend
│   │   │   └── Dockerfile.frontend
│   │   └── cloud/                # This directory
│   ├── backend/
│   │   ├── config/
│   │   │   └── api_keys.json
│   │   └── ...
│   ├── frontend/
│   │   └── ...
│   └── storage/                  # Bind mount, persistent
│       ├── logs/
│       ├── sqlite/
│       ├── cache/
│       └── instruments/
```

### Port Usage

```
5000 (public) → nginx (frontend)
               ├── /api/* → 5001 (backend)
               ├── /ws/*  → 5001 (backend WebSocket)
               └── static files

5001 (internal) → FastAPI (backend)
                  └── MongoDB (27017, internal only)

27017 (internal) → MongoDB
```

## Support

For deployment issues:
1. Check `bash monitor.sh logs` for error messages
2. See Troubleshooting section above
3. Check cloud rules: `cat ../../rules/deploy/cloud/troubleshooting.txt`
4. SSH in and inspect: `docker ps`, `docker logs <container>`

---

**Last Updated:** 2024
**Deployment Rules:** RULE-EP-*, RULE-IT-*, RULE-DR-*, RULE-NT-*
**Cloud Rules Directory:** `../../rules/deploy/cloud/`
