#!/usr/bin/env bash
# Domain Reconnaissance Tool
# By DeSCA - Optimized Version

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
print_banner() {
    echo -e "${CYAN}"
    echo "   ____    *    *   _____    _____   *  *_    _____    ______    _____    ____    *   *"
    echo "  / __ \\  | |  | | |_   *|  / *___| | |/ /   |  ** \\  |  **__|  / ____|  / __ \\  | \\ | |"
    echo " | |  | | | |  | |   | |   | |      | ' /    | |__) | | |__    | |      | |  | | |  \\| |"
    echo " | |  | | | |  | |   | |   | |      |  <     |  *  /  |  *_|   | |      | |  | | | . \` |"
    echo " | |__| | | |__| |  *| |*  | |____  | . \\    | | \\ \\  | |____  | |____  | |__| | | |\\  |"
    echo "  \\___\\_\\  \\____/  |_____|  \\_____| |_|\\_\\   |_|  \\_\\ |______|  \\_____|  \\____/  |_| \\_|"
    echo "                                                                                      BY DeSCA"
    echo -e "${NC}"
}

# Function to print section headers
print_section() {
    echo -e "${YELLOW}[+] $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!] $1${NC}"
}

# Function to print notification messages
print_notification() {
    echo -e "\n.\n.\n.\n${MAGENTA}$1${NC}"
}

# Function to run nuclei scan with proper output
run_nuclei_scan() {
    local domain=$1
    local template_dir=$2
    local output_file=$3
    local template_name=$(basename "$template_dir")
    
    print_section "Running scan for $template_name..."
    nuclei -l "$domain/subdomains.txt" -t "$template_dir" -o "$output_file" 2>/dev/null
    
    if [[ -f "$output_file" && -s "$output_file" ]]; then
        print_success "Scan for $template_name completed. Results saved to $output_file"
    else
        print_success "Scan for $template_name completed. No issues found."
    fi
}

# Check if required tools are installed
check_requirements() {
    tools=("nuclei" "assetfinder" "subfinder" "amass" "httpx" "ffuf")
    missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -ne 0 ]]; then
        print_error "The following required tools are missing: ${missing_tools[*]}"
        print_error "Please install them before running this script."
        exit 1
    fi
}

