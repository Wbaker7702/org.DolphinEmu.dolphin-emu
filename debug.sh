#!/bin/bash
# Debug script for Dolphin Emulator Flatpak
# Helps identify and fix common build/deployment issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Dolphin Emulator Flatpak - Debug Tool${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}\n"

ISSUES_FOUND=0
WARNINGS=0

# Function to report issues
report_issue() {
    echo -e "${RED}✗ ISSUE:${NC} $1"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

report_warning() {
    echo -e "${YELLOW}⚠ WARNING:${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

report_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

# Check 1: File existence and permissions
echo -e "${CYAN}[1/10] Checking file existence and permissions...${NC}"
for file in "org.DolphinEmu.dolphin-emu.yml" "org.DolphinEmu.dolphin-emu.metainfo.xml" "dolphin-emu-wrapper" "README.md"; do
    if [ ! -f "$file" ]; then
        report_issue "Required file missing: $file"
    elif [ "$file" = "dolphin-emu-wrapper" ] && [ ! -x "$file" ]; then
        report_issue "Wrapper script is not executable: $file"
    else
        if [ "$file" = "dolphin-emu-wrapper" ] && [ -x "$file" ]; then
            report_ok "$file exists and is executable"
        else
            report_ok "$file exists"
        fi
    fi
done
echo ""

# Check 2: YAML syntax and structure
echo -e "${CYAN}[2/10] Checking YAML structure...${NC}"
if [ -f "org.DolphinEmu.dolphin-emu.yml" ]; then
    # Check for required fields
    if ! grep -q "app-id:" org.DolphinEmu.dolphin-emu.yml; then
        report_issue "Missing app-id in YAML"
    else
        APP_ID=$(grep "app-id:" org.DolphinEmu.dolphin-emu.yml | head -1 | awk '{print $2}')
        report_ok "app-id found: $APP_ID"
    fi
    
    if ! grep -q "runtime:" org.DolphinEmu.dolphin-emu.yml; then
        report_issue "Missing runtime in YAML"
    else
        RUNTIME=$(grep "runtime:" org.DolphinEmu.dolphin-emu.yml | head -1 | awk '{print $2}')
        report_ok "runtime found: $RUNTIME"
    fi
    
    # Check wrapper script reference
    if grep -q "path: dolphin-emu-wrapper" org.DolphinEmu.dolphin-emu.yml; then
        report_ok "Wrapper script referenced in YAML"
    else
        report_issue "Wrapper script not referenced in YAML"
    fi
    
    # Check for inline script (should not exist)
    if grep -q "type: script" org.DolphinEmu.dolphin-emu.yml && grep -q "dest-filename: dolphin-emu-wrapper" org.DolphinEmu.dolphin-emu.yml; then
        report_warning "Found inline script definition - should use file reference instead"
    fi
fi
echo ""

# Check 3: XML/metainfo validation
echo -e "${CYAN}[3/10] Checking metainfo.xml...${NC}"
if [ -f "org.DolphinEmu.dolphin-emu.metainfo.xml" ]; then
    # Check for typos
    if grep -qi "dolpin" org.DolphinEmu.dolphin-emu.metainfo.xml; then
        report_issue "Found typo 'dolpin' in metainfo.xml"
    else
        report_ok "No obvious typos in metainfo.xml"
    fi
    
    # Check for required elements
    if grep -q "<id>" org.DolphinEmu.dolphin-emu.metainfo.xml; then
        report_ok "App ID found in metainfo"
    else
        report_issue "App ID missing in metainfo"
    fi
    
    if grep -q "<name>" org.DolphinEmu.dolphin-emu.metainfo.xml; then
        report_ok "App name found in metainfo"
    else
        report_issue "App name missing in metainfo"
    fi
fi
echo ""

# Check 4: Wrapper script validation
echo -e "${CYAN}[4/10] Validating wrapper script...${NC}"
if [ -f "dolphin-emu-wrapper" ]; then
    # Syntax check
    if bash -n dolphin-emu-wrapper 2>/dev/null; then
        report_ok "Wrapper script syntax is valid"
    else
        report_issue "Wrapper script has syntax errors"
        bash -n dolphin-emu-wrapper 2>&1 || true
    fi
    
    # Check for shebang
    if head -1 dolphin-emu-wrapper | grep -q "^#!/"; then
        report_ok "Wrapper script has shebang"
    else
        report_warning "Wrapper script missing shebang"
    fi
    
    # Check for Discord IPC setup
    if grep -q "discord-ipc" dolphin-emu-wrapper; then
        report_ok "Discord IPC setup found in wrapper"
    else
        report_warning "Discord IPC setup not found in wrapper"
    fi
    
    # Check for dolphin-emu call
    if grep -q "dolphin-emu" dolphin-emu-wrapper; then
        report_ok "dolphin-emu call found in wrapper"
    else
        report_issue "dolphin-emu call missing in wrapper"
    fi
fi
echo ""

# Check 5: Build tools availability
echo -e "${CYAN}[5/10] Checking build tools...${NC}"
if command -v flatpak-builder &> /dev/null; then
    FLATPAK_BUILDER_VERSION=$(flatpak-builder --version 2>/dev/null || echo "unknown")
    report_ok "flatpak-builder found: $FLATPAK_BUILDER_VERSION"
    
    # Try to parse manifest
    if flatpak-builder --show-deps build org.DolphinEmu.dolphin-emu.yml > /dev/null 2>&1; then
        report_ok "Manifest can be parsed by flatpak-builder"
    else
        report_warning "Manifest parsing failed (may need runtime/SDK installed)"
    fi
else
    report_warning "flatpak-builder not found - install with: sudo apt install flatpak-builder"
fi

if command -v flatpak &> /dev/null; then
    FLATPAK_VERSION=$(flatpak --version 2>/dev/null || echo "unknown")
    report_ok "flatpak found: $FLATPAK_VERSION"
else
    report_warning "flatpak not found"
fi
echo ""

# Check 6: Dependencies and modules
echo -e "${CYAN}[6/10] Checking dependencies...${NC}"
if [ -f "org.DolphinEmu.dolphin-emu.yml" ]; then
    # Check for required modules
    MODULE_COUNT=$(grep -c "^- name:" org.DolphinEmu.dolphin-emu.yml || echo "0")
    report_ok "Found $MODULE_COUNT module(s) in manifest"
    
    # Check for dolphin-emu module
    if grep -q "name: dolphin-emu" org.DolphinEmu.dolphin-emu.yml; then
        report_ok "dolphin-emu module found"
    else
        report_issue "dolphin-emu module not found"
    fi
fi
echo ""

# Check 7: Git status and version control
echo -e "${CYAN}[7/10] Checking git status...${NC}"
if command -v git &> /dev/null && [ -d .git ]; then
    # Check for uncommitted changes
    if [ -z "$(git status --porcelain)" ]; then
        report_ok "Working directory is clean"
    else
        UNCOMMITTED=$(git status --porcelain | wc -l)
        report_warning "$UNCOMMITTED uncommitted file(s)"
    fi
    
    # Check branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    report_ok "Current branch: $CURRENT_BRANCH"
else
    report_warning "Not a git repository or git not found"
fi
echo ""

# Check 8: Screenshots
echo -e "${CYAN}[8/10] Checking screenshots...${NC}"
if [ -d "screenshots" ]; then
    SCREENSHOT_COUNT=$(find screenshots -name "*.png" -o -name "*.jpg" 2>/dev/null | wc -l)
    if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
        report_ok "Found $SCREENSHOT_COUNT screenshot(s)"
    else
        report_warning "Screenshots directory exists but is empty"
    fi
else
    report_warning "Screenshots directory not found"
fi
echo ""

# Check 9: Security checks
echo -e "${CYAN}[9/10] Running security checks...${NC}"
SECURITY_ISSUES=0

# Check for hardcoded sensitive paths
if grep -rq "/etc/passwd\|/etc/shadow\|/root" *.yml *.sh 2>/dev/null; then
    report_warning "Found potentially sensitive paths in files"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check wrapper script for proper quoting
if [ -f "dolphin-emu-wrapper" ]; then
    if grep -q '\$@' dolphin-emu-wrapper && ! grep -q '"\$@"' dolphin-emu-wrapper; then
        report_warning "Wrapper script may need better argument quoting"
        SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
    fi
fi

if [ $SECURITY_ISSUES -eq 0 ]; then
    report_ok "No obvious security issues found"
fi
echo ""

# Check 10: Build configuration
echo -e "${CYAN}[10/10] Checking build configuration...${NC}"
if [ -f "org.DolphinEmu.dolphin-emu.yml" ]; then
    # Check build type
    if grep -q "CMAKE_BUILD_TYPE" org.DolphinEmu.dolphin-emu.yml; then
        BUILD_TYPE=$(grep "CMAKE_BUILD_TYPE" org.DolphinEmu.dolphin-emu.yml | grep -oP '(?<=-DCMAKE_BUILD_TYPE=)\w+' || echo "unknown")
        report_ok "Build type: $BUILD_TYPE"
    fi
    
    # Check for cleanup rules
    if grep -q "cleanup:" org.DolphinEmu.dolphin-emu.yml; then
        report_ok "Cleanup rules found"
    else
        report_warning "No cleanup rules found"
    fi
fi
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Debug Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! No issues found.${NC}\n"
    exit 0
elif [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${YELLOW}⚠ Found $WARNINGS warning(s) but no critical issues${NC}\n"
    exit 0
else
    echo -e "${RED}✗ Found $ISSUES_FOUND critical issue(s) and $WARNINGS warning(s)${NC}\n"
    echo -e "Recommended actions:"
    echo -e "  1. Fix all critical issues listed above"
    echo -e "  2. Review warnings and address as needed"
    echo -e "  3. Run ${CYAN}./validate.sh${NC} and ${CYAN}./test.sh${NC} again"
    echo -e "  4. Run ${CYAN}./deploy.sh${NC} before deploying\n"
    exit 1
fi
