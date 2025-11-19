#!/bin/bash

##############################################################################
# DDoS Defense Lab - Reset Script
# Removes all iptables rules and restores default policy
##############################################################################

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}"
echo "═══════════════════════════════════════════════════════════"
echo "  iptables Reset - Removing Defense Rules"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Error: Must run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}[*] Flushing all
