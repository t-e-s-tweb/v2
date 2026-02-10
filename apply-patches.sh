#!/bin/bash

# apply-patches.sh - Script to apply v2rayNG custom outbound tag and raw config patches
# Usage: ./apply-patches.sh [path-to-v2rayng-repo]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the v2rayNG repository path
if [ -z "$1" ]; then
    V2RAYNG_DIR="$(pwd)"
else
    V2RAYNG_DIR="$1"
fi

echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}v2rayNG Custom Features Patch Application${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""

# Check if we're in a git repository
cd "$V2RAYNG_DIR"
if [ ! -d ".git" ]; then
    echo -e "${RED}Error: Not a git repository. Please run this script from the v2rayNG repository root.${NC}"
    exit 1
fi

echo -e "${GREEN}Working directory: $(pwd)${NC}"
echo ""

# Function to apply a patch
apply_patch() {
    local patch_file="$1"
    local patch_name="$2"
    
    echo -e "${YELLOW}Applying $patch_name...${NC}"
    
    if [ ! -f "$patch_file" ]; then
        echo -e "${RED}Error: Patch file not found: $patch_file${NC}"
        return 1
    fi
    
    if git apply --check "$patch_file" 2>/dev/null; then
        if git apply "$patch_file"; then
            echo -e "${GREEN}✓ $patch_name applied successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Failed to apply $patch_name${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ $patch_name cannot be applied cleanly (may already be applied or conflicts exist)${NC}"
        echo -e "${YELLOW}  Trying with --3way option...${NC}"
        
        if git apply --3way "$patch_file" 2>/dev/null; then
            echo -e "${GREEN}✓ $patch_name applied with --3way${NC}"
            return 0
        else
            echo -e "${RED}✗ Still failed. Please apply manually.${NC}"
            return 1
        fi
    fi
}

# Apply patches
FAILED=0

apply_patch "$SCRIPT_DIR/01-custom-outbound-tag.patch" "Patch 01: Custom Outbound Tag" || FAILED=$((FAILED + 1))
echo ""

apply_patch "$SCRIPT_DIR/02-view-raw-config.patch" "Patch 02: View Raw Config" || FAILED=$((FAILED + 1))
echo ""

# Summary
echo -e "${YELLOW}============================================${NC}"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All patches applied successfully!${NC}"
    echo ""
    echo -e "${GREEN}Modified files:${NC}"
    git status --short
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Open the project in Android Studio"
    echo "  2. Sync project with Gradle files"
    echo "  3. Build and run"
else
    echo -e "${RED}$FAILED patch(es) failed to apply.${NC}"
    echo ""
    echo -e "${YELLOW}Please check the errors above and:${NC}"
    echo "  1. Ensure you're using the latest v2rayNG master branch"
    echo "  2. Or apply the patches manually following the README.md"
fi
echo -e "${YELLOW}============================================${NC}"

exit $FAILED
