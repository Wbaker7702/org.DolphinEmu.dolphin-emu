#!/bin/bash
# Container Configuration Script - Run from HOST System
# This script configures the container to use host network mode

set -e

CONTAINER_NAME="cursor-cli-u51-prswkb"

echo "═══════════════════════════════════════════════════"
echo "  Container Network Configuration"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Container: $CONTAINER_NAME"
echo ""

# Check if container exists
if ! lxc list --format csv -c n | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Container '$CONTAINER_NAME' not found"
    echo "Available containers:"
    lxc list --format csv -c n
    exit 1
fi

echo "[1/4] Checking current configuration..."
CURRENT_CONFIG=$(lxc config show "$CONTAINER_NAME" 2>/dev/null | grep -E "(security|network_mode)" || echo "")
echo "Current config:"
echo "$CURRENT_CONFIG" | head -5
echo ""

echo "[2/4] Configuring security settings..."
lxc config set "$CONTAINER_NAME" security.nesting=true
lxc config set "$CONTAINER_NAME" security.privileged=true
echo "✓ Security settings configured"

echo ""
echo "[3/4] Configuring host network mode..."
lxc config set "$CONTAINER_NAME" network_mode host
echo "✓ Host network mode configured"

echo ""
echo "[4/4] Restarting container..."
lxc restart "$CONTAINER_NAME"
echo "✓ Container restarted"

echo ""
echo "Waiting for container to be ready..."
sleep 5

echo ""
echo "[5/5] Verifying configuration..."
VERIFIED_CONFIG=$(lxc config show "$CONTAINER_NAME" 2>/dev/null | grep -E "(security|network_mode)" || echo "")
echo "New configuration:"
echo "$VERIFIED_CONFIG"
echo ""

if echo "$VERIFIED_CONFIG" | grep -q "network_mode: host"; then
    echo "═══════════════════════════════════════════════════"
    echo "  ✓ Configuration Complete!"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "Container is now configured with:"
    echo "  • security.nesting=true"
    echo "  • security.privileged=true"
    echo "  • network_mode=host"
    echo ""
    echo "Next steps (inside container):"
    echo "  1. cd /workspace/org.DolphinEmu.dolphin-emu"
    echo "  2. export PATH=\"/usr/bin:\$PATH\""
    echo "  3. ./VERIFY_AND_BUILD.sh"
    exit 0
else
    echo "⚠ Configuration may not have been applied correctly"
    echo "Please check manually:"
    echo "  lxc config show $CONTAINER_NAME | grep network_mode"
    exit 1
fi
