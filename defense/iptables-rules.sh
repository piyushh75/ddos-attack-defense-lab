#!/bin/bash

##############################################################################
# DDoS Defense Lab - Defense Script
# iptables Firewall Configuration for TCP SYN Flood Protection
#
# Author: Piyush Arora
# Purpose: Implement rate limiting and connection limiting defenses
##############################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Banner
echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "  DDoS Defense Lab - iptables Defense Configuration"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Error: This script must be run as root${NC}"
    exit 1
fi

# Backup existing rules
echo -e "${YELLOW}[*] Backing up existing iptables rules...${NC}"
iptables-save > /tmp/iptables-backup-$(date +%Y%m%d-%H%M%S).rules
echo -e "${GREEN}✓ Backup saved${NC}"

# Display current rules
echo ""
echo -e "${YELLOW}[*] Current iptables rules:${NC}"
iptables -L -n -v
echo ""

# Implement defense rules
echo -e "${GREEN}[*] Implementing TCP SYN flood defense rules...${NC}"
echo ""

# Rule 1: Rate Limiting
echo -e "${GREEN}[1/3] Applying rate limiting (50 connections/minute, burst 20)...${NC}"
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -m limit --limit 50/minute --limit-burst 20 -j ACCEPT

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Rate limiting rule applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply rate limiting rule${NC}"
    exit 1
fi

# Rule 2: Connection Limiting
echo -e "${GREEN}[2/3] Applying connection limiting (max 10 per IP)...${NC}"
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 -j DROP

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Connection limiting rule applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply connection limiting rule${NC}"
    exit 1
fi

# Rule 3: Drop remaining SYN packets
echo -e "${GREEN}[3/3] Dropping excess SYN packets...${NC}"
iptables -A INPUT -p tcp --dport 80 -j DROP

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Drop rule applied successfully${NC}"
else
    echo -e "${RED}❌ Failed to apply drop rule${NC}"
    exit 1
fi

# Save rules permanently
echo ""
echo -e "${YELLOW}[*] Saving iptables rules permanently...${NC}"

# For Ubuntu/Debian
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
    echo -e "${GREEN}✓ Rules saved with netfilter-persistent${NC}"
elif [ -f /etc/iptables/rules.v4 ]; then
    iptables-save > /etc/iptables/rules.v4
    echo -e "${GREEN}✓ Rules saved to /etc/iptables/rules.v4${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Could not save rules permanently${NC}"
    echo -e "${YELLOW}   Rules will be lost on reboot${NC}"
fi

# Display final configuration
echo ""
echo -e "${GREEN}[✓] Defense implementation completed!${NC}"
echo ""
echo -e "${YELLOW}[*] Current iptables configuration:${NC}"
iptables -L INPUT -n -v --line-numbers
echo ""

# Display statistics
echo -e "${GREEN}═══════════════════════════════════════════════════════════"
echo "  Defense Rules Summary"
echo "═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "✓ Rate Limiting: Max 50 new connections per minute"
echo "✓ Burst Allowance: 20 connections for traffic spikes"
echo "✓ Connection Limiting: Max 10 concurrent connections per IP"
echo "✓ Excess Traffic: Dropped at kernel level"
echo ""
echo -e "${YELLOW}[*] Defense is now active and protecting port 80${NC}"
echo -e "${YELLOW}[*] Monitor with: sudo iptables -L -n -v${NC}"
echo -e "${YELLOW}[*] Reset with: sudo ./iptables-reset.sh${NC}"
