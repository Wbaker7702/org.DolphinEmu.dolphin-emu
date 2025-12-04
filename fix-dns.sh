#!/bin/bash
# Comprehensive DNS Fix Script for Flatpak in Container Environment

set -e

export PATH="/usr/bin:$PATH"

echo "=== Flatpak DNS Fix Script ==="
echo ""

# Method 1: Update /etc/hosts with Flathub IP
echo "[1] Adding Flathub to /etc/hosts..."
if ! grep -q "dl.flathub.org" /etc/hosts; then
    echo "151.101.137.91 dl.flathub.org" | sudo tee -a /etc/hosts
    echo "✓ Added to /etc/hosts"
else
    echo "✓ Already in /etc/hosts"
fi

# Method 2: Configure systemd-resolved with public DNS
echo ""
echo "[2] Configuring systemd-resolved..."
sudo mkdir -p /etc/systemd/resolved.conf.d
cat << RESOLVE | sudo tee /etc/systemd/resolved.conf.d/flatpak-dns.conf > /dev/null
[Resolve]
DNS=8.8.8.8 1.1.1.1 8.8.4.4
FallbackDNS=1.0.0.1
Domains=~.
RESOLVE
sudo systemctl restart systemd-resolved
sleep 2
echo "✓ systemd-resolved configured"

# Method 3: Test DNS resolution
echo ""
echo "[3] Testing DNS resolution..."
if getent hosts dl.flathub.org > /dev/null; then
    echo "✓ DNS resolution works"
else
    echo "✗ DNS resolution failed"
    exit 1
fi

# Method 4: Test flatpak
echo ""
echo "[4] Testing flatpak..."
if timeout 10 flatpak remote-list --system > /dev/null 2>&1; then
    echo "✓ Flatpak can access remotes"
    echo ""
    echo "SUCCESS! DNS issue resolved."
    exit 0
else
    echo "✗ Flatpak still cannot access remotes"
    echo ""
    echo "This appears to be a container network namespace issue."
    echo "Flatpak may be using a restricted network stack."
    echo ""
    echo "Possible solutions:"
    echo "  1. Configure container network to allow flatpak access"
    echo "  2. Use host network mode for container"
    echo "  3. Install runtimes on host system and bind mount"
    echo "  4. Use alternative build method"
    exit 1
fi
