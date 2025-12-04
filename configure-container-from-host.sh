#!/bin/bash
# Host-Level Container Network Configuration Script
# Run this from the HOST system (not inside the container)

set -e

CONTAINER_NAME="${1:-$(lxc list --format csv -c n | head -1 | cut -d',' -f1)}"

if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: Container name not provided"
    echo "Usage: $0 <container-name>"
    echo "Or set CONTAINER_NAME environment variable"
    exit 1
fi

echo "=== Configuring Container Network from Host ==="
echo "Container: $CONTAINER_NAME"
echo ""

# Check if container exists
if ! lxc list --format csv -c n | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Container '$CONTAINER_NAME' not found"
    echo "Available containers:"
    lxc list --format csv -c n
    exit 1
fi

echo "[1] Checking current container configuration..."
lxc config show "$CONTAINER_NAME" | grep -E "(security\.|network)" || true
echo ""

echo "[2] Enabling security.nesting (required for flatpak)..."
lxc config set "$CONTAINER_NAME" security.nesting=true
echo "✓ security.nesting enabled"

echo ""
echo "[3] Setting security.privileged (may be needed for network access)..."
lxc config set "$CONTAINER_NAME" security.privileged=true
echo "✓ security.privileged enabled"

echo ""
echo "[4] Checking network configuration..."
lxc config device list "$CONTAINER_NAME" | grep -E "(eth|net)" || echo "Using default network"
echo ""

echo "[5] Restarting container to apply changes..."
lxc restart "$CONTAINER_NAME"
echo "✓ Container restarted"

echo ""
echo "[6] Waiting for container to be ready..."
sleep 5

echo ""
echo "=== Configuration Complete ==="
echo ""
echo "Container '$CONTAINER_NAME' has been configured with:"
echo "  - security.nesting=true"
echo "  - security.privileged=true"
echo ""
echo "Next steps (inside container):"
echo "  1. Run: ./dev-setup.sh"
echo "  2. Or: sudo flatpak install --system -y flathub org.kde.Platform//6.8 org.kde.Sdk//6.8"
echo ""
