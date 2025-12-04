#!/bin/bash
# Complete Build Script - Configure, Install SDK, Build
# Note: Container configuration must be done from HOST system

set -e

export PATH="/usr/bin:$PATH"

echo "═══════════════════════════════════════════════════"
echo "  Complete Build Process"
echo "═══════════════════════════════════════════════════"
echo ""

CONTAINER_NAME=$(hostname)
echo "Container: $CONTAINER_NAME"
echo ""

# Step 1: Check container configuration
echo "[1/4] Checking container configuration..."
if lxc config show $CONTAINER_NAME 2>/dev/null | grep -q "security.nesting.*true"; then
    echo "✓ Container appears configured"
else
    echo "⚠ Container needs configuration from HOST system"
    echo ""
    echo "Run from HOST:"
    echo "  lxc config set $CONTAINER_NAME security.nesting=true"
    echo "  lxc config set $CONTAINER_NAME security.privileged=true"
    echo "  lxc restart $CONTAINER_NAME"
    echo ""
    echo "Then re-run this script."
    exit 1
fi

# Step 2: Configure network
echo ""
echo "[2/4] Configuring network..."
./configure-container-network.sh > /dev/null 2>&1 || true

# Step 3: Install runtime/SDK
echo ""
echo "[3/4] Installing runtime/SDK..."
if flatpak list --system | grep -q "org.kde.Sdk.*6.8"; then
    echo "✓ SDK already installed"
else
    echo "Installing KDE Platform 6.8 and SDK..."
    if sudo flatpak install --system -y flathub org.kde.Platform//6.8 org.kde.Sdk//6.8; then
        echo "✓ Runtime/SDK installed"
    else
        echo "✗ Installation failed"
        echo "This may require container configuration from host system."
        exit 1
    fi
fi

# Step 4: Build
echo ""
echo "[4/4] Building Flatpak..."
./build.sh --clean

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Build Complete!"
echo "═══════════════════════════════════════════════════"
