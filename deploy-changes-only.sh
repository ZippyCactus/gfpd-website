#!/bin/bash

# Smart Deployment Script - Upload Only Changed Files
# This script tracks changes and uploads only modified files to cPanel

# Configuration - UPDATE THESE WITH YOUR DETAILS
CPANEL_USERNAME="greatfallspolice"  # Your cPanel username
CPANEL_DOMAIN="yourdomain.com"      # Your domain name
REMOTE_PATH="/home/greatfallspolice/public_html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Smart Deployment - Upload Only Changes${NC}"
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

# Get list of changed files since last deployment
echo -e "${BLUE}📋 Checking for changed files...${NC}"

# Create a file to track last deployment
DEPLOYMENT_LOG=".last-deployment"
if [[ ! -f "$DEPLOYMENT_LOG" ]]; then
    # First deployment - get all tracked files
    echo -e "${YELLOW}🆕 First deployment detected - will upload all files${NC}"
    CHANGED_FILES=$(git ls-files | grep -v "^\.git" | grep -v "deploy-" | grep -v "setup-" | grep -v "upload-")
else
    # Get files changed since last deployment
    LAST_COMMIT=$(cat "$DEPLOYMENT_LOG")
    CHANGED_FILES=$(git diff --name-only $LAST_COMMIT HEAD | grep -v "^\.git" | grep -v "deploy-" | grep -v "setup-" | grep -v "upload-")
fi

if [[ -z "$CHANGED_FILES" ]]; then
    echo -e "${GREEN}✅ No changes detected since last deployment${NC}"
    echo "Your website is up to date!"
    exit 0
fi

echo -e "${BLUE}📝 Files to upload:${NC}"
echo "$CHANGED_FILES" | while read file; do
    echo "  • $file"
done
echo ""

# Upload changed files
echo -e "${BLUE}📤 Uploading changed files...${NC}"
UPLOADED_COUNT=0
FAILED_COUNT=0

echo "$CHANGED_FILES" | while read file; do
    if [[ -f "$file" ]]; then
        echo -n "  Uploading $file... "
        
        # Create directory structure on remote server if needed
        REMOTE_DIR=$(dirname "$REMOTE_PATH/$file")
        ssh "$CPANEL_USERNAME@$CPANEL_DOMAIN" "mkdir -p '$REMOTE_DIR'" 2>/dev/null
        
        # Upload the file
        if scp "$file" "$CPANEL_USERNAME@$CPANEL_DOMAIN:$REMOTE_PATH/$file" 2>/dev/null; then
            echo -e "${GREEN}✅${NC}"
            ((UPLOADED_COUNT++))
        else
            echo -e "${RED}❌${NC}"
            ((FAILED_COUNT++))
        fi
    fi
done

# Update deployment log
git rev-parse HEAD > "$DEPLOYMENT_LOG"

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "=============================================="
echo -e "📊 Uploaded: ${GREEN}$UPLOADED_COUNT${NC} files"
if [[ $FAILED_COUNT -gt 0 ]]; then
    echo -e "❌ Failed: ${RED}$FAILED_COUNT${NC} files"
fi
echo ""
echo -e "${BLUE}💡 Next time you make changes, just run:${NC}"
echo "   ./deploy-changes-only.sh"
echo ""
echo -e "${YELLOW}📋 Note: This preserves file permissions set in cPanel${NC}"
echo "   Files like PDFs with custom permissions won't be overwritten"
