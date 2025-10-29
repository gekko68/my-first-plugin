#!/bin/bash
#
# Example Bash Script
# Demonstrates the bash-executor skill capabilities
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

echo -e "${GREEN}═══════════════════════════════════${NC}"
echo -e "${GREEN}Bash Executor - Example Script${NC}"
echo -e "${GREEN}═══════════════════════════════════${NC}"
echo ""

# 1. System information
log "System Information:"
echo "  OS: $(uname -s)"
echo "  Kernel: $(uname -r)"
echo "  Hostname: $(hostname)"
echo "  User: $(whoami)"
echo ""

# 2. Directory information
log "Directory Information:"
echo "  Current: $(pwd)"
echo "  Home: $HOME"
echo "  Files in current directory:"
ls -lh | head -10
echo ""

# 3. Date/Time
log "Date and Time:"
echo "  Date: $(date '+%Y-%m-%d')"
echo "  Time: $(date '+%H:%M:%S')"
echo "  Timezone: $(date '+%Z')"
echo ""

# 4. Text processing example
log "Text Processing Example:"
echo "Creating sample data..."
cat > /tmp/sample.txt << EOF
apple
banana
cherry
date
elderberry
EOF

echo "Sample file created with $(wc -l < /tmp/sample.txt) lines"
echo "Lines starting with 'a' or 'c':"
grep -E '^[ac]' /tmp/sample.txt | sed 's/^/  /'
rm -f /tmp/sample.txt
echo ""

# 5. Command pipeline example
log "Pipeline Example:"
echo "Finding largest directories in current path:"
du -sh ./* 2>/dev/null | sort -hr | head -5 | sed 's/^/  /'
echo ""

# 6. Success
echo -e "${GREEN}═══════════════════════════════════${NC}"
echo -e "${GREEN}✓ Example completed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════${NC}"
