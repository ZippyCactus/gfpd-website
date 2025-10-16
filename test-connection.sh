#!/bin/bash

# Test SSH Connection to cPanel Server

echo "🔧 Testing SSH Connection to cPanel Server"
echo "=========================================="
echo ""

# Test different possible SSH hosts
HOSTS=(
    "greatfallspolicesc.com"
    "greatfallspolice.greatfallspolicesc.com"
    "ssh.greatfallspolicesc.com"
    "server.greatfallspolicesc.com"
)

USERNAME="greatfallspolice"

echo "Testing SSH connections..."
echo ""

for host in "${HOSTS[@]}"; do
    echo -n "Testing $host... "
    if timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes "$USERNAME@$host" "echo 'SSH connection successful'" 2>/dev/null; then
        echo "✅ SUCCESS!"
        echo "   Use this host: $host"
        exit 0
    else
        echo "❌ Failed"
    fi
done

echo ""
echo "❌ No SSH connections successful"
echo ""
echo "🔍 Troubleshooting steps:"
echo "1. Check if SSH is enabled in your cPanel"
echo "2. Verify your hosting provider supports SSH"
echo "3. Contact your hosting provider to enable SSH"
echo "4. Ask them for the correct SSH hostname"
echo ""
echo "💡 Alternative: Use the manual zip upload method"
echo "   ./deploy-via-ftp.sh"
