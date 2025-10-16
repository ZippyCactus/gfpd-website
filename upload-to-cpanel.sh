#!/bin/bash

# Alternative cPanel Upload Script (without SSH)
# This uses cPanel File Manager API or FTP to upload files

echo "🚀 Uploading to cPanel via File Manager..."

# You'll need to modify these variables with your actual cPanel details
CPANEL_USERNAME="your_username"
CPANEL_DOMAIN="your_domain.com"
CPANEL_API_TOKEN="your_api_token"  # Get this from cPanel

# Create a temporary zip file of your website
echo "📦 Creating deployment package..."
zip -r gfpd-website-deploy.zip . -x "*.git*" "node_modules/*" ".DS_Store" "*.log"

echo "📤 Upload package created: gfpd-website-deploy.zip"
echo "📋 Manual steps:"
echo "1. Log into your cPanel"
echo "2. Go to File Manager"
echo "3. Navigate to public_html"
echo "4. Upload gfpd-website-deploy.zip"
echo "5. Extract the zip file"
echo "6. Delete the zip file"

echo "✅ Package ready for manual upload!"
