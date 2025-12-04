# Verify Host Configuration Status

## Current Container Status

**Network Mode:** Still in BRIDGE MODE
- Interface: `eth0` with IP `10.30.247.182/24`
- This indicates host network mode has NOT been applied yet

## What Needs to Happen

The container configuration commands **MUST be run from the HOST system**, not from inside the container.

### Step 1: From HOST System

Run these commands on the **HOST** (not inside container):

```bash
lxc config set cursor-cli-u51-prswkb security.nesting=true
lxc config set cursor-cli-u51-prswkb security.privileged=true
lxc config set cursor-cli-u51-prswkb network_mode host
lxc restart cursor-cli-u51-prswkb
```

### Step 2: Verify Configuration (from HOST)

After restart, verify on HOST:

```bash
lxc config show cursor-cli-u51-prswkb | grep -E "(security|network_mode)"
```

**Expected output:**
```
security.nesting: "true"
security.privileged: "true"
network_mode: host
```

### Step 3: Verify Inside Container

After container restarts, check network:

```bash
# Inside container:
ip addr show
```

**Expected:** Should show host network interfaces (NOT eth0 with 10.x.x.x)

### Step 4: Run Build Script

Once network mode is confirmed:

```bash
# Inside container:
cd /workspace/org.DolphinEmu.dolphin-emu
export PATH="/usr/bin:$PATH"
./VERIFY_AND_BUILD.sh
```

## Current Issue

- Container is still in bridge mode
- `flatpak install` fails due to network restrictions
- Host-level configuration has not been applied yet

## How to Know It Worked

After host configuration and restart:
1. `ip addr show` should NOT show `eth0` with `10.x.x.x` IP
2. `flatpak install` should succeed
3. SDK installation will complete
4. Build can proceed

## Troubleshooting

If commands fail on host:
- Ensure you're on the HOST system (not inside container)
- Check container name: `lxc list`
- Verify LXC/LXD is installed on host
- Check permissions (may need sudo)
