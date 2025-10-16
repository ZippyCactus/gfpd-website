#!/bin/bash

# cPanel Deployment Setup Script for GFPD Website
# This script helps you configure automated deployment to your cPanel server

echo "🔧 Setting up cPanel deployment for GFPD Website"
echo ""

# Display the public key
echo "📋 Your SSH Public Key (copy this to cPanel):"
echo "----------------------------------------"
cat ~/.ssh/id_rsa_cpanel.pub
echo "----------------------------------------"
echo ""

echo "📝 Next steps:"
echo "1. Log into your cPanel account"
echo "2. Go to 'SSH Access' section"
echo "3. Click 'Manage SSH Keys'"
echo "4. Click 'Import Key' and paste the key above"
echo "5. Click 'Authorize' to enable the key"
echo ""

read -p "Have you added the SSH key to cPanel? (y/n): " key_added

if [[ $key_added != "y" && $key_added != "Y" ]]; then
    echo "❌ Please add the SSH key to cPanel first, then run this script again."
    exit 1
fi

echo ""
echo "🔗 Now let's configure the cPanel remote..."
echo ""

# Get cPanel details
read -p "Enter your cPanel username: " cpanel_username
read -p "Enter your domain name (e.g., greatfallspolicesc.com): " domain_name

# Add cPanel remote
cpanel_remote="ssh://${cpanel_username}@${domain_name}/home/${cpanel_username}/public_html.git"

echo "Adding cPanel remote: $cpanel_remote"

# Remove existing cpanel remote if it exists
git remote remove cpanel 2>/dev/null

# Add the new cpanel remote
git remote add cpanel "$cpanel_remote"

echo ""
echo "✅ cPanel deployment setup complete!"
echo ""
echo "🚀 To deploy your site:"
echo "   ./deploy-to-cpanel.sh"
echo ""
echo "📋 Your deployment will:"
echo "   1. Push to GitHub (backup)"
echo "   2. Push to cPanel (live site)"
echo ""
echo "⚠️  Note: You'll need to set up the Git repository on your cPanel server first."
echo "   Contact your hosting provider if you need help with this."
