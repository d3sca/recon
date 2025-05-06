#!/usr/bin/env bash
# Tool Installer for Domain Reconnaissance
# This script installs all required tools for the domain reconnaissance script

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

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

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script as root or with sudo"
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
            return 0  # Debian-based
        elif [[ $OS == *"CentOS"* ]] || [[ $OS == *"Red Hat"* ]] || [[ $OS == *"Fedora"* ]]; then
            return 1  # RHEL-based
        else
            return 2  # Other Linux
        fi
    elif [ "$(uname)" == "Darwin" ]; then
        return 3  # macOS
    else
        return 4  # Unknown
    fi
}

# Function to install basic dependencies
install_basic_deps() {
    print_section "Installing basic dependencies..."
    
    detect_os
    os_type=$?
    
    if [ $os_type -eq 0 ]; then
        # Debian/Ubuntu
        apt-get update
        apt-get install -y git wget curl build-essential make gcc unzip python3 python3-pip
    elif [ $os_type -eq 1 ]; then
        # RHEL/CentOS/Fedora
        yum -y update
        yum -y install git wget curl gcc make unzip python3 python3-pip
    elif [ $os_type -eq 3 ]; then
        # macOS
        if ! command_exists brew; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install git wget curl gcc make unzip python3
    else
        print_error "Your OS is not supported for automated installation"
        exit 1
    fi
    
    print_success "Basic dependencies installed"
}

# Function to install Go
install_go() {
    print_section "Installing Go..."
    
    if command_exists go; then
        print_success "Go is already installed"
        return
    fi
    
    GO_VERSION="1.21.1"
    
    detect_os
    os_type=$?
    
    if [ $os_type -eq 3 ]; then
        # macOS
        brew install go
    else
        # Linux
        wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
        tar -C /usr/local -xzf /tmp/go.tar.gz
        
        # Add Go to PATH
        if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" ~/.bashrc; then
            echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
            echo "export PATH=\$PATH:~/go/bin" >> ~/.bashrc
        fi
        
        # Apply changes to current session
        export PATH=$PATH:/usr/local/go/bin
        export PATH=$PATH:~/go/bin
    fi
    
    if command_exists go; then
        print_success "Go installed successfully"
    else
        print_error "Failed to install Go"
        exit 1
    fi
}

# Function to install nuclei
install_nuclei() {
    print_section "Installing nuclei..."
    
    if command_exists nuclei; then
        print_success "nuclei is already installed"
        return
    fi
    
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    
    if command_exists nuclei; then
        print_success "nuclei installed successfully"
        print_section "Downloading nuclei templates..."
        nuclei --update-templates
        print_success "nuclei templates downloaded"
    else
        print_error "Failed to install nuclei"
    fi
}

# Function to install assetfinder
install_assetfinder() {
    print_section "Installing assetfinder..."
    
    if command_exists assetfinder; then
        print_success "assetfinder is already installed"
        return
    fi
    
    go install -v github.com/tomnomnom/assetfinder@latest
    
    if command_exists assetfinder; then
        print_success "assetfinder installed successfully"
    else
        print_error "Failed to install assetfinder"
    fi
}

# Function to install subfinder
install_subfinder() {
    print_section "Installing subfinder..."
    
    if command_exists subfinder; then
        print_success "subfinder is already installed"
        return
    fi
    
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    
    if command_exists subfinder; then
        print_success "subfinder installed successfully"
    else
        print_error "Failed to install subfinder"
    fi
}

# Function to install amass
install_amass() {
    print_section "Installing amass..."
    
    if command_exists amass; then
        print_success "amass is already installed"
        return
    fi
    
    detect_os
    os_type=$?
    
    if [ $os_type -eq 3 ]; then
        # macOS
        brew install amass
    else
        # Linux
        go install -v github.com/owasp-amass/amass/v4/...@master
    fi
    
    if command_exists amass; then
        print_success "amass installed successfully"
    else
        print_error "Failed to install amass"
    fi
}

# Function to install httpx
install_httpx() {
    print_section "Installing httpx..."
    
    if command_exists httpx; then
        print_success "httpx is already installed"
        return
    fi
    
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    
    if command_exists httpx; then
        print_success "httpx installed successfully"
    else
        print_error "Failed to install httpx"
    fi
}

