#!/bin/bash

# Smart Manual Deployment - Creates incremental packages
# This creates a zip with only changed files for manual upload

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Smart Manual Deployment${NC}"
echo "================================"
echo ""

# Check if we have uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes. Committing them first...${NC}"
    git add .
    git commit -m "Auto-commit before deployment $(date)"
    echo -e "${GREEN}✅ Changes committed${NC}"
    echo ""
fi

# Create deployment log
DEPLOYMENT_LOG=".last-deployment"
if [[ ! -f "$DEPLOYMENT_LOG" ]]; then
    echo -e "${YELLOW}🆕 First deployment - creating full package${NC}"
    # First deployment - include all files
    CHANGED_FILES=$(git ls-files | grep -v "^\.git" | grep -v "deploy-" | grep -v "setup-" | grep -v "upload-")
    PACKAGE_NAME="gfpd-full-deploy.zip"
else
    # Get files changed since last deployment
    LAST_COMMIT=$(cat "$DEPLOYMENT_LOG")
    CHANGED_FILES=$(git diff --name-only $LAST_COMMIT HEAD | grep -v "^\.git" | grep -v "deploy-" | grep -v "setup-" | grep -v "upload-")
    
    if [[ -z "$CHANGED_FILES" ]]; then
        echo -e "${GREEN}✅ No changes detected since last deployment${NC}"
        echo "Your website is up to date!"
        exit 0
    fi
    
    PACKAGE_NAME="gfpd-changes-$(date +%Y%m%d-%H%M).zip"
fi

echo -e "${BLUE}📝 Files to include in package:${NC}"
echo "$CHANGED_FILES" | while read file; do
    echo "  • $file"
done
echo ""

# Remove any existing deployment packages
rm -f gfpd-*-deploy.zip gfpd-changes-*.zip

# Create the deployment package
echo -e "${BLUE}📦 Creating deployment package...${NC}"

if [[ "$PACKAGE_NAME" == *"full"* ]]; then
    # Full deployment
    zip -r "$PACKAGE_NAME" . \
        -x "*.git*" \
        -x "node_modules/*" \
        -x ".DS_Store" \
        -x "*.log" \
        -x "deploy-*.sh" \
        -x "setup-*.sh" \
        -x "upload-*.sh" \
        -x "gfpd-*-deploy.zip" \
        -x "gfpd-changes-*.zip"
else
    # Incremental deployment - only changed files
    echo "$CHANGED_FILES" | zip -r "$PACKAGE_NAME" -@
fi

# Update deployment log
git rev-parse HEAD > "$DEPLOYMENT_LOG"

echo -e "${GREEN}✅ Deployment package created: $PACKAGE_NAME${NC}"
echo ""
echo -e "${BLUE}📋 Upload Instructions:${NC}"
echo "1. Log into your cPanel account"
echo "2. Go to 'File Manager'"
echo "3. Navigate to 'public_html' directory"
echo "4. Upload '$PACKAGE_NAME'"
echo "5. Right-click the zip file and select 'Extract'"
echo "6. Delete the zip file after extraction"
echo ""
echo -e "${GREEN}🎉 Your website will be updated!${NC}"
echo ""
echo -e "${YELLOW}💡 Benefits of this approach:${NC}"
echo "  ✅ Only uploads changed files (smaller packages)"
echo "  ✅ Preserves file permissions set in cPanel"
echo "  ✅ No need to change PDF permissions every time"
echo "  ✅ Much faster than uploading everything"
echo ""
echo -e "${BLUE}🚀 For future updates, just run:${NC}"
echo "   ./deploy-smart-manual.sh"
