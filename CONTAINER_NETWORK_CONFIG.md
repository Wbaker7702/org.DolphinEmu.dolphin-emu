# Container Network Configuration Guide

## Problem
Flatpak cannot establish TCP connections to dl.flathub.org due to container network namespace isolation, even though DNS resolution works.

## Solution: Configure Container from Host

### Option 1: Using LXC Commands (Recommended)

From the **host system**, run:

```bash
# Get container name
CONTAINER_NAME=$(lxc list --format csv -c n | head -1)

# Or specify manually
CONTAINER_NAME="your-container-name"

# Enable security.nesting (required for flatpak)
lxc config set "$CONTAINER_NAME" security.nesting=true

# Enable privileged mode (may be needed for network access)
lxc config set "$CONTAINER_NAME" security.privileged=true

# Restart container to apply changes
lxc restart "$CONTAINER_NAME"
```

### Option 2: Using the Provided Script

From the **host system**, run:

```bash
# Navigate to project directory (if mounted)
cd /path/to/org.DolphinEmu.dolphin-emu

# Run the configuration script
./configure-container-from-host.sh <container-name>

# Or let it auto-detect
./configure-container-from-host.sh
```

### Option 3: Manual Configuration

Edit the container configuration directly:

```bash
# On host system
lxc config edit <container-name>
```

Add or modify:
```yaml
security:
  nesting: "true"
  privileged: "true"
```

Then restart:
```bash
lxc restart <container-name>
```

## Verification

After configuring and restarting, test inside the container:

```bash
# Test DNS
getent hosts dl.flathub.org

# Test network
curl -I https://dl.flathub.org/repo/summary.idx

# Test flatpak
flatpak remote-list --system

# Try installation
sudo flatpak install --system -y flathub org.kde.Platform//6.8
```

## Alternative: Host Network Mode

If the above doesn't work, try host network mode:

```bash
# On host system
lxc config set <container-name> network_mode host
lxc restart <container-name>
```

**Warning**: Host network mode reduces isolation but may be needed for flatpak.

## Current Container Status

- Container Name: Check with `hostname` inside container
- Network Namespace: Isolated (net:[4026533773])
- DNS: Working (systemd-resolved)
- Network: Working (curl/wget)
- Flatpak Network: Blocked (needs container config)

## Files Created

- `configure-container-network.sh` - Run inside container (configures DNS/system)
- `configure-container-from-host.sh` - Run on host (configures container)
- `CONTAINER_NETWORK_CONFIG.md` - This guide