# Function to create a sample config file for amass
create_amass_config() {
    print_section "Creating sample amass config..."
    
    CONFIG_DIR="/home"
    CONFIG_FILE="${CONFIG_DIR}/config.ini"
    
    if [ -f "$CONFIG_FILE" ]; then
        print_success "amass config file already exists at $CONFIG_FILE"
        return
    fi
    
    # Create a basic config file
    cat > "$CONFIG_FILE" << EOL
# OWASP Amass Configuration File

# Data sources for DNS name resolution
[data_sources]
# Some basic free API keys - replace with your own for better results
#virustotal = [free-api-key-here]
#securitytrails = [free-api-key-here]
#shodan = [free-api-key-here]

# Settings specific to DNS name resolution
[resolvers]
monitor_dedicated_systems = true

# Public DNS resolvers
public_resolvers = [
    "8.8.8.8",     # Google
    "8.8.4.4",     # Google
    "1.1.1.1",     # Cloudflare
    "1.0.0.1",     # Cloudflare
    "9.9.9.9",     # Quad9
    "9.9.9.10",    # Quad9
    "208.67.222.222", # OpenDNS
    "208.67.220.220"  # OpenDNS
]
EOL
    
    if [ -f "$CONFIG_FILE" ]; then
        print_success "Created amass config file at $CONFIG_FILE"
        echo -e "${BLUE}Note: Edit this file to add your API keys for better results${NC}"
    else
        print_error "Failed to create amass config file"
    fi
}

# Main function
main() {
    echo -e "${GREEN}"
    echo "    _____           _        _ _           "
    echo "   |_   _|         | |      | | |          "
    echo "     | |  _ __  ___| |_ __ _| | | ___ _ __ "
    echo "     | | | '_ \/ __| __/ _\` | | |/ _ \ '__|"
    echo "    _| |_| | | \__ \ || (_| | | |  __/ |   "
    echo "   |_____|_| |_|___/\__\__,_|_|_|\___|_|   "
    echo "                                           "
    echo -e "${NC}"
    echo -e "${YELLOW}Reconnaissance Tools Installer${NC}"
    echo -e "${YELLOW}================================${NC}"
    
    # Check if running as root
    check_root
    
    # Install basic dependencies
    install_basic_deps
    
    # Install Go
    install_go
    
    # Create tools directory
    mkdir -p /root/tools
    mkdir -p /root/tools/scripts
    
    # Function to install ffuf
    install_ffuf() {
        print_section "Installing ffuf..."
        
        if command_exists ffuf; then
            print_success "ffuf is already installed"
            return
        fi
        
        go install -v github.com/ffuf/ffuf@latest
        
        if command_exists ffuf; then
            print_success "ffuf installed successfully"
        else
            print_error "Failed to install ffuf"
        fi
    }
    
    # Install tools
    install_nuclei
    install_assetfinder
    install_subfinder
    install_amass
    install_httpx
    install_ffuf
    
    # Download common wordlists
    print_section "Downloading common wordlists for fuzzing..."
    mkdir -p /usr/share/wordlists/dirb/
    mkdir -p /usr/share/wordlists/api/
    
    if [ ! -f "/usr/share/wordlists/dirb/common.txt" ]; then
        curl -s -o "/usr/share/wordlists/dirb/common.txt" "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"
        print_success "Downloaded common.txt wordlist"
    else
        print_success "common.txt wordlist already exists"
    fi
    
    if [ ! -f "/usr/share/wordlists/api/endpoints.txt" ]; then
        curl -s -o "/usr/share/wordlists/api/endpoints.txt" "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/api/api-endpoints.txt"
        print_success "Downloaded API endpoints wordlist"
    else
        print_success "API endpoints wordlist already exists"
    fi
    
    # Create config files
    create_amass_config
    
    # Print final message
    echo -e "\n${GREEN}[✓] All tools have been installed successfully!${NC}"
    echo -e "${YELLOW}[+] Notes:${NC}"
    echo -e "  - You may need to restart your terminal or source your .bashrc to use these tools"
    echo -e "  - Edit /home/config.ini to add your API keys for better amass results"
    echo -e "  - The tools are installed in your Go bin directory (~/go/bin)"
    echo -e "\n${GREEN}Happy reconnaissance!${NC}\n"
}

# Execute main function
main
