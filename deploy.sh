#!/bin/bash
# Deployment script for Dolphin Emulator Flatpak
# Prepares the package for deployment to Flathub

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Dolphin Emulator Flatpak - Deployment Checklist${NC}\n"

# Step 1: Run validation
echo -e "${BLUE}Step 1: Running validation...${NC}"
if ./validate.sh; then
    echo -e "${GREEN}✓ Validation passed${NC}\n"
else
    echo -e "${RED}✗ Validation failed - fix issues before deploying${NC}\n"
    exit 1
fi

# Step 2: Run tests
echo -e "${BLUE}Step 2: Running tests...${NC}"
if ./test.sh; then
    echo -e "${GREEN}✓ All tests passed${NC}\n"
else
    echo -e "${RED}✗ Tests failed - fix issues before deploying${NC}\n"
    exit 1
fi

# Step 3: Check git status
echo -e "${BLUE}Step 3: Checking git status...${NC}"
if command -v git &> /dev/null; then
    if [ -d .git ]; then
        if [ -z "$(git status --porcelain)" ]; then
            echo -e "${GREEN}✓ Working directory is clean${NC}"
        else
            echo -e "${YELLOW}⚠ Working directory has uncommitted changes:${NC}"
            git status --short
        fi
        
        # Check if we're on the right branch
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        echo -e "  Current branch: ${CURRENT_BRANCH}"
        
        # Check for uncommitted wrapper script changes
        if git diff --quiet dolphin-emu-wrapper 2>/dev/null; then
            echo -e "${GREEN}✓ Wrapper script is committed${NC}"
        else
            echo -e "${YELLOW}⚠ Wrapper script has uncommitted changes${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Not a git repository${NC}"
    fi
else
    echo -e "${YELLOW}⚠ git not found, skipping git checks${NC}"
fi
echo ""

# Step 4: Verify file structure
echo -e "${BLUE}Step 4: Verifying file structure...${NC}"
REQUIRED_FILES=(
    "org.DolphinEmu.dolphin-emu.yml"
    "org.DolphinEmu.dolphin-emu.metainfo.xml"
    "dolphin-emu-wrapper"
    "README.md"
)

ALL_FILES_OK=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file is missing"
        ALL_FILES_OK=false
    fi
done

if [ "$ALL_FILES_OK" = true ]; then
    echo -e "${GREEN}✓ All required files present${NC}\n"
else
    echo -e "${RED}✗ Missing required files${NC}\n"
    exit 1
fi

# Step 5: Check wrapper script
echo -e "${BLUE}Step 5: Verifying wrapper script...${NC}"
if [ -x "dolphin-emu-wrapper" ]; then
    if bash -n dolphin-emu-wrapper 2>/dev/null; then
        echo -e "${GREEN}✓ Wrapper script is valid and executable${NC}"
        
        # Check if wrapper is referenced in YAML
        if grep -q "path: dolphin-emu-wrapper" org.DolphinEmu.dolphin-emu.yml; then
            echo -e "${GREEN}✓ Wrapper script is properly referenced in YAML${NC}"
        else
            echo -e "${RED}✗ Wrapper script not referenced in YAML${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ Wrapper script has syntax errors${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Wrapper script is missing or not executable${NC}"
    exit 1
fi
echo ""

# Step 6: Check for common deployment issues
echo -e "${BLUE}Step 6: Checking for deployment issues...${NC}"
ISSUES_FOUND=0

# Check for hardcoded paths
if grep -q "/home/\|/tmp/" org.DolphinEmu.dolphin-emu.yml 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ Found potentially problematic hardcoded paths${NC}"
    ((ISSUES_FOUND++))
fi

# Check YAML for common mistakes
if grep -q "TODO\|FIXME\|XXX" org.DolphinEmu.dolphin-emu.yml 2>/dev/null; then
    echo -e "  ${YELLOW}⚠ Found TODO/FIXME comments in YAML${NC}"
    ((ISSUES_FOUND++))
fi

# Check metainfo version
if grep -q "<release version=" org.DolphinEmu.dolphin-emu.metainfo.xml 2>/dev/null; then
    LATEST_VERSION=$(grep -oP '(?<=version=")[^"]+' org.DolphinEmu.dolphin-emu.metainfo.xml | head -1)
    echo -e "  Latest version in metainfo: ${LATEST_VERSION}"
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ No deployment issues found${NC}\n"
else
    echo -e "${YELLOW}⚠ Found $ISSUES_FOUND potential issue(s)${NC}\n"
fi

# Step 7: Build readiness check
echo -e "${BLUE}Step 7: Build readiness check...${NC}"
if command -v flatpak-builder &> /dev/null; then
    echo -e "${GREEN}✓ flatpak-builder is available${NC}"
    
    # Try to parse the manifest
    if flatpak-builder --show-deps build org.DolphinEmu.dolphin-emu.yml > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Manifest can be parsed by flatpak-builder${NC}"
    else
        echo -e "${YELLOW}⚠ Manifest parsing had issues (may need runtime/SDK)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ flatpak-builder not found - install to test build${NC}"
    echo -e "  Install with: sudo apt install flatpak-builder"
fi
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}Deployment Checklist Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}\n"

echo -e "Next steps for deployment:"
echo -e "  1. Review all changes: ${YELLOW}git diff${NC}"
echo -e "  2. Commit changes: ${YELLOW}git commit -m 'Your commit message'${NC}"
echo -e "  3. Push to repository: ${YELLOW}git push${NC}"
echo -e "  4. Create pull request on Flathub (if applicable)"
echo -e "  5. Test build locally: ${YELLOW}./build.sh${NC}\n"

echo -e "${GREEN}Package is ready for deployment!${NC}"
