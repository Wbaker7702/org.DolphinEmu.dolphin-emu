#!/bin/bash
# Development Environment Setup Script
# Sets up the development environment for building Dolphin Emulator Flatpak

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

export PATH="/usr/bin:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Dolphin Emulator - Development Environment Setup${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}\n"

# Step 1: Check prerequisites
echo -e "${CYAN}[1/6] Checking prerequisites...${NC}"
MISSING_DEPS=()

if ! command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}⚠ flatpak not found${NC}"
    MISSING_DEPS+=("flatpak")
else
    FLATPAK_VERSION=$(flatpak --version)
    echo -e "${GREEN}✓${NC} $FLATPAK_VERSION"
fi

if ! command -v flatpak-builder &> /dev/null; then
    echo -e "${YELLOW}⚠ flatpak-builder not found${NC}"
    MISSING_DEPS+=("flatpak-builder")
else
    BUILDER_VERSION=$(flatpak-builder --version)
    echo -e "${GREEN}✓${NC} $BUILDER_VERSION"
fi

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Installing missing dependencies...${NC}"
    sudo apt update
    sudo apt install -y "${MISSING_DEPS[@]}"
fi
echo ""

# Step 2: Configure Flathub remote
echo -e "${CYAN}[2/6] Configuring Flathub remote...${NC}"
if flatpak remote-list --system | grep -q flathub; then
    echo -e "${GREEN}✓ Flathub remote already configured${NC}"
else
    echo -e "${YELLOW}Adding Flathub remote...${NC}"
    # Try to download repo file manually first
    if curl -o /tmp/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then
        sudo flatpak remote-add --if-not-exists --system flathub /tmp/flathub.flatpakrepo
        echo -e "${GREEN}✓ Flathub remote added${NC}"
    else
        echo -e "${RED}✗ Could not download Flathub repo file${NC}"
        echo -e "${YELLOW}  Try manually: flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo${NC}"
    fi
fi
echo ""

# Step 3: Check network connectivity
echo -e "${CYAN}[3/6] Checking network connectivity...${NC}"
if curl -s --max-time 5 https://dl.flathub.org/repo/summary.idx > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Network connectivity OK${NC}"
    NETWORK_OK=true
else
    echo -e "${YELLOW}⚠ Network connectivity issue detected${NC}"
    NETWORK_OK=false
fi
echo ""

# Step 4: Install KDE Platform runtime and SDK
echo -e "${CYAN}[4/6] Installing KDE Platform 6.8 runtime and SDK...${NC}"
RUNTIME_INSTALLED=false
SDK_INSTALLED=false

# Check if already installed
if flatpak list --system | grep -q "org.kde.Platform.*6.8"; then
    echo -e "${GREEN}✓ KDE Platform 6.8 already installed${NC}"
    RUNTIME_INSTALLED=true
else
    echo -e "${YELLOW}Installing KDE Platform 6.8...${NC}"
    if [ "$NETWORK_OK" = true ]; then
        if sudo flatpak install --system -y flathub org.kde.Platform//6.8 2>&1 | grep -q "error"; then
            echo -e "${RED}✗ Installation failed (network/DNS issue)${NC}"
            echo -e "${YELLOW}  See DNS_NETWORK_ISSUE.md for troubleshooting${NC}"
        else
            echo -e "${GREEN}✓ KDE Platform 6.8 installed${NC}"
            RUNTIME_INSTALLED=true
        fi
    else
        echo -e "${YELLOW}⚠ Skipping (network issue)${NC}"
    fi
fi

if flatpak list --system | grep -q "org.kde.Sdk.*6.8"; then
    echo -e "${GREEN}✓ KDE SDK 6.8 already installed${NC}"
    SDK_INSTALLED=true
else
    echo -e "${YELLOW}Installing KDE SDK 6.8...${NC}"
    if [ "$NETWORK_OK" = true ] && [ "$RUNTIME_INSTALLED" = true ]; then
        if sudo flatpak install --system -y flathub org.kde.Sdk//6.8 2>&1 | grep -q "error"; then
            echo -e "${RED}✗ Installation failed (network/DNS issue)${NC}"
        else
            echo -e "${GREEN}✓ KDE SDK 6.8 installed${NC}"
            SDK_INSTALLED=true
        fi
    else
        echo -e "${YELLOW}⚠ Skipping (network or runtime issue)${NC}"
    fi
fi
echo ""

# Step 5: Verify installation
echo -e "${CYAN}[5/6] Verifying installation...${NC}"
if [ "$RUNTIME_INSTALLED" = true ] && [ "$SDK_INSTALLED" = true ]; then
    echo -e "${GREEN}✓ Runtime and SDK installed${NC}"
    INSTALLATION_COMPLETE=true
else
    echo -e "${YELLOW}⚠ Runtime/SDK installation incomplete${NC}"
    INSTALLATION_COMPLETE=false
fi
echo ""

# Step 6: Test build readiness
echo -e "${CYAN}[6/6] Testing build readiness...${NC}"
if [ "$INSTALLATION_COMPLETE" = true ]; then
    echo -e "${GREEN}✓ All dependencies installed${NC}"
    echo -e "\n${GREEN}Development environment ready!${NC}"
    echo -e "\nYou can now run:"
    echo -e "  ${CYAN}./build.sh --clean${NC}        # Build the Flatpak"
    echo -e "  ${CYAN}./build.sh --install${NC}      # Build and install"
else
    echo -e "${YELLOW}⚠ Development environment setup incomplete${NC}"
    echo -e "\n${YELLOW}To complete setup:${NC}"
    echo -e "  1. Resolve network/DNS issues (see DNS_NETWORK_ISSUE.md)"
    echo -e "  2. Run: ${CYAN}sudo flatpak install --system -y flathub org.kde.Platform//6.8 org.kde.Sdk//6.8${NC}"
    echo -e "  3. Or install from alternative source/mirror"
    echo -e "\n${YELLOW}You can still validate the manifest:${NC}"
    echo -e "  ${CYAN}./build.sh --dry-run${NC}      # Validate without building"
    echo -e "  ${CYAN}./validate.sh${NC}             # Run validation checks"
fi

echo -e "\n${BLUE}════════════════════════════════════════════════${NC}"
if [ "$INSTALLATION_COMPLETE" = true ]; then
    echo -e "${GREEN}Setup Complete! Ready for development.${NC}"
    exit 0
else
    echo -e "${YELLOW}Setup Incomplete - Network/DNS issue detected.${NC}"
    exit 1
fi
