# Remove Container from Bridge Mode

## Problem
Container is currently in bridge mode, which blocks flatpak network access.

## Solution: Configure Host Network Mode

### Option 1: Use the Provided Script (Recommended)

**From HOST system, run:**
```bash
cd /path/to/org.DolphinEmu.dolphin-emu
./configure-container-host.sh
```

### Option 2: Manual Configuration

**From HOST system, run these commands:**

```bash
# Set security settings
lxc config set cursor-cli-u51-prswkb security.nesting=true
lxc config set cursor-cli-u51-prswkb security.privileged=true

# Set host network mode (removes bridge mode)
lxc config set cursor-cli-u51-prswkb network_mode host

# Restart container to apply changes
lxc restart cursor-cli-u51-prswkb

# Wait for container to be ready
sleep 5
```

### Option 3: Remove Network Device (Alternative)

If host network mode doesn't work, you can remove the bridge device:

```bash
# On HOST system:
lxc config device remove cursor-cli-u51-prswkb eth0
lxc config set cursor-cli-u51-prswkb network_mode host
lxc restart cursor-cli-u51-prswkb
```

## Verification

### From HOST System

```bash
# Check configuration
lxc config show cursor-cli-u51-prswkb | grep -E "(security|network_mode)"
```

**Expected output:**
```
security.nesting: "true"
security.privileged: "true"
network_mode: host
```

### Inside Container

```bash
# Check network interfaces
ip addr show
```

**Expected:** Should show host network interfaces (not eth0 with 10.x.x.x IP)

**If still showing bridge mode:**
- Container may not have restarted
- Configuration may not have been applied
- Try stopping and starting: `lxc stop cursor-cli-u51-prswkb && lxc start cursor-cli-u51-prswkb`

## After Configuration

Once host network mode is active:

```bash
# Inside container:
cd /workspace/org.DolphinEmu.dolphin-emu
export PATH="/usr/bin:$PATH"
./VERIFY_AND_BUILD.sh
```

## Troubleshooting

### Container Still in Bridge Mode

1. **Verify commands were run on HOST** (not inside container)
2. **Check container was restarted:**
   ```bash
   # On host
   lxc list cursor-cli-u51-prswkb
   ```
3. **Force restart:**
   ```bash
   # On host
   lxc stop cursor-cli-u51-prswkb
   lxc start cursor-cli-u51-prswkb
   ```

### Network Still Blocked

1. **Check host network:**
   ```bash
   # On host
   ip addr show
   ```
2. **Try removing network device:**
   ```bash
   # On host
   lxc config device remove cursor-cli-u51-prswkb eth0
   lxc restart cursor-cli-u51-prswkb
   ```

## Summary

**Current Status:** Container in bridge mode (needs host configuration)

**Solution:** Configure host network mode from HOST system

**After Configuration:** Container will use host network, flatpak will work, build can proceed
