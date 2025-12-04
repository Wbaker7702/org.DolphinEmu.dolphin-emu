#!/bin/bash
# Container Network Configuration Script
# Attempts to configure container network for flatpak access

set -e

export PATH="/usr/bin:$PATH"

echo "=== Container Network Configuration ==="
echo ""

# Method 1: Ensure DNS is properly configured
echo "[1] Configuring DNS..."
if [ -f /etc/resolv.conf ]; then
    echo "Current /etc/resolv.conf:"
    cat /etc/resolv.conf
    echo ""
fi

# Ensure systemd-resolved is running
if systemctl is-active --quiet systemd-resolved; then
    echo "✓ systemd-resolved is running"
    sudo systemctl restart systemd-resolved
    sleep 2
else
    echo "⚠ systemd-resolved not active"
fi

# Method 2: Configure systemd-resolved with multiple DNS servers
echo ""
echo "[2] Configuring systemd-resolved with public DNS..."
sudo mkdir -p /etc/systemd/resolved.conf.d
cat << RESOLVE | sudo tee /etc/systemd/resolved.conf.d/flatpak-dns.conf > /dev/null
[Resolve]
DNS=8.8.8.8 1.1.1.1 8.8.4.4
FallbackDNS=1.0.0.1 208.67.222.222
Domains=~.
DNSSEC=no
DNSOverTLS=no
RESOLVE
sudo systemctl restart systemd-resolved
sleep 3
echo "✓ systemd-resolved configured"

# Method 3: Add Flathub to /etc/hosts
echo ""
echo "[3] Adding Flathub to /etc/hosts..."
if ! grep -q "dl.flathub.org" /etc/hosts; then
    echo "151.101.137.91 dl.flathub.org" | sudo tee -a /etc/hosts
    echo "✓ Added to /etc/hosts"
else
    echo "✓ Already in /etc/hosts"
fi

# Method 4: Test DNS resolution
echo ""
echo "[4] Testing DNS resolution..."
if getent hosts dl.flathub.org > /dev/null; then
    RESOLVED_IP=$(getent hosts dl.flathub.org | awk '{print $1}')
    echo "✓ DNS resolution works: dl.flathub.org -> $RESOLVED_IP"
else
    echo "✗ DNS resolution failed"
    exit 1
fi

# Method 5: Test network connectivity
echo ""
echo "[5] Testing network connectivity..."
if curl -s --max-time 5 -I https://dl.flathub.org/repo/summary.idx | head -1 | grep -q "200\|HTTP"; then
    echo "✓ Network connectivity works"
else
    echo "✗ Network connectivity failed"
    exit 1
fi

# Method 6: Configure flatpak to use system network
echo ""
echo "[6] Configuring flatpak network settings..."
# Try to ensure flatpak can use system DNS
export GIO_USE_VFS=local
export GIO_USE_VOLUME_MONITOR=unix

# Test flatpak
echo ""
echo "[7] Testing flatpak network access..."
if timeout 15 flatpak remote-list --system > /dev/null 2>&1; then
    echo "✓ Flatpak can list remotes"
else
    echo "⚠ Flatpak remote-list may have issues"
fi

# Try installation
echo ""
echo "[8] Attempting runtime installation..."
if sudo flatpak install --system -y flathub org.kde.Platform//6.8 2>&1 | head -5 | grep -q "error"; then
    echo "⚠ Installation still failing - container network isolation may require host-level configuration"
    echo ""
    echo "To fix from host system, run:"
    echo "  lxc config set <container> security.nesting true"
    echo "  lxc config set <container> security.privileged true"
    echo "  lxc restart <container>"
    exit 1
else
    echo "✓ Installation successful!"
    exit 0
fi
