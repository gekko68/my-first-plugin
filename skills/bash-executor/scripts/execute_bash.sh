#!/bin/bash
#
# Bash Command/Script Executor with Security and Validation
# Usage: 
#   bash execute_bash.sh "<command>" [timeout]
#   bash execute_bash.sh script.sh [timeout]
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INPUT="${1:-}"
TIMEOUT="${2:-60}"
DRY_RUN="${DRY_RUN:-0}"
TEMP_DIR="/tmp/bash-executor-$$"

# Validation
if [[ -z "$INPUT" ]]; then
    echo -e "${RED}Error: Command or script file required${NC}"
    echo "Usage: $0 \"<command>\" [timeout]"
    echo "   or: $0 script.sh [timeout]"
    exit 1
fi

# Determine if input is a file or command
IS_FILE=0
if [[ -f "$INPUT" ]]; then
    IS_FILE=1
    SCRIPT_FILE="$INPUT"
    COMMAND=""
else
    IS_FILE=0
    COMMAND="$INPUT"
    SCRIPT_FILE=""
fi

# Function to validate command for dangerous patterns
validate_command() {
    local cmd="$1"
    
    # Dangerous patterns that should be blocked
    local dangerous_patterns=(
        "rm\s+-rf\s+/"
        "dd\s+if=/dev/zero"
        "dd\s+if=/dev/random"
        "mkfs\."
        ":\(\)\{\s*:\|:\&\s*\};\s*:"  # Fork bomb
        "chmod\s+-R\s+777\s+/"
        "chown\s+-R.*/"
        "curl.*\|.*bash"
        "wget.*\|.*bash"
        "curl.*\|.*sh"
        ">\s*/dev/sda"
        ">\s*/dev/sd"
    )
    
    echo -e "${YELLOW}Validating command for security issues...${NC}"
    
    local found_issues=0
    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$cmd" | grep -qE "$pattern"; then
            echo -e "${RED}⚠️  BLOCKED: Dangerous pattern detected: $pattern${NC}"
            found_issues=$((found_issues + 1))
        fi
    done
    
    # Warn about risky patterns (don't block, just warn)
    local risky_patterns=(
        "rm\s+-rf"
        "sudo"
        "eval"
        "curl"
        "wget"
    )
    
    for pattern in "${risky_patterns[@]}"; do
        if echo "$cmd" | grep -qE "$pattern"; then
            echo -e "${YELLOW}⚠️  Warning: Potentially risky pattern: $pattern${NC}"
        fi
    done
    
    if [[ $found_issues -gt 0 ]]; then
        echo -e "${RED}Validation failed: Command contains dangerous patterns${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Command validation passed${NC}"
    return 0
}

# Function to validate script file
validate_script() {
    local file="$1"
    
    echo -e "${YELLOW}Validating script file...${NC}"
    
    # Check if file is executable
    if [[ ! -x "$file" ]]; then
        echo -e "${YELLOW}⚠️  Script is not executable. Making it executable...${NC}"
        chmod +x "$file"
    fi
    
    # Check for shell shebang
    if ! head -n 1 "$file" | grep -q "^#!/"; then
        echo -e "${YELLOW}⚠️  No shebang found. Will execute with /bin/bash${NC}"
    fi
    
    # Read and validate script content
    local content
    content=$(cat "$file")
    validate_command "$content"
    
    return $?
}

# Create temp directory
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

# Perform validation
if [[ $IS_FILE -eq 1 ]]; then
    if [[ ! -f "$SCRIPT_FILE" ]]; then
        echo -e "${RED}Error: Script file not found: $SCRIPT_FILE${NC}"
        exit 1
    fi
    
    if ! validate_script "$SCRIPT_FILE"; then
        exit 1
    fi
else
    if ! validate_command "$COMMAND"; then
        exit 1
    fi
fi

# Dry run mode
if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${BLUE}DRY RUN MODE - No execution${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    if [[ $IS_FILE -eq 1 ]]; then
        echo "Would execute script: $SCRIPT_FILE"
        echo "Script contents:"
        echo "─────────────────────────────────────"
        cat "$SCRIPT_FILE"
        echo "─────────────────────────────────────"
    else
        echo "Would execute command: $COMMAND"
    fi
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    exit 0
fi

# Print execution info
echo -e "${GREEN}═══════════════════════════════════${NC}"
echo -e "${GREEN}Bash Executor${NC}"
echo -e "${GREEN}═══════════════════════════════════${NC}"
if [[ $IS_FILE -eq 1 ]]; then
    echo "Type: Script File"
    echo "File: $SCRIPT_FILE"
    echo "Size: $(stat -f%z "$SCRIPT_FILE" 2>/dev/null || stat -c%s "$SCRIPT_FILE" 2>/dev/null || echo "unknown") bytes"
else
    echo "Type: Command"
    echo "Command: $COMMAND"
fi
echo "Timeout: ${TIMEOUT}s"
echo "Working Dir: $(pwd)"
echo "Shell: $BASH_VERSION"
echo -e "${GREEN}═══════════════════════════════════${NC}"
echo ""

# Record start time
START_TIME=$(date +%s)

# Execute
echo -e "${YELLOW}Executing...${NC}"
echo ""

set +e  # Don't exit on error

EXIT_CODE=0

if [[ $IS_FILE -eq 1 ]]; then
    # Execute script file
    if command -v timeout &> /dev/null; then
        timeout "${TIMEOUT}s" bash "$SCRIPT_FILE"
        EXIT_CODE=$?
    elif command -v gtimeout &> /dev/null; then
        gtimeout "${TIMEOUT}s" bash "$SCRIPT_FILE"
        EXIT_CODE=$?
    else
        bash "$SCRIPT_FILE" &
        PID=$!
        {
            sleep "$TIMEOUT"
            kill -TERM $PID 2>/dev/null
            sleep 1
            kill -KILL $PID 2>/dev/null
        } &
        TIMEOUT_PID=$!
        wait $PID
        EXIT_CODE=$?
        kill $TIMEOUT_PID 2>/dev/null
    fi
else
    # Execute command
    if command -v timeout &> /dev/null; then
        timeout "${TIMEOUT}s" bash -c "$COMMAND"
        EXIT_CODE=$?
    elif command -v gtimeout &> /dev/null; then
        gtimeout "${TIMEOUT}s" bash -c "$COMMAND"
        EXIT_CODE=$?
    else
        bash -c "$COMMAND" &
        PID=$!
        {
            sleep "$TIMEOUT"
            kill -TERM $PID 2>/dev/null
            sleep 1
            kill -KILL $PID 2>/dev/null
        } &
        TIMEOUT_PID=$!
        wait $PID
        EXIT_CODE=$?
        kill $TIMEOUT_PID 2>/dev/null
    fi
fi

set -e

# Record end time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Print results
echo ""
echo -e "${GREEN}═══════════════════════════════════${NC}"

# Interpret exit code
if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ Execution completed successfully${NC}"
elif [[ $EXIT_CODE -eq 124 ]] || [[ $EXIT_CODE -eq 137 ]]; then
    echo -e "${RED}✗ Execution timed out after ${TIMEOUT}s${NC}"
elif [[ $EXIT_CODE -eq 126 ]]; then
    echo -e "${RED}✗ Permission denied${NC}"
elif [[ $EXIT_CODE -eq 127 ]]; then
    echo -e "${RED}✗ Command not found${NC}"
else
    echo -e "${RED}✗ Execution failed${NC}"
fi

echo "Exit Code: $EXIT_CODE"
echo "Duration: ${DURATION}s"
echo -e "${GREEN}═══════════════════════════════════${NC}"

exit $EXIT_CODE
