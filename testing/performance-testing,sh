#!/bin/bash

##############################################################################
# DDoS Defense Lab - Performance Testing Script
# Tests performance under various conditions
##############################################################################

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
TARGET="http://192.168.153.129/"
REQUESTS="1000"
CONCURRENCY="10"
OUTPUT_DIR="../results"

# Create results directory
mkdir -p "$OUTPUT_DIR"

# Banner
echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "  Performance Testing Suite"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 [baseline|attack|defense]"
    echo ""
    echo "Options:"
    echo "  baseline  - Test normal performance (no attack, no defense)"
    echo "  attack    - Test performance during attack (no defense)"
    echo "  defense   - Test performance with defense active (under attack)"
    exit 1
fi

TEST_TYPE=$1

case $TEST_TYPE in
    baseline)
        OUTPUT_FILE="$OUTPUT_DIR/baseline-performance.txt"
        echo -e "${GREEN}[*] Running BASELINE performance test${NC}"
        echo "    (No attack, no defense - normal operation)"
        ;;
    attack)
        OUTPUT_FILE="$OUTPUT_DIR/attack-impact.txt"
        echo -e "${YELLOW}[*] Running ATTACK IMPACT test${NC}"
        echo "    (Attack active, no defense)"
        echo -e "${RED}[!] Make sure attack is running on Kali system${NC}"
        ;;
    defense)
        OUTPUT_FILE="$OUTPUT_DIR/defense-effectiveness.txt"
        echo -e "${GREEN}[*] Running DEFENSE EFFECTIVENESS test${NC}"
        echo "    (Attack active, defense enabled)"
        echo -e "${YELLOW}[!] Make sure both attack and defense are active${NC}"
        ;;
    *)
        echo -e "${RED}❌ Invalid option: $TEST_TYPE${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}[*] Test Configuration:${NC}"
echo "    Target:         $TARGET"
echo "    Requests:       $REQUESTS"
echo "    Concurrency:    $CONCURRENCY"
echo "    Output:         $OUTPUT_FILE"
echo ""

read -p "Press Enter to start test..." 

# Run test
echo -e "${GREEN}[*] Testing...${NC}"
ab -n "$REQUESTS" -c "$CONCURRENCY" "$TARGET" > "$OUTPUT_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Test completed${NC}"
else
    echo -e "${RED}❌ Test failed${NC}"
    exit 1
fi

# Display results
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════"
echo "  Test Results ($TEST_TYPE)"
echo "═══════════════════════════════════════════════════════════${NC}"
echo ""

REQUESTS_PER_SEC=$(grep "Requests per second:" "$OUTPUT_FILE" | awk '{print $4}')
TIME_PER_REQUEST=$(grep "Time per request:" "$OUTPUT_FILE" | head -1 | awk '{print $4}')
TRANSFER_RATE=$(grep "Transfer rate:" "$OUTPUT_FILE" | awk '{print $3}')
FAILED=$(grep "Failed requests:" "$OUTPUT_FILE" | awk '{print $3}')

echo "📊 Results:"
echo "   Throughput:        $REQUESTS_PER_SEC req/sec"
echo "   Response Time:     $TIME_PER_REQUEST ms"
echo "   Transfer Rate:     $TRANSFER_RATE KB/sec"
echo "   Failed Requests:   $FAILED"
echo ""
echo -e "${YELLOW}[*] Full results saved to: $OUTPUT_FILE${NC}"
