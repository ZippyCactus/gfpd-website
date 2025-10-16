#!/bin/bash

# cPanel Deployment Script for GFPD Website
# This script pushes your local changes to your cPanel server

echo "🚀 Starting deployment to cPanel..."

# Check if we have uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️  You have uncommitted changes. Please commit them first:"
    echo "   git add ."
    echo "   git commit -m 'Your commit message'"
    exit 1
fi

# Push to GitHub (backup)
echo "📤 Pushing to GitHub (backup)..."
git push origin main

# Check if cpanel remote exists
if ! git remote get-url cpanel >/dev/null 2>&1; then
    echo "❌ cPanel remote not configured. Please run setup-cpanel-deploy.sh first."
    exit 1
fi

# Push to cPanel (live site)
echo "🌐 Pushing to cPanel (live site)..."
git push cpanel main

echo "✅ Deployment complete!"
echo "📊 Your site is now live at: https://GreatFallsPoliceSC.com"
