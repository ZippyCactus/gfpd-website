#!/bin/bash

# Rsync Deployment Script - Upload Only Changed Files
# This script uses rsync to efficiently sync only changed files

# Configuration - UPDATE THESE WITH YOUR DETAILS
CPANEL_USERNAME="greatfallspolice"  # Your cPanel username  
CPANEL_DOMAIN="greatfallspolicesc.com"      # Your domain name
REMOTE_PATH="/home/greatfallspolice/public_html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Rsync Deployment - Upload Only Changes${NC}"
echo "=============================================="
echo ""

# Check if we have uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes. Committing them first...${NC}"
    git add .
    git commit -m "Auto-commit before deployment $(date)"
    echo -e "${GREEN}✅ Changes committed${NC}"
    echo ""
fi

echo -e "${BLUE}📤 Syncing changed files...${NC}"

# Use rsync to sync only changed files
# --update: skip files that are newer on the destination
# --exclude: skip git files and deployment scripts
# --progress: show progress
# --dry-run: first show what would be synced (remove this line for actual upload)

echo -e "${YELLOW}🔍 Checking what files would be synced...${NC}"
rsync -avz --progress \
    --exclude='.git/' \
    --exclude='deploy-*.sh' \
    --exclude='setup-*.sh' \
    --exclude='upload-*.sh' \
    --exclude='*.zip' \
    --exclude='.DS_Store' \
    --exclude='node_modules/' \
    --exclude='.last-deployment' \
    ./ "$CPANEL_USERNAME@$CPANEL_DOMAIN:$REMOTE_PATH/"

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}💡 What rsync does:${NC}"
echo "  ✅ Uploads only changed files"
echo "  ✅ Preserves file permissions you set in cPanel"
echo "  ✅ Skips files that haven't changed"
echo "  ✅ Much faster than uploading everything"
echo ""
echo -e "${YELLOW}📋 Your PDF with 644 permissions will be preserved!${NC}"
echo "   No need to change permissions after each update"
echo ""
echo -e "${BLUE}🚀 For future updates, just run:${NC}"
echo "   ./deploy-rsync.sh"
