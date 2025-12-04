#!/bin/bash
# Setup script for Flatpak build environment
# Installs required runtime and SDK

set -e

export PATH="/usr/bin:$PATH"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Setting up Flatpak build environment...${NC}\n"

# Check if flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo -e "${YELLOW}Installing flatpak and flatpak-builder...${NC}"
    sudo apt update
    sudo apt install -y flatpak flatpak-builder
fi

# Add Flathub remote
echo -e "${BLUE}Adding Flathub remote...${NC}"
if ! flatpak remote-list | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    echo -e "${GREEN}✓ Flathub remote added${NC}"
else
    echo -e "${GREEN}✓ Flathub remote already exists${NC}"
fi

# Install KDE Platform runtime and SDK (version 6.8)
echo -e "${BLUE}Installing KDE Platform 6.8 runtime and SDK...${NC}"
echo -e "${YELLOW}This may take a while (downloading ~1-2GB)...${NC}\n"

flatpak install -y flathub \
    org.kde.Platform//6.8 \
    org.kde.Sdk//6.8

echo -e "\n${GREEN}✓ Build environment setup complete!${NC}"
echo -e "\nYou can now run:"
echo -e "  ${YELLOW}./build.sh${NC}              # Build the Flatpak"
echo -e "  ${YELLOW}./build.sh --install${NC}    # Build and install"
