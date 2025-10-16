#!/bin/bash

# Script to help diagnose and fix cPanel Git issues

echo "🔧 cPanel Git Repository Troubleshooting"
echo "========================================"
echo ""

echo "📊 Current Local Repository Status:"
echo "Latest commit: $(git log --oneline -1)"
echo "Branch: $(git branch --show-current)"
echo "Remote URL: $(git remote get-url origin)"
echo ""

echo "🌐 GitHub Repository Status:"
echo "Latest commit on GitHub: $(git ls-remote origin HEAD | cut -f1)"
echo ""

echo "📋 Troubleshooting Steps for cPanel:"
echo ""
echo "1. VERIFY REPOSITORY SETTINGS:"
echo "   - Go to cPanel → Git Version Control → Manage"
echo "   - Check 'Basic Information' tab"
echo "   - Ensure 'Repository Path' is: /home/greatfallspolice/public_html"
echo "   - Ensure 'Remote URL' is: https://github.com/ZippyCactus/gfpd-website.git"
echo "   - Ensure 'Checked-Out Branch' is: main"
echo ""

echo "2. TRY MANUAL BRANCH SWITCH:"
echo "   - In cPanel → Git Version Control → Manage → Basic Information"
echo "   - Change 'Checked-Out Branch' to 'master' (if available)"
echo "   - Click 'Update'"
echo "   - Then change it back to 'main'"
echo "   - Click 'Update' again"
echo ""

echo "3. CLEAR REPOSITORY CACHE:"
echo "   - In cPanel → Git Version Control"
echo "   - Click 'Remove' on your gfpd-website repository"
echo "   - Click 'Create' and recreate the repository with same settings"
echo ""

echo "4. ALTERNATIVE: USE MANUAL UPLOAD:"
echo "   - Use the 'gfpd-website-deploy.zip' file created by deploy-via-ftp.sh"
echo "   - Upload via cPanel File Manager"
echo ""

echo "🎯 Recommended Next Steps:"
echo "1. Try step 2 first (manual branch switch)"
echo "2. If that doesn't work, try step 3 (recreate repository)"
echo "3. If Git still doesn't work, use the manual upload method"
echo ""
echo "💡 The manual upload method is actually faster and more reliable"
echo "   for most website updates!"
