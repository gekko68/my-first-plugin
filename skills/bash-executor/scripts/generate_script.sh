#!/bin/bash
#
# Bash Script Generator - Creates production-ready script templates
# Usage: bash generate_script.sh <script-name> [description]
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_NAME="${1:-}"
DESCRIPTION="${2:-Script description}"

if [[ -z "$SCRIPT_NAME" ]]; then
    echo -e "${RED}Error: Script name is required${NC}"
    echo "Usage: $0 <script-name> [description]"
    exit 1
fi

# Ensure .sh extension
if [[ ! "$SCRIPT_NAME" =~ \.sh$ ]]; then
    SCRIPT_NAME="${SCRIPT_NAME}.sh"
fi

# Check if file exists
if [[ -f "$SCRIPT_NAME" ]]; then
    echo -e "${YELLOW}Warning: File already exists: $SCRIPT_NAME${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 0
    fi
fi

# Generate script
cat > "$SCRIPT_NAME" << 'SCRIPT_TEMPLATE'
#!/bin/bash
#
# SCRIPT_NAME_PLACEHOLDER
# DESCRIPTION_PLACEHOLDER
#
# Usage: bash SCRIPT_NAME_PLACEHOLDER [options]
#

set -euo pipefail

# ════════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════════

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ════════════════════════════════════════════════════════════════
# Functions
# ════════════════════════════════════════════════════════════════

# Print colored message
log() {
    local level="$1"
    shift
    case "$level" in
        INFO)
            echo -e "${GREEN}[INFO]${NC} $*"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $*"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} $*" >&2
            ;;
        *)
            echo "$*"
            ;;
    esac
}

# Error handler
error_exit() {
    log ERROR "$1"
    exit "${2:-1}"
}

# Cleanup function
cleanup() {
    log INFO "Cleaning up..."
    # Add cleanup tasks here
}

# Setup trap for cleanup
trap cleanup EXIT ERR

# Display usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

DESCRIPTION_PLACEHOLDER

Options:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -d, --dry-run       Perform a dry run without making changes

Examples:
    $(basename "$0")
    $(basename "$0") --verbose
    $(basename "$0") --dry-run

EOF
    exit 0
}

# ════════════════════════════════════════════════════════════════
# Main Logic
# ════════════════════════════════════════════════════════════════

main() {
    # Parse arguments
    local VERBOSE=0
    local DRY_RUN=0
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=1
                shift
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
    
    # Validate prerequisites
    log INFO "Starting SCRIPT_NAME_PLACEHOLDER..."
    
    if [[ $VERBOSE -eq 1 ]]; then
        log INFO "Verbose mode enabled"
    fi
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log WARN "Dry run mode - no changes will be made"
    fi
    
    # ─────────────────────────────────────────────────────────────
    # Your main logic goes here
    # ─────────────────────────────────────────────────────────────
    
    log INFO "Performing main task..."
    
    # Example: File operations
    # if [[ -f "input.txt" ]]; then
    #     log INFO "Processing input.txt..."
    #     # Process file
    # else
    #     error_exit "input.txt not found"
    # fi
    
    # Example: Command execution
    # if some_command; then
    #     log INFO "Command succeeded"
    # else
    #     error_exit "Command failed"
    # fi
    
    # ─────────────────────────────────────────────────────────────
    
    log INFO "Completed successfully!"
}

# ════════════════════════════════════════════════════════════════
# Entry Point
# ════════════════════════════════════════════════════════════════

main "$@"
SCRIPT_TEMPLATE

# Replace placeholders
sed -i.bak "s/SCRIPT_NAME_PLACEHOLDER/$SCRIPT_NAME/g" "$SCRIPT_NAME"
sed -i.bak "s/DESCRIPTION_PLACEHOLDER/$DESCRIPTION/g" "$SCRIPT_NAME"
rm -f "${SCRIPT_NAME}.bak"

# Make executable
chmod +x "$SCRIPT_NAME"

# Display success message
echo -e "${GREEN}✓ Script created successfully!${NC}"
echo ""
echo "File: $SCRIPT_NAME"
echo "Description: $DESCRIPTION"
echo ""
echo "Next steps:"
echo "  1. Edit the script: vim $SCRIPT_NAME"
echo "  2. Add your logic in the main() function"
echo "  3. Test the script: bash $SCRIPT_NAME"
echo ""
echo -e "${YELLOW}Template includes:${NC}"
echo "  ✓ Error handling with set -euo pipefail"
echo "  ✓ Colored logging (INFO, WARN, ERROR)"
echo "  ✓ Cleanup trap for EXIT and ERR"
echo "  ✓ Argument parsing with -h, -v, -d"
echo "  ✓ Usage documentation"
echo "  ✓ Best practices structure"
