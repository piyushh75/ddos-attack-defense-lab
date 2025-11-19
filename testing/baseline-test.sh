#!/bin/bash

##############################################################################
# DDoS Defense Lab - Baseline Performance Test
# Establishes normal performance metrics before attack
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

# Create results directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Banner
echo -e "${GREEN}"
echo "═══════════════════════════════════════════════════════════"
echo "  Baseline Performance Test"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check if Apache Bench is installed
if ! command -v ab &> /dev/null; then
    echo -e "${RED}❌ Error: Apache Bench (ab) is not installed${NC}"
    echo "   Install with: sudo apt-get install apache2-utils"
    exit 1
fi

# Connectivity check
echo -e "${YELLOW}[*] Checking target connectivity...${NC}"
if curl -s -o /dev/null -w "%{http_code}" "$TARGET" --connect-timeout 5 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ Target is reachable${NC}"
else
    echo -e "${RED}❌ Error: Cannot reach target${NC}"
    exit 1
fi

# Display test configuration
echo ""
echo -e "${GREEN}[*] Test Configuration:${NC}"
echo "    Target URL:     $TARGET"
echo "    Total Requests: $REQUESTS"
echo "    Concurrency:    $CONCURRENCY"
echo "    Output File:    $OUTPUT_DIR/baseline-performance.txt"
echo ""

# Run baseline test
echo -e "${GREEN}[*] Running baseline performance test...${NC}"
echo -e "${YELLOW}[*] This may take a moment...${NC}"
echo ""

ab -n "$REQUESTS" -c "$CONCURRENCY" "$TARGET" > "$OUTPUT_DIR/baseline-performance.txt" 2>&1

# Check if test was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Baseline test completed successfully${NC}"
else
    echo -e "${RED}❌ Baseline test failed${NC}"
    exit 1
fi

# Parse and display key metrics
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════"
echo "  Baseline Performance Results"
echo "═══════════════════════════════════════════════════════════${NC}"
echo ""

# Extract metrics
REQUESTS_PER_SEC=$(grep "Requests per second:" "$OUTPUT_DIR/baseline-performance.txt" | awk '{print $4}')
TIME_PER_REQUEST=$(grep "Time per request:" "$OUTPUT_DIR/baseline-performance.txt" | head -1 | awk '{print $4}')
TRANSFER_RATE=$(grep "Transfer rate:" "$OUTPUT_DIR/baseline-performance.txt" | awk '{print $3}')
FAILED=$(grep "Failed requests:" "$OUTPUT_DIR/baseline-performance.txt" | awk '{print $3}')

echo "📊 Key Metrics:"
echo "   Throughput:        $REQUESTS_PER_SEC req/sec"
echo "   Response Time:     $TIME_PER_REQUEST ms"
echo "   Transfer Rate:     $TRANSFER_RATE KB/sec"
echo "   Failed Requests:   $FAILED"
echo ""
echo -e "${YELLOW}[*] Full results saved to: $OUTPUT_DIR/baseline-performance.txt${NC}"
echo -e "${YELLOW}[*] Use these metrics as baseline for comparison${NC}"
