# Container Configuration Checklist

## Prerequisites

Before proceeding, ensure you have:
- Access to the HOST system (where LXD/LXC runs)
- Container name: `cursor-cli-u51-prswkb`
- Project mounted at: `/workspace/org.DolphinEmu.dolphin-emu`

## Step 1: Configure Container (From HOST System)

**Run these commands on the HOST system:**

```bash
# Set security settings
lxc config set cursor-cli-u51-prswkb security.nesting=true
lxc config set cursor-cli-u51-prswkb security.privileged=true

# Restart container to apply changes
lxc restart cursor-cli-u51-prswkb

# Wait for container to be ready
sleep 5
```

## Step 2: Verify Configuration (From HOST System)

**Verify the configuration was applied:**

```bash
lxc config show cursor-cli-u51-prswkb | grep security
```

**Expected output:**
```
security.nesting: "true"
security.privileged: "true"
```

## Step 3: Install SDK and Build (Inside Container)

**After container restart, enter the container and run:**

```bash
# Enter container (if needed)
lxc exec cursor-cli-u51-prswkb -- bash

# Navigate to project
cd /workspace/org.DolphinEmu.dolphin-emu
export PATH="/usr/bin:$PATH"

# Run verification and build script
./VERIFY_AND_BUILD.sh
```

**Or run steps manually:**

```bash
# Install SDK
./dev-setup.sh

# Build
./build.sh --clean
```

## Verification Steps

### Check 1: Network Access
```bash
# Inside container
flatpak remote-list --system
```
Should list remotes without errors.

### Check 2: SDK Installation
```bash
# Inside container
flatpak list --system | grep -E "(Platform|Sdk)"
```
Should show:
```
org.kde.Platform	6.8
org.kde.Sdk		6.8
```

### Check 3: Build Success
```bash
# Inside container
ls -la build/
```
Should show build artifacts.

## Troubleshooting

### Configuration Not Applied

**Symptoms:** `flatpak install` still fails with connection error

**Solution:**
1. Verify commands were run on HOST system (not inside container)
2. Ensure container was restarted after configuration
3. Check configuration: `lxc config show cursor-cli-u51-prswkb | grep security`

### Network Still Blocked

**Symptoms:** `[7] Couldn't connect to server` persists

**Solution:**
1. Try host network mode:
   ```bash
   # On host
   lxc config set cursor-cli-u51-prswkb network_mode host
   lxc restart cursor-cli-u51-prswkb
   ```
2. Verify DNS: `curl -I https://dl.flathub.org/repo/summary.idx`
3. Check container logs: `lxc info cursor-cli-u51-prswkb`

### Build Fails

**Symptoms:** `org.kde.Sdk/x86_64/6.8 not installed`

**Solution:**
- Ensure SDK was installed: `flatpak list --system`
- Re-run: `./dev-setup.sh`
- Then: `./build.sh --clean`

## Quick Reference

### Host Commands
```bash
lxc config set cursor-cli-u51-prswkb security.nesting=true security.privileged=true
lxc restart cursor-cli-u51-prswkb
lxc config show cursor-cli-u51-prswkb | grep security
```

### Container Commands
```bash
cd /workspace/org.DolphinEmu.dolphin-emu
export PATH="/usr/bin:$PATH"
./VERIFY_AND_BUILD.sh
```

## Current Status

- ✅ Build scripts ready
- ✅ Manifest validated
- ⏳ Waiting for container configuration from host
- ⏳ Waiting for SDK installation
- ⏳ Ready for build once dependencies installed
