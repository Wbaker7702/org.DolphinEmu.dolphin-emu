#!/bin/bash
# Test script for Dolphin Emulator Flatpak
# Runs basic tests and checks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Running tests for Dolphin Emulator Flatpak...${NC}\n"

# Test 1: Run validation
echo -e "${BLUE}Test 1: Running validation...${NC}"
if ./validate.sh; then
    echo -e "${GREEN}✓ Validation passed${NC}\n"
else
    echo -e "${RED}✗ Validation failed${NC}\n"
    exit 1
fi

# Test 2: Check wrapper script syntax
echo -e "${BLUE}Test 2: Checking wrapper script syntax...${NC}"
if bash -n dolphin-emu-wrapper 2>/dev/null; then
    echo -e "${GREEN}✓ Wrapper script syntax is valid${NC}\n"
else
    echo -e "${RED}✗ Wrapper script has syntax errors${NC}\n"
    exit 1
fi

# Test 3: Check if flatpak-builder can parse the manifest
echo -e "${BLUE}Test 3: Checking Flatpak manifest parsing...${NC}"
if command -v flatpak-builder &> /dev/null; then
    if flatpak-builder --show-deps build org.DolphinEmu.dolphin-emu.yml > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Flatpak manifest can be parsed${NC}\n"
    else
        echo -e "${YELLOW}⚠ Could not fully parse manifest (may need dependencies)${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠ flatpak-builder not found, skipping manifest parse test${NC}\n"
fi

# Test 4: Check file permissions
echo -e "${BLUE}Test 4: Checking file permissions...${NC}"
if [ -x "dolphin-emu-wrapper" ]; then
    echo -e "${GREEN}✓ Wrapper script has execute permissions${NC}\n"
else
    echo -e "${RED}✗ Wrapper script missing execute permissions${NC}\n"
    exit 1
fi

# Test 5: Check for common security issues
echo -e "${BLUE}Test 5: Checking for security issues...${NC}"
SECURITY_ISSUES=0

# Check for hardcoded paths that might be problematic
if grep -q "/etc/passwd\|/etc/shadow" dolphin-emu-wrapper 2>/dev/null; then
    echo -e "  ${RED}✗ Found potentially problematic file access${NC}"
    ((SECURITY_ISSUES++))
fi

# Check wrapper script for proper quoting
if grep -q '\$@' dolphin-emu-wrapper && ! grep -q '"\$@"' dolphin-emu-wrapper; then
    echo -e "  ${YELLOW}⚠ Wrapper script may need better quoting${NC}"
    ((SECURITY_ISSUES++))
fi

if [ $SECURITY_ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ No obvious security issues found${NC}\n"
else
    echo -e "${YELLOW}⚠ Found $SECURITY_ISSUES potential security concern(s)${NC}\n"
fi

echo -e "${GREEN}All tests completed!${NC}"
