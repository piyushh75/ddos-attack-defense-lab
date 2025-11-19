#!/bin/bash

##############################################################################
# DDoS Defense Lab - Kali Attack System Setup
# Automated setup script for attack system
##############################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
ATTACKER_IP="192.168.153.128"
TARGET_IP="192.168.153.129"

echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "  Kali Attack System Setup"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Error: This script must be run as root${NC}"
    exit 1
fi

# Update system
echo -e "${YELLOW}[1/4] Updating Kali Linux...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"

# Install/verify tools
echo -e "${YELLOW}[2/4] Installing/verifying attack tools...${NC}"
apt-get install -y hping3 apache2-utils curl net-tools
echo -e "${GREEN}✓ Tools verified${NC}"

# Verify hping3
echo -e "${YELLOW}[3/4] Verifying hping3 installation...${NC}"
if command -v hping3 &> /dev/null; then
    HPING_VERSION=$(hping3 --version 2>&1 | head -1)
    echo -e "${GREEN}✓ hping3 installed: $HPING_VERSION${NC}"
else
    echo -e "${RED}❌ hping3 installation failed${NC}"
    exit 1
fi

# Test connectivity
echo -e "${YELLOW}[4/4] Testing target connectivity...${NC}"
echo "    Target IP: $TARGET_IP"
echo ""
if ping -c 1 -W 2 $TARGET_IP &> /dev/null; then
    echo -e "${GREEN}✓ Target is reachable${NC}"
    
    if curl -s http://$TARGET_IP > /dev/null; then
        echo -e "${GREEN}✓ HTTP service accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  Warning: HTTP service not responding${NC}"
    fi
else
    echo -e "${RED}❌ Cannot reach target${NC}"
    echo "    Check network configuration"
fi

# Display summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "✓ Attack tools installed"
echo "✓ System ready for testing"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Navigate to attack/ directory"
echo "  2. Run: sudo ./hping3-commands.sh"
echo ""
echo -e "${RED}[!] Remember: Use only in authorized environments${NC}"
