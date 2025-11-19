#!/bin/bash

##############################################################################
# DDoS Defense Lab - Real-Time Monitoring Script
# Monitors system and network statistics during testing
##############################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
clear
echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "  Real-Time Network Monitoring"
echo "  Press Ctrl+C to stop"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"
echo ""

# Check if running on target system
if ! systemctl is-active --quiet apache2; then
    echo -e "${YELLOW}⚠️  Warning: Apache2 not running on this system${NC}"
    echo "   This script should run on the target (Ubuntu) server"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Monitoring loop
while true; do
    clear
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  DDoS Defense Lab - System Monitor  $(date +'%H:%M:%S')${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Network Connections
    echo -e "${BLUE}[Network Connections]${NC}"
    TOTAL_CONN=$(netstat -ant | grep :80 | wc -l)
    ESTABLISHED=$(netstat -ant | grep :80 | grep ESTABLISHED | wc -l)
    SYN_RECV=$(netstat -ant | grep :80 | grep SYN_RECV | wc -l)
    TIME_WAIT=$(netstat -ant | grep :80 | grep TIME_WAIT | wc -l)
    
    echo "  Total connections:     $TOTAL_CONN"
    echo "  ESTABLISHED:           $ESTABLISHED"
    echo "  SYN_RECV:              $SYN_RECV"
    echo "  TIME_WAIT:             $TIME_WAIT"
    echo ""
    
    # iptables Statistics
    echo -e "${BLUE}[iptables Statistics]${NC}"
    if sudo iptables -L INPUT -n -v | grep -q "tcp dpt:80"; then
        echo "  Defense Status:        ${GREEN}ACTIVE${NC}"
        DROPPED=$(sudo iptables -L INPUT -n -v | grep "tcp dpt:80" | grep DROP | awk '{sum+=$1} END {print sum}')
        if [ -z "$DROPPED" ]; then
            DROPPED=0
        fi
        echo "  Packets Dropped:       $DROPPED"
    else
        echo "  Defense Status:        ${RED}INACTIVE${NC}"
        echo "  Packets Dropped:       N/A"
    fi
    echo ""
    
    # System Resources
    echo -e "${BLUE}[System Resources]${NC}"
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEM=$(free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100}')
    echo "  CPU Usage:             $CPU%"
    echo "  Memory Usage:          $MEM%"
    echo ""
    
    # Apache Status
    echo -e "${BLUE}[Apache Status]${NC}"
    if systemctl is-active --quiet apache2; then
        echo "  Service Status:        ${GREEN}RUNNING${NC}"
        APACHE_PROCS=$(ps aux | grep apache2 | grep -v grep | wc -l)
        echo "  Apache Processes:      $APACHE_PROCS"
    else
        echo "  Service Status:        ${RED}STOPPED${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}Refreshing every 2 seconds... Press Ctrl+C to stop${NC}"
    
    sleep 2
done
