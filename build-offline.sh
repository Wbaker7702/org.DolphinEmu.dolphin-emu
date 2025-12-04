#!/bin/bash
# Offline build script - attempts build with existing runtimes
# Falls back to validation if runtime not available

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/usr/bin:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Attempting Flatpak build (offline mode)...${NC}\n"

# Check if runtime is available
RUNTIME_AVAILABLE=false
if flatpak list | grep -q "org.kde.Platform"; then
    RUNTIME_VERSION=$(flatpak list | grep "org.kde.Platform" | head -1 | awk '{print $2}' | cut -d'/' -f2)
    echo -e "${GREEN}✓ Found KDE Platform runtime: $RUNTIME_VERSION${NC}"
    
    # Check if it matches required version
    if [ "$RUNTIME_VERSION" = "6.8" ]; then
        RUNTIME_AVAILABLE=true
        echo -e "${GREEN}✓ Runtime version matches required (6.8)${NC}"
    else
        echo -e "${YELLOW}⚠ Runtime version $RUNTIME_VERSION found, but 6.8 is required${NC}"
    fi
else
    echo -e "${YELLOW}⚠ KDE Platform runtime not found${NC}"
fi

# Check if SDK is available
SDK_AVAILABLE=false
if flatpak list | grep -q "org.kde.Sdk"; then
    SDK_VERSION=$(flatpak list | grep "org.kde.Sdk" | head -1 | awk '{print $2}' | cut -d'/' -f2)
    echo -e "${GREEN}✓ Found KDE SDK: $SDK_VERSION${NC}"
    
    if [ "$SDK_VERSION" = "6.8" ]; then
        SDK_AVAILABLE=true
        echo -e "${GREEN}✓ SDK version matches required (6.8)${NC}"
    else
        echo -e "${YELLOW}⚠ SDK version $SDK_VERSION found, but 6.8 is required${NC}"
    fi
else
    echo -e "${YELLOW}⚠ KDE SDK not found${NC}"
fi

echo ""

if [ "$RUNTIME_AVAILABLE" = true ] && [ "$SDK_AVAILABLE" = true ]; then
    echo -e "${GREEN}All dependencies available! Proceeding with build...${NC}\n"
    
    # Clean build directories
    if [ -d "build" ] || [ -d ".flatpak-builder" ]; then
        echo -e "${YELLOW}Cleaning previous build...${NC}"
        rm -rf .flatpak-builder build repo
    fi
    
    # Attempt build
    echo -e "${BLUE}Building Flatpak...${NC}"
    if flatpak-builder --force-clean --repo=repo build org.DolphinEmu.dolphin-emu.yml; then
        echo -e "\n${GREEN}✓ Build completed successfully!${NC}"
        echo -e "\nBuild output:"
        ls -lh repo/ 2>/dev/null || echo "  (repo directory created)"
        exit 0
    else
        echo -e "\n${RED}✗ Build failed${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Required runtime/SDK not available.${NC}"
    echo -e "\nTo install dependencies:"
    echo -e "  1. Ensure network connectivity"
    echo -e "  2. Run: ${BLUE}./setup-build-env.sh${NC}"
    echo -e "  Or manually:"
    echo -e "     flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    echo -e "     flatpak install -y flathub org.kde.Platform//6.8 org.kde.Sdk//6.8"
    echo -e "\nRunning validation instead...\n"
    ./validate.sh
    exit 0
fi
