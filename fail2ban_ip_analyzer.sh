#!/bin/bash

# fail2ban_ip_analyzer.sh
# Version: 1.0.0
# Description: Analyzes banned IPs from Fail2Ban, queries ipinfo.io for details,
#              and generates summaries with a focus on Polish IPs.
# Author: Krystian Graba

# Configuration
TOKEN="_use_your_own_"            # ipinfo.io API token (replace with your own or use env var)
OUTPUT_FILE="fail2ban_analysis_$(date +%Y%m%d_%H%M%S).txt"
TEMP_FILE="/tmp/fail2ban_temp_$$.json"
ERROR_LOG="/tmp/fail2ban_errors_$$.log"
POLISH_IPS=()                     # Array to store Polish IPs
TOTAL_IPS=0                       # Counter for total IPs processed
declare -A COUNTRY_COUNT          # Associative array for country counts
declare -A IP_DETAILS             # Associative array for IP details

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup function for temporary files
cleanup() {
    [[ -f "$TEMP_FILE" ]] && rm -f "$TEMP_FILE"
    [[ -f "$ERROR_LOG" ]] && rm -f "$ERROR_LOG"
}

# Error handling trap
trap 'echo -e "${RED}Error: Script terminated unexpectedly${NC}"; [ -f "$TEMP_FILE" ] && cat "$TEMP_FILE"; [ -f "$ERROR_LOG" ] && echo -e "\nErrors:\n$(cat "$ERROR_LOG")"; cleanup; exit 1' ERR
trap 'cleanup; exit 0' INT TERM

# Check dependencies
for cmd in curl jq sudo fail2ban-client; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Error: $cmd is required but not installed${NC}"
        exit 1
    fi
done

# Function to process IP information
process_ip() {
    local ip=$1
    local details=""
    
    echo -e "\n${BLUE}Processing IP: $ip${NC}" >&2
    details="IP: $ip"
    
    local attempt=1
    local max_attempts=3
    local response
    
    # Attempt to fetch IP info with retries
    while [ $attempt -le $max_attempts ]; do
        response=$(curl -s --max-time 10 "ipinfo.io/$ip?token=$TOKEN" 2>>"$ERROR_LOG")
        if [ $? -eq 0 ] && [ ! -z "$response" ]; then
            break
        fi
        echo -e "${RED}Attempt $attempt failed for $ip${NC}" >&2
        sleep 2
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo -e "${RED}Failed to get info for $ip after $max_attempts attempts${NC}" >&2
        details="$details\nStatus: Failed to retrieve information"
    else
        local country=$(echo "$response" | jq -r '.country // "Unknown"' 2>>"$ERROR_LOG")
        local city=$(echo "$response" | jq -r '.city // "Unknown"' 2>>"$ERROR_LOG")
        local region=$(echo "$response" | jq -r '.region // "Unknown"' 2>>"$ERROR_LOG")
        local org=$(echo "$response" | jq -r '.org // "Unknown"' 2>>"$ERROR_LOG")
        
        if [ $? -ne 0 ]; then
            echo "jq parsing failed for $ip" >> "$ERROR_LOG"
            details="$details\nStatus: Failed to parse response"
        else
            details="$details\nCountry: $country\nCity: $city\nRegion: $region\nOrganization: $org"
            
            ((TOTAL_IPS++))
            ((COUNTRY_COUNT[$country]++))
            if [ "$country" = "PL" ]; then
                POLISH_IPS+=("$ip|$city|$region|$org")
                echo -e "${GREEN}Polish IP Detected:${NC}" >&2
                echo "IP: $ip" >&2
                echo "Country: $country" >&2
                echo "City: $city" >&2
                echo "Region: $region" >&2
                echo "Organization: $org" >&2
            fi
        fi
    fi
    
    IP_DETAILS[$ip]="$details"
}

# Main execution
echo -e "${GREEN}Starting Fail2Ban IP analysis...${NC}"

# Get banned IPs from Fail2Ban
echo "Retrieving banned IPs..."
sudo fail2ban-client banned > "$TEMP_FILE" 2>>"$ERROR_LOG"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to get banned IPs from fail2ban${NC}"
    cleanup
    exit 1
fi

# Show raw output for debugging
echo -e "${BLUE}Raw Fail2Ban output:${NC}"
cat "$TEMP_FILE"

# Parse IPs from the output
IPS=$(cat "$TEMP_FILE" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | sort -u)
if [ -z "$IPS" ]; then
    echo -e "${RED}No valid IPs found in output${NC}"
    cleanup
    exit 0
fi

# Process each IP sequentially
echo "Found $(echo "$IPS" | wc -l) IPs to process"
for ip in $IPS; do
    process_ip "$ip"
done

# Write results to file
echo "Fail2Ban IP Analysis - $(date)" > "$OUTPUT_FILE"
echo "===================================" >> "$OUTPUT_FILE"
for ip in "${!IP_DETAILS[@]}"; do
    echo -e "\n${IP_DETAILS[$ip]}" >> "$OUTPUT_FILE"
done

# Generate summaries
echo -e "\n${GREEN}Generating summaries...${NC}"

GENERAL_SUMMARY=$(cat <<EOF
General Summary
===============
Total IPs analyzed: $TOTAL_IPS

IPs by Country:
$(for country in "${!COUNTRY_COUNT[@]}"; do echo "$country: ${COUNTRY_COUNT[$country]}"; done)
EOF
)
echo "$GENERAL_SUMMARY" >> "$OUTPUT_FILE"

POLISH_SUMMARY=$(cat <<EOF
Polish IPs Summary
=================
$(if [ ${#POLISH_IPS[@]} -eq 0 ]; then
    echo "No Polish IPs found"
else
    echo "Total Polish IPs: ${#POLISH_IPS[@]}"
    echo -e "\nIP | City | Region | Organization"
    echo "--------------------------------"
    for entry in "${POLISH_IPS[@]}"; do
        IFS='|' read -r ip city region org <<< "$entry"
        echo "$ip | $city | $region | $org"
    done
fi)
EOF
)
echo "$POLISH_SUMMARY" >> "$OUTPUT_FILE"

# Final output to terminal
echo -e "${GREEN}Analysis complete!${NC}"
echo "Results saved to: $OUTPUT_FILE"
echo -e "\n${BLUE}Full Results:${NC}"
echo "$GENERAL_SUMMARY"
echo -e "\n$POLISH_SUMMARY"
echo -e "\nTotal IPs processed: $TOTAL_IPS"
echo "Polish IPs found: ${#POLISH_IPS[@]}"

# Cleanup temporary files
cleanup
