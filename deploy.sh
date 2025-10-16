#!/bin/bash

# Smart Deployment Script - Handles file moves and prevents duplicates
# Usage: ./deploy.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Smart Deployment${NC}"
echo "===================="
echo ""

# Check if we have uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${YELLOW}⚠️  Committing changes first...${NC}"
    git add .
    git commit -m "Deploy $(date)"
    echo -e "${GREEN}✅ Changes committed${NC}"
    echo ""
fi

# Create deployment log
DEPLOYMENT_LOG=".last-deployment"
if [[ ! -f "$DEPLOYMENT_LOG" ]]; then
    echo -e "${YELLOW}🆕 First deployment - creating full package${NC}"
    PACKAGE_NAME="gfpd-full-deploy.zip"
    
    # Create full deployment package
    zip -r "$PACKAGE_NAME" . \
        -x "*.git*" \
        -x "node_modules/*" \
        -x ".DS_Store" \
        -x "deploy*.sh" \
        -x "setup*.sh" \
        -x "upload*.sh" \
        -x "test*.sh" \
        -x "fix*.sh" \
        -x "gfpd-*.zip" \
        -x "cleanup-files.txt"
        
    git rev-parse HEAD > "$DEPLOYMENT_LOG"
    
    echo -e "${GREEN}✅ Full deployment package created: $PACKAGE_NAME${NC}"
    echo ""
    echo -e "${BLUE}📋 Upload Instructions:${NC}"
    echo "1. Log into cPanel → File Manager → public_html"
    echo "2. Upload '$PACKAGE_NAME'"
    echo "3. Extract the ZIP file"
    echo "4. Delete the ZIP file"
    echo ""
    echo -e "${GREEN}🎉 Your entire website will be deployed!${NC}"
    exit 0
fi

# Get changes since last deployment
LAST_COMMIT=$(cat "$DEPLOYMENT_LOG")

# Get all changes
CHANGES=$(git diff --name-status $LAST_COMMIT HEAD | grep -v "deploy" | grep -v "setup" | grep -v "upload" | grep -v "test" | grep -v "fix" | grep -v "cleanup-files.txt")

if [[ -z "$CHANGES" ]]; then
    echo -e "${GREEN}✅ No changes since last deployment${NC}"
    exit 0
fi

# Parse changes
NEW_FILES=""
OLD_FILES=""

echo "$CHANGES" | while IFS=$'\t' read -r status file; do
    case $status in
        "A")
            NEW_FILES="$NEW_FILES $file"
            ;;
        "M")
            NEW_FILES="$NEW_FILES $file"
            ;;
        "D")
            OLD_FILES="$OLD_FILES $file"
            ;;
        "R")
            # For renamed files: R100 oldfile newfile
            OLD_FILE=$(echo "$file" | awk '{print $1}')
            NEW_FILE=$(echo "$file" | awk '{print $2}')
            OLD_FILES="$OLD_FILES $OLD_FILE"
            NEW_FILES="$NEW_FILES $NEW_FILE"
            echo -e "${YELLOW}🔄 File moved: $OLD_FILE → $NEW_FILE${NC}"
            ;;
    esac
done

# Create incremental package
PACKAGE_NAME="gfpd-changes-$(date +%Y%m%d-%H%M).zip"
rm -f gfpd-changes-*.zip cleanup-files.txt

echo -e "${BLUE}📝 Files to upload:${NC}"
echo "$NEW_FILES" | tr ' ' '\n' | while read file; do
    if [[ -n "$file" && -f "$file" ]]; then
        echo "  • $file"
        zip -r "$PACKAGE_NAME" "$file"
    fi
done

# Create cleanup instructions if needed
if [[ -n "$OLD_FILES" ]]; then
    echo -e "${RED}🗑️  Files to delete from server:${NC}"
    echo "# Files to delete from server to prevent duplicates" > cleanup-files.txt
    echo "$OLD_FILES" | tr ' ' '\n' | while read file; do
        if [[ -n "$file" ]]; then
            echo "  • $file"
            echo "$file" >> cleanup-files.txt
        fi
    done
    zip "$PACKAGE_NAME" cleanup-files.txt
fi

# Update deployment log
git rev-parse HEAD > "$DEPLOYMENT_LOG"

echo ""
echo -e "${GREEN}✅ Deployment package created: $PACKAGE_NAME${NC}"
echo ""

if [[ -f "cleanup-files.txt" ]]; then
    echo -e "${YELLOW}⚠️  MANUAL CLEANUP REQUIRED:${NC}"
    echo ""
    echo -e "${BLUE}📋 After uploading the ZIP:${NC}"
    echo "1. Upload and extract '$PACKAGE_NAME'"
    echo "2. Open 'cleanup-files.txt' (included in ZIP)"
    echo "3. Delete the files listed in cleanup-files.txt"
    echo "4. Delete 'cleanup-files.txt'"
    echo ""
    echo -e "${RED}🗑️  Files to delete:${NC}"
    tail -n +2 cleanup-files.txt | while read file; do
        if [[ -n "$file" ]]; then
            echo "  • $file"
        fi
    done
else
    echo -e "${BLUE}📋 Upload Instructions:${NC}"
    echo "1. Log into cPanel → File Manager → public_html"
    echo "2. Upload '$PACKAGE_NAME'"
    echo "3. Extract the ZIP file"
    echo "4. Delete the ZIP file"
fi

echo ""
echo -e "${GREEN}🎉 Deployment ready!${NC}"
echo ""
echo -e "${YELLOW}💡 This prevents duplicate files and preserves your permissions!${NC}"
