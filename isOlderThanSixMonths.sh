#!/bin/sh
# =============================================================================
# isOlderThanSixMonths - Checks if a file is older than 6 months
# =============================================================================
# 
# DESCRIPTION:
#   This script checks if a file is older than 6 months, based on the
#   modification date of the file. The calculation corresponds to the Excel
#   DATEDIF function with "m" parameter.
#
# USAGE:
#   isOlderThanSixMonths <file_path>
#
# RETURN VALUES:
#   0   - File is older than 6 months
#   1   - File is younger than 6 months
#   255 (-1) - File not found
#   254 (-2) - Other error
#
# AUTHOR: Auto-generated
# VERSION: 1.0
# =============================================================================

# Function: Show help
show_help() {
    echo "USAGE:"
    echo "  $(basename "$0") <file_path>"
    echo ""
    echo "DESCRIPTION:"
    echo "  Checks if a file is older than 6 months."
    echo ""
    echo "RETURN VALUES:"
    echo "  0   - File is older than 6 months"
    echo "  1   - File is younger than 6 months"
    echo "  255 - File not found"
    echo "  254 - Other error"
    echo ""
    echo "EXAMPLES:"
    echo "  $(basename "$0") /home/user/document.txt"
    echo "  $(basename "$0") /var/log/system.log"
}

# Function: Calculate months between two dates
calculate_months_difference() {
    local file_date="$1"
    local today_date="$2"
    
    # Extract date components
    local file_year=$(echo "$file_date" | cut -c1-4)
    local file_month=$(echo "$file_date" | cut -c5-6)
    local file_day=$(echo "$file_date" | cut -c7-8)
    
    local today_year=$(echo "$today_date" | cut -c1-4)
    local today_month=$(echo "$today_date" | cut -c5-6)
    local today_day=$(echo "$today_date" | cut -c7-8)
    
    # Calculate months (Excel DATEDIF logic)
    local months=$(( (today_year - file_year) * 12 + (today_month - file_month) ))
    
    # Adjust if day has not been reached yet
    if [ "$today_day" -lt "$file_day" ]; then
        months=$((months - 1))
    fi
    
    echo "$months"
}

# Function: Main logic
main() {
    # Check parameters
    if [ $# -eq 0 ]; then
        show_help >&2
        exit 254  # -2: Other error
    fi
    
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    if [ $# -ne 1 ]; then
        echo "Error: Exactly one parameter required" >&2
        show_help >&2
        exit 254  # -2: Other error
    fi
    
    local file_path="$1"
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        echo "Error: File '$file_path' not found" >&2
        exit 255  # -1: File not found
    fi
    
    # Get file modification timestamp
    local file_timestamp
    if command -v stat >/dev/null 2>&1; then
        # Try different stat formats (Linux/BSD compatibility)
        if stat -c "%Y" "$file_path" >/dev/null 2>&1; then
            # GNU stat (Linux)
            file_timestamp=$(stat -c "%Y" "$file_path")
        elif stat -f "%m" "$file_path" >/dev/null 2>&1; then
            # BSD stat (macOS, FreeBSD)
            file_timestamp=$(stat -f "%m" "$file_path")
        else
            echo "Error: Unknown stat variant" >&2
            exit 254  # -2: Other error
        fi
    else
        echo "Error: stat command not available" >&2
        exit 254  # -2: Other error
    fi
    
    # Convert timestamp to YYYYMMDD format
    local file_date
    if command -v date >/dev/null 2>&1; then
        # Try different date formats
        if date -d "@$file_timestamp" +%Y%m%d >/dev/null 2>&1; then
            # GNU date (Linux)
            file_date=$(date -d "@$file_timestamp" +%Y%m%d)
        elif date -r "$file_timestamp" +%Y%m%d >/dev/null 2>&1; then
            # BSD date (macOS, FreeBSD)
            file_date=$(date -r "$file_timestamp" +%Y%m%d)
        else
            echo "Error: Unknown date variant" >&2
            exit 254  # -2: Other error
        fi
    else
        echo "Error: date command not available" >&2
        exit 254  # -2: Other error
    fi
    
    # Today's date
    local today_date=$(date +%Y%m%d)
    
    # Calculate months
    local months_diff
    months_diff=$(calculate_months_difference "$file_date" "$today_date")
    
    # Check if older than 6 months
    if [ "$months_diff" -ge 6 ]; then
        # File is older than 6 months
        exit 0
    else
        # File is younger than 6 months
        exit 1
    fi
}

# Execute script
main "$@"