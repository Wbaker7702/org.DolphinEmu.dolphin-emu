# DNS/Network Issue with Flatpak

## Problem Summary

Flatpak cannot resolve DNS for `dl.flathub.org` in this containerized environment, even though:
- ✓ System DNS resolution works (`nslookup`, `dig`, `resolvectl`)
- ✓ curl can download files from dl.flathub.org
- ✓ Network connectivity is functional

## Error Details

```
error: Unable to load summary from remote flathub: 
While fetching https://dl.flathub.org/repo/summary.idx: 
[6] Couldn't resolve host name
```

This occurs when flatpak tries to fetch repository metadata using its internal curl/network stack.

## Root Cause

This appears to be a container/LXD environment network namespace issue where:
- Flatpak's internal network resolver cannot access system DNS
- The container's network configuration may restrict flatpak's DNS queries
- Flatpak runs in a different network namespace than system tools

## Workarounds Attempted

1. ✓ Added hosts file entry - Changed error but didn't solve
2. ✓ Configured systemd-resolved - DNS works for system tools
3. ✓ Tried user-level vs system-level installation - Same issue
4. ✓ Cleared flatpak cache - No change
5. ✓ Restarted flatpak services - No change

## Solutions

### Option 1: Fix Container Network (Recommended)
Configure the container/LXD environment to allow flatpak DNS resolution:
```bash
# In container host or LXD config
# Ensure DNS is properly forwarded to containers
# Check network policies and DNS forwarding
```

### Option 2: Use Host System Build
Build on the host system instead of in the container:
```bash
# On host system with proper network access
./setup-build-env.sh
./build.sh --clean
```

### Option 3: Manual Runtime Installation
If you have the runtime/SDK files from another source:
```bash
# Install from local files or different source
flatpak install --system /path/to/runtime.flatpak
```

### Option 4: Use Pre-built Runtimes
If compatible runtimes are already installed:
```bash
# Check what's available
flatpak list

# Build with existing runtime if compatible
./build.sh --clean
```

## Current Status

- ✅ All build scripts ready and tested
- ✅ Manifest validated and correct
- ✅ Dependencies installed (flatpak, flatpak-builder)
- ⏳ Runtime/SDK installation blocked by DNS issue

## Next Steps

1. **Resolve container network DNS** - Configure container to allow flatpak DNS
2. **Build on host system** - Use a system with proper network access
3. **Use alternative runtime source** - Install from local files or mirror

The build environment is 100% ready - only the runtime download is blocked.
