#!/bin/bash
# Verification and Build Script
# Run this AFTER container has been configured from host system

set -e

export PATH="/usr/bin:$PATH"

echo "═══════════════════════════════════════════════════"
echo "  Verification and Build Process"
echo "═══════════════════════════════════════════════════"
echo ""

# Step 1: Verify network access
echo "[1/4] Verifying flatpak network access..."
if timeout 10 flatpak remote-list --system > /dev/null 2>&1; then
    echo "✓ Flatpak can access remotes"
else
    echo "✗ Flatpak network access failed"
    echo "  Container may need to be configured from host:"
    echo "    lxc config set $(hostname) security.nesting=true"
    echo "    lxc config set $(hostname) security.privileged=true"
    echo "    lxc restart $(hostname)"
    exit 1
fi

# Step 2: Check for SDK
echo ""
echo "[2/4] Checking for installed SDK..."
if flatpak list --system | grep -q "org.kde.Sdk.*6.8"; then
    echo "✓ SDK already installed"
    SDK_INSTALLED=true
else
    echo "⚠ SDK not found, will install..."
    SDK_INSTALLED=false
fi

# Step 3: Install SDK if needed
if [ "$SDK_INSTALLED" = false ]; then
    echo ""
    echo "[3/4] Installing runtime/SDK..."
    if sudo flatpak install --system -y flathub org.kde.Platform//6.8 org.kde.Sdk//6.8; then
        echo "✓ Runtime/SDK installed successfully"
    else
        echo "✗ Installation failed"
        echo "  Check container configuration and network access"
        exit 1
    fi
else
    echo ""
    echo "[3/4] Skipping installation (SDK already present)"
fi

# Step 4: Build
echo ""
echo "[4/4] Running full build..."
./build.sh --clean

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Build Complete!"
echo "═══════════════════════════════════════════════════"
