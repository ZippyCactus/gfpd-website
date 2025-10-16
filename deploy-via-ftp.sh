#!/bin/bash

# FTP Deployment Script for cPanel
# This script creates a deployment package and provides instructions for manual upload

echo "🚀 Creating cPanel deployment package..."

# Remove any existing deployment files
rm -f gfpd-website-deploy.zip

# Create deployment package (exclude git files and node_modules)
echo "📦 Packaging website files..."
zip -r gfpd-website-deploy.zip . \
    -x "*.git*" \
    -x "node_modules/*" \
    -x ".DS_Store" \
    -x "*.log" \
    -x "deploy-*.sh" \
    -x "setup-*.sh" \
    -x "upload-*.sh"

echo "✅ Deployment package created: gfpd-website-deploy.zip"
echo ""
echo "📋 Manual Upload Instructions:"
echo "1. Log into your cPanel account"
echo "2. Go to 'File Manager'"
echo "3. Navigate to 'public_html' directory"
echo "4. Upload 'gfpd-website-deploy.zip'"
echo "5. Right-click the zip file and select 'Extract'"
echo "6. Delete the zip file after extraction"
echo ""
echo "🌐 Your website will be updated with the latest changes!"
echo ""
echo "💡 Tip: You can also use this script after making changes:"
echo "   ./deploy-via-ftp.sh"
echo "   Then follow the upload instructions above"
