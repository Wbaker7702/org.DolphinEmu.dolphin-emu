# Build Commands Reference

Quick reference for building and testing the Dolphin Emulator Flatpak.

## Build Script Usage

### Basic Commands

```bash
./build.sh                # Build the Flatpak
./build.sh --install      # Build and install
./build.sh --clean        # Clean and build
./build.sh --dry-run      # Validate without building
```

### All Options

```bash
./build.sh [options]

Options:
  --install, -i    Install the built Flatpak
  --clean, -c      Clean build directories before building
  --verbose, -v    Verbose output
  --dry-run, -d    Validate manifest without building
  --help, -h       Show help message
```

### Examples

```bash
# Build the Flatpak
./build.sh

# Clean previous build and rebuild
./build.sh --clean

# Build with verbose output
./build.sh --verbose

# Build and automatically install
./build.sh --install

# Validate manifest without building (useful when flatpak-builder is not installed)
./build.sh --dry-run

# Combine options
./build.sh --clean --verbose --install
```

## Other Scripts

### Validation
```bash
./validate.sh              # Validate manifest and files
```

### Testing
```bash
./test.sh                  # Run all tests
```

### Debugging
```bash
./debug.sh                 # Comprehensive debug check
```

### Deployment
```bash
./deploy.sh                # Run deployment checklist
```

## Prerequisites

To actually build (not just validate), you need:

```bash
# Install flatpak-builder
sudo apt install flatpak-builder

# Or on other distributions:
# Fedora: sudo dnf install flatpak-builder
# Arch:   sudo pacman -S flatpak-builder
```

## Workflow

1. **Validate** before building:
   ```bash
   ./build.sh --dry-run
   ```

2. **Build** the Flatpak:
   ```bash
   ./build.sh
   ```

3. **Test** the build:
   ```bash
   ./test.sh
   ```

4. **Debug** if issues occur:
   ```bash
   ./debug.sh
   ```

5. **Deploy** when ready:
   ```bash
   ./deploy.sh
   ```

## Troubleshooting

- **flatpak-builder not found**: Use `--dry-run` to validate, or install flatpak-builder
- **Build fails**: Run `./debug.sh` to identify issues
- **Permission errors**: Ensure scripts are executable: `chmod +x *.sh`
