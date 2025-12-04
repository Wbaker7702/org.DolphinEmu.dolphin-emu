# Complete Build Guide: Configure Container, Install SDK, Full Build

## Overview

This guide provides step-by-step instructions to:
1. Configure the container from the host system
2. Install the required runtime/SDK
3. Run a full build

## Prerequisites

- Access to the host system (where LXD/LXC is running)
- Container name: `cursor-cli-u51-prswkb`
- Project mounted at: `/workspace/org.DolphinEmu.dolphin-emu`

## Step-by-Step Process

### Step 1: Configure Container (From HOST System)

**Run these commands on the HOST system (not inside the container):**

```bash
# Set container security settings
lxc config set cursor-cli-u51-prswkb security.nesting=true
lxc config set cursor-cli-u51-prswkb security.privileged=true

# Restart container to apply changes
lxc restart cursor-cli-u51-prswkb

# Wait for container to be ready
sleep 5
```

**Or use the provided script:**
```bash
cd /path/to/org.DolphinEmu.dolphin-emu
./configure-container-from-host.sh cursor-cli-u51-prswkb
```

### Step 2: Install Runtime/SDK (Inside Container)

**After container restart, enter the container and run:**

```bash
# Enter container (if needed)
lxc exec cursor-cli-u51-prswkb -- bash

# Navigate to project
cd /workspace/org.DolphinEmu.dolphin-emu
export PATH="/usr/bin:$PATH"

# Run development setup
./dev-setup.sh

# Or install manually
sudo flatpak install --system -y flathub org.kde.Platform//6.8 org.kde.Sdk//6.8
```

### Step 3: Run Full Build (Inside Container)

```bash
# Clean build
./build.sh --clean

# Or build and install
./build.sh --install

# With verbose output
./build.sh --verbose --clean
```

## Automated Script

A complete automation script is available:

**From HOST system:**
```bash
# Configure container
./configure-container-from-host.sh cursor-cli-u51-prswkb
```

**Inside container:**
```bash
# Complete build process
./complete-build.sh
```

## Verification

After each step, verify success:

### Verify Container Configuration
```bash
# On host
lxc config show cursor-cli-u51-prswkb | grep security
```

Should show:
```
security.nesting: "true"
security.privileged: "true"
```

### Verify Runtime/SDK Installation
```bash
# Inside container
flatpak list --system | grep -E "(Platform|Sdk)"
```

Should show:
```
org.kde.Platform	6.8
org.kde.Sdk		6.8
```

### Verify Build
```bash
# Inside container
ls -la build/
```

Should show build artifacts.

## Troubleshooting

### Container Configuration Fails

**Error:** `Permission denied` or `Instance not found`

**Solution:**
- Ensure you're running on the host system
- Check container name: `lxc list`
- Ensure you have LXD permissions

### Runtime Installation Fails

**Error:** `[7] Couldn't connect to server`

**Solution:**
1. Verify container was restarted after configuration
2. Check network connectivity: `curl -I https://dl.flathub.org/repo/summary.idx`
3. Try host network mode:
   ```bash
   # On host
   lxc config set cursor-cli-u51-prswkb network_mode host
   lxc restart cursor-cli-u51-prswkb
   ```

### Build Fails

**Error:** `org.kde.Sdk/x86_64/6.8 not installed`

**Solution:**
- Ensure runtime/SDK are installed (see Step 2)
- Verify with: `flatpak list --system`

## Quick Reference

### All Commands (Host System)
```bash
lxc config set cursor-cli-u51-prswkb security.nesting=true security.privileged=true
lxc restart cursor-cli-u51-prswkb
```

### All Commands (Inside Container)
```bash
cd /workspace/org.DolphinEmu.dolphin-emu
export PATH="/usr/bin:$PATH"
./dev-setup.sh
./build.sh --clean
```

## Expected Timeline

- Container configuration: ~10 seconds
- Container restart: ~5 seconds
- Runtime/SDK installation: ~5-10 minutes (depends on network)
- Full build: ~30-60 minutes (depends on system)

## Current Status

- ✅ Build scripts ready
- ✅ Manifest validated
- ✅ All files present
- ⏳ Waiting for container configuration from host
- ⏳ Waiting for runtime/SDK installation
- ⏳ Ready for full build once dependencies installed
