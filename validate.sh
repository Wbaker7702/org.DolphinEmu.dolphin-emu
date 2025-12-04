#!/bin/bash
# Validation script for Dolphin Emulator Flatpak manifest
# Checks for common issues and validates the manifest structure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Helper function to safely increment counters
increment_errors() { ((ERRORS++)) || true; }
increment_warnings() { ((WARNINGS++)) || true; }

echo -e "${BLUE}Validating Dolphin Emulator Flatpak manifest...${NC}\n"

# Check if required files exist
echo -e "${BLUE}Checking required files...${NC}"
REQUIRED_FILES=(
    "org.DolphinEmu.dolphin-emu.yml"
    "org.DolphinEmu.dolphin-emu.metainfo.xml"
    "dolphin-emu-wrapper"
    "README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file exists"
    else
        echo -e "  ${RED}✗${NC} $file is missing"
        increment_errors
    fi
done

# Check if wrapper script is executable
if [ -f "dolphin-emu-wrapper" ]; then
    if [ -x "dolphin-emu-wrapper" ]; then
        echo -e "  ${GREEN}✓${NC} dolphin-emu-wrapper is executable"
    else
        echo -e "  ${YELLOW}⚠${NC} dolphin-emu-wrapper is not executable"
        increment_warnings
    fi
fi

# Validate YAML syntax (if yamllint is available)
echo -e "\n${BLUE}Validating YAML syntax...${NC}"
if command -v yamllint &> /dev/null; then
    if yamllint org.DolphinEmu.dolphin-emu.yml > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} YAML syntax is valid"
    else
        echo -e "  ${RED}✗${NC} YAML syntax errors found"
        yamllint org.DolphinEmu.dolphin-emu.yml || true
        increment_errors
    fi
else
    echo -e "  ${YELLOW}⚠${NC} yamllint not found, skipping YAML validation"
    increment_warnings
fi

# Validate XML syntax (if xmllint is available)
echo -e "\n${BLUE}Validating XML syntax...${NC}"
if command -v xmllint &> /dev/null; then
    if xmllint --noout org.DolphinEmu.dolphin-emu.metainfo.xml 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} XML syntax is valid"
    else
        echo -e "  ${RED}✗${NC} XML syntax errors found"
        xmllint --noout org.DolphinEmu.dolphin-emu.metainfo.xml || true
        increment_errors
    fi
else
    echo -e "  ${YELLOW}⚠${NC} xmllint not found, skipping XML validation"
    increment_warnings
fi

# Check for common issues in YAML
echo -e "\n${BLUE}Checking for common issues...${NC}"

# Check if wrapper script is referenced correctly
if grep -q "dolphin-emu-wrapper" org.DolphinEmu.dolphin-emu.yml; then
    if grep -q "type: file" org.DolphinEmu.dolphin-emu.yml && grep -q "path: dolphin-emu-wrapper" org.DolphinEmu.dolphin-emu.yml; then
        echo -e "  ${GREEN}✓${NC} Wrapper script is properly referenced"
    else
        echo -e "  ${YELLOW}⚠${NC} Wrapper script reference may need checking"
        increment_warnings
    fi
fi

# Check for typos
if grep -qi "dolpin" org.DolphinEmu.dolphin-emu.metainfo.xml; then
    echo -e "  ${RED}✗${NC} Found typo 'dolpin' (should be 'dolphin')"
    increment_errors
else
    echo -e "  ${GREEN}✓${NC} No obvious typos found"
fi

# Check if screenshots exist
echo -e "\n${BLUE}Checking screenshots...${NC}"
if [ -d "screenshots" ]; then
    SCREENSHOT_COUNT=$(find screenshots -name "*.png" -o -name "*.jpg" | wc -l)
    if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Found $SCREENSHOT_COUNT screenshot(s)"
    else
        echo -e "  ${YELLOW}⚠${NC} No screenshots found"
        increment_warnings
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Screenshots directory not found"
    increment_warnings
fi

# Summary
echo -e "\n${BLUE}Validation Summary:${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "  ${GREEN}✓ All checks passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "  ${YELLOW}⚠ Validation completed with $WARNINGS warning(s) (no errors)${NC}"
    exit 0
else
    echo -e "  ${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
