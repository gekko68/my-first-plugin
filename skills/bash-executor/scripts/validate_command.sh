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

# Dangerous patterns
declare -A DANGEROUS_PATTERNS=(
    ["rm -rf /"]="CRITICAL: System destruction"
    ["dd if=/dev/zero"]="CRITICAL: Disk wiping"
    ["dd if=/dev/random"]="CRITICAL: Disk wiping"
    ["mkfs."]="CRITICAL: Filesystem formatting"
    [":(){ :|:& };:"]="CRITICAL: Fork bomb"
    ["chmod 777 /"]="CRITICAL: Permission destruction"
    ["chown -R .* /"]="CRITICAL: Ownership change"
    ["> /dev/sd"]="CRITICAL: Direct disk write"
    ["curl.*|.*bash"]="CRITICAL: Arbitrary code execution"
    ["wget.*|.*sh"]="CRITICAL: Arbitrary code execution"
)

# Risky patterns
declare -A RISKY_PATTERNS=(
    ["rm -rf"]="WARNING: Recursive deletion"
    ["sudo"]="WARNING: Elevated privileges"
    ["eval"]="WARNING: Dynamic code execution"
    ["exec"]="WARNING: Process replacement"
    ["\\\$\("]="WARNING: Command substitution"
)

CRITICAL_COUNT=0
WARNING_COUNT=0

# Check dangerous patterns
for pattern in "${!DANGEROUS_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qE "$pattern"; then
        echo -e "${RED}✗ ${DANGEROUS_PATTERNS[$pattern]}${NC}"
        echo "  Pattern: $pattern"
        CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    fi
done

# Check risky patterns
for pattern in "${!RISKY_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qE "$pattern"; then
        echo -e "${YELLOW}⚠ ${RISKY_PATTERNS[$pattern]}${NC}"
        echo "  Pattern: $pattern"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
done

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
