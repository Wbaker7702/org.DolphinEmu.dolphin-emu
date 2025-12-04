#!/bin/bash
# Comprehensive Flatpak Network Diagnosis

set -e

export PATH="/usr/bin:$PATH"

echo "═══════════════════════════════════════════════════"
echo "  Flatpak Network Diagnosis"
echo "═══════════════════════════════════════════════════"
echo ""

echo "[1] System DNS resolution..."
getent hosts dl.flathub.org || echo "✗ DNS failed"

echo ""
echo "[2] curl connectivity..."
if curl -s --connect-timeout 5 https://dl.flathub.org/repo/summary.idx > /dev/null 2>&1; then
    echo "✓ curl works"
else
    echo "✗ curl failed"
fi

echo ""
echo "[3] Flatpak remote list (cached)..."
if flatpak remote-list --system > /dev/null 2>&1; then
    echo "✓ remote-list works"
else
    echo "✗ remote-list failed"
fi

echo ""
echo "[4] Flatpak remote info (requires network)..."
if timeout 10 flatpak remote-info --system flathub org.kde.Platform 2>&1 | head -5; then
    echo "✓ remote-info works"
else
    echo "✗ remote-info failed"
fi

echo ""
echo "[5] Testing flatpak with strace..."
echo "Running: sudo strace -e trace=network -f flatpak remote-info --system flathub org.kde.Platform 2>&1 | grep -E '(connect|dl.flathub)' | head -10"
sudo strace -e trace=network -f flatpak remote-info --system flathub org.kde.Platform 2>&1 | grep -E '(connect|dl.flathub|ECONN)' | head -10 || true

echo ""
echo "[6] Checking network namespaces..."
if [ -d /proc/self/ns ]; then
    echo "Network namespace: $(readlink /proc/self/ns/net)"
    echo "PID namespace: $(readlink /proc/self/ns/pid)"
fi

echo ""
echo "═══════════════════════════════════════════════════"
