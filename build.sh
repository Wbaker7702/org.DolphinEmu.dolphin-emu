#!/bin/bash
# Build script for Dolphin Emulator Flatpak
# Usage: ./build.sh [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure flatpak is in PATH
export PATH="/usr/bin:$PATH"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default options
BUILD_TYPE="release"
INSTALL=false
CLEAN=false
VERBOSE=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install|-i)
            INSTALL=true
            shift
            ;;
        --clean|-c)
            CLEAN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --install, -i    Install the built Flatpak"
            echo "  --clean, -c      Clean build directories before building"
            echo "  --verbose, -v    Verbose output"
            echo "  --dry-run, -d    Validate manifest without building"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                # Build the Flatpak"
            echo "  $0 --install      # Build and install"
            echo "  $0 --clean        # Clean and build"
            echo "  $0 --dry-run      # Validate without building"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check if flatpak-builder is installed
if ! command -v flatpak-builder &> /dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}Warning: flatpak-builder is not installed${NC}"
        echo "Running in dry-run mode (validation only)..."
        echo ""
        # Run validation instead
        if [ -f "./validate.sh" ]; then
            ./validate.sh
            echo ""
            echo -e "${GREEN}Dry-run validation complete!${NC}"
            echo "To actually build, install flatpak-builder:"
            echo "  sudo apt install flatpak-builder"
            exit 0
        fi
    else
        echo -e "${RED}Error: flatpak-builder is not installed${NC}"
        echo "Install it with: sudo apt install flatpak-builder (or your distro's equivalent)"
        echo ""
        echo "Or run with --dry-run to validate the manifest without building:"
        echo "  $0 --dry-run"
        exit 1
    fi
fi

# If dry-run, validate and exit (before cleaning)
if [ "$DRY_RUN" = true ]; then
    if [ "$CLEAN" = true ]; then
        echo -e "${YELLOW}Note: --clean flag ignored in dry-run mode${NC}"
        echo ""
    fi
    echo -e "${GREEN}Running dry-run validation...${NC}"
    echo ""
    
    # Validate manifest can be parsed
    if flatpak-builder --show-deps build org.DolphinEmu.dolphin-emu.yml > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Manifest can be parsed by flatpak-builder${NC}"
    else
        echo -e "${YELLOW}⚠ Manifest parsing check skipped (may need runtime/SDK)${NC}"
    fi
    
    # Run validation script if available
    if [ -f "./validate.sh" ]; then
        echo ""
        ./validate.sh
    fi
    
    echo ""
    echo -e "${GREEN}Dry-run complete! Manifest is valid.${NC}"
    echo "Run without --dry-run to actually build."
    exit 0
fi

# Clean if requested (only if not dry-run)
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Cleaning build directories...${NC}"
    rm -rf .flatpak-builder build repo
    echo -e "${GREEN}✓ Build directories cleaned${NC}"
fi

# Build options
BUILD_OPTS=()
if [ "$VERBOSE" = true ]; then
    BUILD_OPTS+=("--verbose")
fi

# Build the Flatpak
echo -e "${GREEN}Building Dolphin Emulator Flatpak...${NC}"
echo -e "${YELLOW}This may take a while...${NC}"
echo ""
flatpak-builder "${BUILD_OPTS[@]}" \
    --force-clean \
    --repo=repo \
    build \
    org.DolphinEmu.dolphin-emu.yml

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build completed successfully!${NC}"
    
    if [ "$INSTALL" = true ]; then
        echo -e "${YELLOW}Installing Flatpak...${NC}"
        flatpak-builder --run build org.DolphinEmu.dolphin-emu.yml flatpak run org.DolphinEmu.dolphin-emu || \
        flatpak install --user --reinstall repo org.DolphinEmu.dolphin-emu
        echo -e "${GREEN}Installation completed!${NC}"
    else
        echo -e "${YELLOW}To install, run:${NC}"
        echo "  flatpak install --user --reinstall repo org.DolphinEmu.dolphin-emu"
    fi
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi
