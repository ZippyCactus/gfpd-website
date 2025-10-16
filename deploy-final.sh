#!/bin/bash

# Final Smart Deployment - Properly handles file moves and deletions
# This script creates deployment packages that handle file moves properly

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Smart Deployment - Final Version${NC}"
echo "====================================="
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
    CHANGED_FILES=$(git ls-files | grep -v "^\.git" | grep -v "deploy-" | grep -v "setup-" | grep -v "upload-")
    PACKAGE_NAME="gfpd-full-deploy.zip"
    CREATE_CLEANUP_SCRIPT=false
else
    # Get files changed since last deployment
    LAST_COMMIT=$(cat "$DEPLOYMENT_LOG")
    
    # Get all changes since last deployment
    ALL_CHANGES=$(git diff --name-status $LAST_COMMIT HEAD | grep -v "^\.git" | grep -v "deploy-" | grep -v "setup-" | grep -v "upload-")
    
    # Parse the changes
    ADDED_FILES=""
    MODIFIED_FILES=""
    DELETED_FILES=""
    RENAMED_FILES=""
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            STATUS=$(echo "$line" | cut -c1)
            FILE_PATH=$(echo "$line" | cut -c2- | sed 's/^[[:space:]]*//')
            
            case $STATUS in
                "A")
                    ADDED_FILES="$ADDED_FILES $FILE_PATH"
                    ;;
                "M")
                    MODIFIED_FILES="$MODIFIED_FILES $FILE_PATH"
                    ;;
                "D")
                    DELETED_FILES="$DELETED_FILES $FILE_PATH"
                    ;;
                "R")
                    # For renamed files, extract old and new names
                    OLD_NAME=$(echo "$FILE_PATH" | awk '{print $1}')
                    NEW_NAME=$(echo "$FILE_PATH" | awk '{print $2}')
                    DELETED_FILES="$DELETED_FILES $OLD_NAME"
                    ADDED_FILES="$ADDED_FILES $NEW_NAME"
                    RENAMED_FILES="$RENAMED_FILES $OLD_NAME → $NEW_NAME"
                    ;;
            esac
        fi
    done <<< "$ALL_CHANGES"
    
    # Combine all files to upload
    CHANGED_FILES="$ADDED_FILES $MODIFIED_FILES"
    CHANGED_FILES=$(echo "$CHANGED_FILES" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    
    if [[ -z "$CHANGED_FILES" && -z "$DELETED_FILES" ]]; then
        echo -e "${GREEN}✅ No changes detected since last deployment${NC}"
        echo "Your website is up to date!"
        exit 0
    fi
    
    PACKAGE_NAME="gfpd-changes-$(date +%Y%m%d-%H%M).zip"
    CREATE_CLEANUP_SCRIPT=true
fi

echo -e "${BLUE}📝 Files to include in package:${NC}"
if [[ -n "$CHANGED_FILES" ]]; then
    echo "$CHANGED_FILES" | tr ' ' '\n' | while read file; do
        if [[ -n "$file" ]]; then
            echo "  • $file"
        fi
    done
fi

if [[ -n "$DELETED_FILES" ]]; then
    echo -e "${RED}🗑️  Files to remove from server:${NC}"
    echo "$DELETED_FILES" | tr ' ' '\n' | while read file; do
        if [[ -n "$file" ]]; then
            echo "  • $file"
        fi
    done
fi

if [[ -n "$RENAMED_FILES" ]]; then
    echo -e "${YELLOW}🔄 File moves detected:${NC}"
    echo "$RENAMED_FILES" | tr ' ' '\n' | while read move; do
        if [[ -n "$move" ]]; then
            echo "  • $move"
        fi
    done
fi

echo ""

# Remove any existing deployment packages
rm -f gfpd-*-deploy.zip gfpd-changes-*.zip cleanup-files.txt

# Create cleanup script if needed
if [[ "$CREATE_CLEANUP_SCRIPT" == "true" && -n "$DELETED_FILES" ]]; then
    echo -e "${BLUE}📝 Creating cleanup instructions...${NC}"
    echo "# Files to delete from server after uploading new package" > cleanup-files.txt
    echo "# This ensures no duplicate files remain" >> cleanup-files.txt
    echo "" >> cleanup-files.txt
    echo "$DELETED_FILES" | tr ' ' '\n' | while read file; do
        if [[ -n "$file" ]]; then
            echo "$file" >> cleanup-files.txt
        fi
    done
    echo ""
fi

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
        -x "gfpd-changes-*.zip" \
        -x "cleanup-files.txt"
else
    # Incremental deployment - only changed files
    echo "$CHANGED_FILES" | tr ' ' '\n' | while read file; do
        if [[ -n "$file" && -f "$file" ]]; then
            zip -r "$PACKAGE_NAME" "$file"
        fi
    done
    
    # Add cleanup instructions to the package
    if [[ -f "cleanup-files.txt" ]]; then
        zip "$PACKAGE_NAME" cleanup-files.txt
    fi
fi

# Update deployment log
git rev-parse HEAD > "$DEPLOYMENT_LOG"

echo -e "${GREEN}✅ Deployment package created: $PACKAGE_NAME${NC}"
echo ""

# Show cleanup instructions if needed
if [[ -f "cleanup-files.txt" ]]; then
    echo -e "${YELLOW}⚠️  IMPORTANT: Manual cleanup required!${NC}"
    echo ""
    echo -e "${BLUE}📋 After uploading and extracting the ZIP:${NC}"
    echo "1. Upload and extract '$PACKAGE_NAME' as usual"
    echo "2. Open 'cleanup-files.txt' (included in the ZIP)"
    echo "3. Delete the files listed in cleanup-files.txt from your server"
    echo "4. Delete 'cleanup-files.txt' from your server"
    echo ""
    echo -e "${RED}🗑️  Files to delete from server:${NC}"
    tail -n +4 cleanup-files.txt | while read file; do
        if [[ -n "$file" ]]; then
            echo "  • $file"
        fi
    done
    echo ""
else
    echo -e "${BLUE}📋 Upload Instructions:${NC}"
    echo "1. Log into your cPanel account"
    echo "2. Go to 'File Manager'"
    echo "3. Navigate to 'public_html' directory"
    echo "4. Upload '$PACKAGE_NAME'"
    echo "5. Right-click the zip file and select 'Extract'"
    echo "6. Delete the zip file after extraction"
fi

echo ""
echo -e "${GREEN}🎉 Your website will be updated!${NC}"
echo ""
echo -e "${YELLOW}💡 Benefits of this approach:${NC}"
echo "  ✅ Only uploads changed files (smaller packages)"
echo "  ✅ Handles file moves and deletions properly"
echo "  ✅ Prevents duplicate files on your server"
echo "  ✅ Preserves file permissions set in cPanel"
echo "  ✅ Much faster than uploading everything"
echo ""
echo -e "${BLUE}🚀 For future updates, just run:${NC}"
echo "   ./deploy-final.sh"
