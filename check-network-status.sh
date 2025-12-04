#!/bin/bash
# Network Status Check Script
# Run this inside the container to verify network configuration

echo "═══════════════════════════════════════════════════"
echo "  Container Network Status Check"
echo "═══════════════════════════════════════════════════"
echo ""

echo "[1] Checking network interfaces..."
IP_OUTPUT=$(ip addr show 2>/dev/null)
echo "$IP_OUTPUT"
echo ""

# Check if we're in bridge mode (has eth0 with 10.x.x.x IP)
if echo "$IP_OUTPUT" | grep -q "eth0.*inet.*10\."; then
    echo "⚠️  Status: BRIDGE MODE ACTIVE"
    echo "   Container is still using bridge networking"
    echo "   Need to configure host network mode from HOST system"
    echo ""
    echo "   Run from HOST:"
    echo "   lxc config set cursor-cli-u51-prswkb network_mode host"
    echo "   lxc restart cursor-cli-u51-prswkb"
    BRIDGE_MODE=true
elif echo "$IP_OUTPUT" | grep -q "eth0.*inet"; then
    echo "⚠️  Status: CUSTOM NETWORK MODE"
    echo "   Container has eth0 but not in standard bridge mode"
    BRIDGE_MODE=false
else
    echo "✓ Status: HOST NETWORK MODE (or no eth0)"
    echo "   Container appears to be using host network"
    BRIDGE_MODE=false
fi

echo ""
echo "[2] Testing DNS resolution..."
if getent hosts dl.flathub.org > /dev/null 2>&1; then
    RESOLVED_IP=$(getent hosts dl.flathub.org | awk '{print $1}')
    echo "✓ DNS works: dl.flathub.org -> $RESOLVED_IP"
else
    echo "✗ DNS resolution failed"
fi

echo ""
echo "[3] Testing network connectivity..."
if timeout 5 curl -s -o /dev/null https://dl.flathub.org > /dev/null 2>&1; then
    echo "✓ Network connectivity works (curl)"
else
    echo "✗ Network connectivity failed (curl)"
fi

echo ""
echo "[4] Testing flatpak network access..."
export PATH="/usr/bin:$PATH"
if timeout 10 flatpak remote-list --system > /dev/null 2>&1; then
    echo "✓ Flatpak can access remotes"
    FLATPAK_WORKS=true
else
    echo "✗ Flatpak cannot access remotes"
    FLATPAK_WORKS=false
fi

echo ""
echo "═══════════════════════════════════════════════════"
if [ "$BRIDGE_MODE" = true ]; then
    echo "  ⚠️  ACTION REQUIRED"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "Container is still in bridge mode."
    echo "Configure from HOST system:"
    echo ""
    echo "  lxc config set cursor-cli-u51-prswkb security.nesting=true"
    echo "  lxc config set cursor-cli-u51-prswkb security.privileged=true"
    echo "  lxc config set cursor-cli-u51-prswkb network_mode host"
    echo "  lxc restart cursor-cli-u51-prswkb"
    exit 1
elif [ "$FLATPAK_WORKS" = true ]; then
    echo "  ✓ READY FOR BUILD"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "Network configuration is correct!"
    echo "You can now run:"
    echo "  ./VERIFY_AND_BUILD.sh"
    exit 0
else
    echo "  ⚠️  NETWORK ISSUE"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "Network may be configured but flatpak still has issues."
    echo "Try running: ./VERIFY_AND_BUILD.sh"
    exit 1
fi
