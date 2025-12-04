#!/bin/bash
# Simple Container Status Check

echo "═══════════════════════════════════════════════════"
echo "  Container Status Check"
echo "═══════════════════════════════════════════════════"
echo ""

CURRENT_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1)

if [ -n "$CURRENT_IP" ] && echo "$CURRENT_IP" | grep -q "^10\."; then
    echo "⚠️  STATUS: Still in BRIDGE MODE"
    echo ""
    echo "Current IP: $CURRENT_IP"
    echo ""
    echo "The container has NOT been configured yet."
    echo "You need to run the configuration commands from the HOST system."
    echo ""
    echo "From HOST system, run:"
    echo "  lxc config set cursor-cli-u51-prswkb security.nesting=true"
    echo "  lxc config set cursor-cli-u51-prswkb security.privileged=true"
    echo "  lxc config set cursor-cli-u51-prswkb network_mode host"
    echo "  lxc restart cursor-cli-u51-prswkb"
    echo ""
    echo "Then verify (from HOST):"
    echo "  lxc config show cursor-cli-u51-prswkb | grep network_mode"
    echo ""
    echo "After restart, run inside container:"
    echo "  ./VERIFY_AND_BUILD.sh"
else
    echo "✓ STATUS: Host network mode active (or no eth0)"
    echo "Ready to proceed with build!"
    echo ""
    echo "Run: ./VERIFY_AND_BUILD.sh"
fi