# Main function
main() {
    print_banner
    check_requirements
    
    # Update nuclei templates
    print_section "Updating nuclei templates..."
    if nuclei --update-templates --silent; then
        print_success "Templates updated successfully"
    else
        print_error "Failed to update templates"
    fi
    
    # Get input domains
    read -p "$(echo -e "${BLUE}Enter domain names separated by space: ${NC}")" input
    
    # Define nuclei templates directory - adjust as needed
    NUCLEI_TEMPLATES="/root/nuclei-templates"
    
    # Check if nuclei templates directory exists
    if [[ ! -d "$NUCLEI_TEMPLATES" ]]; then
        print_error "Nuclei templates directory not found at $NUCLEI_TEMPLATES"
        print_error "Please update the NUCLEI_TEMPLATES variable in the script"
        exit 1
    fi
    
    # Create output directory if it doesn't exist
    RESULTS_DIR="recon_results_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$RESULTS_DIR"
    
    # Process each domain
    for domain in $input; do
        domain_dir="$RESULTS_DIR/$domain"
        mkdir -p "$domain_dir"
        
        print_notification "Scan started for $domain"
        
        print_section "Enumerating subdomains for $domain..."
        
        # Run assetfinder and save results
        print_section "Running assetfinder..."
        assetfinder -subs-only "$domain" > "$domain_dir/assetfinder.txt" 2>/dev/null
        count=$(wc -l < "$domain_dir/assetfinder.txt")
        print_success "Found $count subdomains with assetfinder"
        
        # Run subfinder and save results
        print_section "Running subfinder..."
        subfinder -d "$domain" -o "$domain_dir/subfinder.txt" 2>/dev/null
        count=$(wc -l < "$domain_dir/subfinder.txt")
        print_success "Found $count subdomains with subfinder"
        
        # Combine results from assetfinder and subfinder
        cat "$domain_dir/assetfinder.txt" "$domain_dir/subfinder.txt" | sort -u > "$domain_dir/subf.txt"
        
        # Run amass
        print_section "Running amass (passive mode)..."
        # Check if config file exists
        CONFIG_FILE="/home/config.ini"
        SCRIPTS_DIR="/root/tools/scripts"
        
        if [[ -f "$CONFIG_FILE" ]]; then
            amass enum --config "$CONFIG_FILE" --passive -d "$domain" -dir "$domain_dir/amass_output" \
                $(if [[ -d "$SCRIPTS_DIR" ]]; then echo "--scripts $SCRIPTS_DIR"; fi)
            
            # Extract domains from amass output
            find "$domain_dir/amass_output" -name "*.txt" -exec cat {} \; | grep "$domain" > "$domain_dir/amass.txt" 2>/dev/null
        else
            print_error "Amass config file not found at $CONFIG_FILE. Running without config."
            amass enum -passive -d "$domain" -o "$domain_dir/amass.txt"
        fi
        
        count=$(wc -l < "$domain_dir/amass.txt")
        print_success "Found $count subdomains with amass"
        
        # Combine all subdomain results
        print_section "Combining results..."
        cat "$domain_dir/amass.txt" "$domain_dir/subf.txt" | sort -u > "$domain_dir/non-http_list.txt"
        
        # Filter for active HTTP/HTTPS services
        print_section "Filtering for active HTTP/HTTPS services..."
        cat "$domain_dir/non-http_list.txt" | httpx -silent > "$domain_dir/subdomains.txt"
        
        count=$(wc -l < "$domain_dir/subdomains.txt")
        print_success "Found $count active HTTP/HTTPS services"
        
        # Run fuzzing with ffuf
        print_section "Running directory and path fuzzing with ffuf..."
        
        # Create directory for ffuf results
        mkdir -p "$domain_dir/fuzzing"
        
        # Common wordlists - adjust paths as needed
        COMMON_WORDLIST="/usr/share/wordlists/dirb/common.txt"
        API_WORDLIST="/usr/share/wordlists/api/endpoints.txt"
        
        # Check if wordlists exist, if not use default paths or download
        if [ ! -f "$COMMON_WORDLIST" ]; then
            print_error "Common wordlist not found at $COMMON_WORDLIST"
            # Try to use alternative location or download it
            if [ -f "/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt" ]; then
                COMMON_WORDLIST="/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt"
                print_success "Using alternative wordlist: $COMMON_WORDLIST"
            else
                print_section "Downloading common wordlist..."
                mkdir -p /usr/share/wordlists/dirb/
                curl -s -o "$COMMON_WORDLIST" "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
                if [ -f "$COMMON_WORDLIST" ]; then
                    print_success "Downloaded common wordlist"
                else
                    print_error "Failed to download wordlist"
                fi
            fi
        fi
        
        # Create a list of active subdomains to fuzz
        ACTIVE_DOMAINS="$domain_dir/active_domains.txt"
        cat "$domain_dir/subdomains.txt" > "$ACTIVE_DOMAINS"
        
        # Run ffuf against each active subdomain
        print_section "Fuzzing directories and paths on active subdomains..."
        
        while IFS= read -r target; do
            target_name=$(echo "$target" | sed 's/https\?:\/\///' | sed 's/[\/\.]/_/g')
            output_file="$domain_dir/fuzzing/${target_name}_dirs.json"
            
            print_section "Fuzzing $target..."
            ffuf -u "${target}/FUZZ" -w "$COMMON_WORDLIST" -mc 200,201,202,203,204,301,302,307,401,403,405 -of json -o "$output_file" -s
            
            # Extract discovered URLs from ffuf output
            if [ -f "$output_file" ]; then
                cat "$output_file" | jq -r '.results[] | .url' 2>/dev/null > "$domain_dir/fuzzing/${target_name}_urls.txt"
                print_success "Fuzzing complete for $target. Found $(wc -l < "$domain_dir/fuzzing/${target_name}_urls.txt") endpoints."
            else
                print_error "Fuzzing failed for $target"
            fi
        done < "$ACTIVE_DOMAINS"
        
        # Combine all discovered URLs
        find "$domain_dir/fuzzing/" -name "*_urls.txt" -exec cat {} \; > "$domain_dir/fuzzed_endpoints.txt"
        print_success "Combined $(wc -l < "$domain_dir/fuzzed_endpoints.txt") fuzzed endpoints"
        
        # Run nuclei scans against both subdomain list and fuzzed endpoints
        print_section "Running vulnerability scans with nuclei..."
        
        # Combine subdomain and fuzzed endpoint lists
        cat "$domain_dir/subdomains.txt" "$domain_dir/fuzzed_endpoints.txt" | sort -u > "$domain_dir/all_targets.txt"
        print_success "Combined target list with $(wc -l < "$domain_dir/all_targets.txt") unique endpoints"
        
        # Define scan types
        scan_types=(
            "default-logins"
            "exposures"
            "misconfiguration"
            "takeovers"
            "vulnerabilities"
            "exposed-panels"
        )
        
        # Run all scans on the combined target list
        for scan_type in "${scan_types[@]}"; do
            # Update the run_nuclei_scan function call to use the all_targets.txt file
            print_section "Running scan for $scan_type..."
            nuclei -l "$domain_dir/all_targets.txt" -t "$NUCLEI_TEMPLATES/$scan_type" -o "$domain_dir/${scan_type}.txt" 2>/dev/null
            
            if [[ -f "$domain_dir/${scan_type}.txt" && -s "$domain_dir/${scan_type}.txt" ]]; then
                print_success "Scan for $scan_type completed. Results saved to $domain_dir/${scan_type}.txt"
            else
                print_success "Scan for $scan_type completed. No issues found."
            fi
        done
        
        # Create summary file
        print_section "Creating summary report..."
        {
            echo "# Reconnaissance Summary for $domain"
            echo "Date: $(date)"
            echo
            echo "## Enumeration Results"
            echo "- Total unique subdomains found: $(wc -l < "$domain_dir/non-http_list.txt")"
            echo "- Live HTTP/HTTPS endpoints: $(wc -l < "$domain_dir/subdomains.txt")"
            
            # Add fuzzing results if available
            if [[ -f "$domain_dir/fuzzed_endpoints.txt" ]]; then
                echo "- Fuzzed endpoints discovered: $(wc -l < "$domain_dir/fuzzed_endpoints.txt")"
                echo "- Total unique targets scanned: $(wc -l < "$domain_dir/all_targets.txt")"
            fi
            echo
            echo "## Vulnerability Scan Results"
            
            for scan_type in "${scan_types[@]}"; do
                output_file="$domain_dir/${scan_type}.txt"
                if [[ -f "$output_file" && -s "$output_file" ]]; then
                    count=$(wc -l < "$output_file")
                    echo "- $scan_type: $count findings"
                else
                    echo "- $scan_type: No findings"
                fi
            done
        } > "$domain_dir/summary.md"
        
        print_success "Summary report created at $domain_dir/summary.md"
        print_notification "Scan finished for $domain"
    done
    
    print_section "All scans completed!"
    print_success "Results saved in $RESULTS_DIR directory"
}

# Execute main function
main
