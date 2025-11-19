#!/bin/bash

##############################################################################
# DDoS Defense Lab - Ubuntu Target Server Setup
# Automated setup script for target system
##############################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
TARGET_IP="192.168.153.129"
NETMASK="255.255.255.0"

echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "  Ubuntu Target Server Setup"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Error: This script must be run as root${NC}"
    exit 1
fi

# Update system
echo -e "${YELLOW}[1/5] Updating system packages...${NC}"
apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓ System updated${NC}"

# Install Apache
echo -e "${YELLOW}[2/5] Installing Apache2...${NC}"
apt-get install -y apache2 apache2-utils
systemctl enable apache2
systemctl start apache2
echo -e "${GREEN}✓ Apache2 installed and started${NC}"

# Install additional tools
echo -e "${YELLOW}[3/5] Installing monitoring tools...${NC}"
apt-get install -y net-tools iptables-persistent tcpdump htop
echo -e "${GREEN}✓ Tools installed${NC}"

# Configure network
echo -e "${YELLOW}[4/5] Configuring network...${NC}"
echo "    Target IP will be: $TARGET_IP"
echo "    Netmask: $NETMASK"
echo ""
echo -e "${RED}[!] Manual network configuration required${NC}"
echo "    Edit /etc/netplan/*.yaml with:"
echo "    network:"
echo "      version: 2"
echo "      renderer: networkd"
echo "      ethernets:"
echo "        ens33:  # or your interface name"
echo "          addresses:"
echo "            - $TARGET_IP/24"
echo ""
read -p "Press Enter when network is configured..."

# Test Apache
echo -e "${YELLOW}[5/5] Testing Apache installation...${NC}"
if curl -s http://localhost > /dev/null; then
    echo -e "${GREEN}✓ Apache is responding${NC}"
else
    echo -e "${RED}❌ Apache test failed${NC}"
    exit 1
fi

# Display summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "✓ Apache2 installed and running"
echo "✓ Monitoring tools installed"
echo "✓ System ready for testing"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Verify network configuration"
echo "  2. Test Apache from attack system"
echo "  3. Run baseline performance test"
echo ""
echo -e "${YELLOW}Test Apache access:${NC}"
echo "  curl http://$TARGET_IP"
