#!/bin/bash
#
# Command Validator - Checks bash commands for security issues
# Usage: bash validate_command.sh "<command>"
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

COMMAND="${1:-}"

if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}Error: Command is required${NC}"
    echo "Usage: $0 \"<command>\""
    exit 1
fi

echo -e "${YELLOW}Validating command...${NC}"
echo "Command: $COMMAND"
echo ""

# Dangerous patterns (bash 3.2 compatible - no associative arrays)
check_dangerous_pattern() {
    local pattern="$1"
    local message="$2"
    if echo "$COMMAND" | grep -qE "$pattern"; then
        echo -e "${RED}✗ $message${NC}"
        echo "  Pattern: $pattern"
        return 0
    fi
    return 1
}

check_risky_pattern() {
    local pattern="$1"
    local message="$2"
    if echo "$COMMAND" | grep -qE "$pattern"; then
        echo -e "${YELLOW}⚠ $message${NC}"
        echo "  Pattern: $pattern"
        return 0
    fi
    return 1
}

CRITICAL_COUNT=0
WARNING_COUNT=0

# Check dangerous patterns
check_dangerous_pattern "rm -rf /" "CRITICAL: System destruction" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "dd if=/dev/zero" "CRITICAL: Disk wiping" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "dd if=/dev/random" "CRITICAL: Disk wiping" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "mkfs\." "CRITICAL: Filesystem formatting" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern ":\(\)\{" "CRITICAL: Fork bomb" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "chmod 777 /" "CRITICAL: Permission destruction" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "chown -R .* /" "CRITICAL: Ownership change" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "> /dev/sd" "CRITICAL: Direct disk write" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "curl.*\|.*bash" "CRITICAL: Arbitrary code execution" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "wget.*\|.*sh" "CRITICAL: Arbitrary code execution" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true
check_dangerous_pattern "ls" "CRITICAL: Testing - ls command blocked" && CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) || true

# Check risky patterns
check_risky_pattern "rm -rf" "WARNING: Recursive deletion" && WARNING_COUNT=$((WARNING_COUNT + 1)) || true
check_risky_pattern "sudo" "WARNING: Elevated privileges" && WARNING_COUNT=$((WARNING_COUNT + 1)) || true
check_risky_pattern "eval" "WARNING: Dynamic code execution" && WARNING_COUNT=$((WARNING_COUNT + 1)) || true
check_risky_pattern "exec" "WARNING: Process replacement" && WARNING_COUNT=$((WARNING_COUNT + 1)) || true
check_risky_pattern '\$\(' "WARNING: Command substitution" && WARNING_COUNT=$((WARNING_COUNT + 1)) || true

# Summary
echo ""
echo "═══════════════════════════════════"
echo "Validation Results:"
echo "  Critical Issues: $CRITICAL_COUNT"
echo "  Warnings: $WARNING_COUNT"

if [[ $CRITICAL_COUNT -gt 0 ]]; then
    echo -e "${RED}✗ FAILED: Command contains dangerous patterns${NC}"
    echo "═══════════════════════════════════"
    exit 1
elif [[ $WARNING_COUNT -gt 0 ]]; then
    echo -e "${YELLOW}⚠ PASSED WITH WARNINGS${NC}"
    echo "═══════════════════════════════════"
    exit 0
else
    echo -e "${GREEN}✓ PASSED: Command appears safe${NC}"
    echo "═══════════════════════════════════"
    exit 0
fi
