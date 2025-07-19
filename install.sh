#!/bin/bash

# Website Scanner Installer for Termux
# Auto installer dengan dependency check

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Informasi installer
SCRIPT_NAME="Website Scanner"
VERSION="2.1"
GITHUB_USER="serbianhacker"
REPO_NAME="website-scanner-termux"
SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main/scanner.sh"

# Fungsi untuk menampilkan header installer
show_installer_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗         ║
    ║    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║         ║
    ║    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║         ║
    ║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║         ║
    ║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗    ║
    ║    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝    ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${WHITE}              🔧 WEBSITE SCANNER INSTALLER v${VERSION}             ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${WHITE}                   Automatic Setup for Termux                 ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Fungsi loading animation
loading_animation() {
    local duration=$1
    local message=$2
    local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local end=$((SECONDS + duration))
    
    echo -e "${YELLOW}${message}${NC}"
    while [ $SECONDS -lt $end ]; do
        for i in "${spinner[@]}"; do
            echo -ne "\r${CYAN}${i} Processing... ${YELLOW}$((end - SECONDS))s${NC}"
            sleep 0.1
        done
    done
    echo -e "\r${GREEN}✓ Complete!${NC}"
    echo ""
}

# Fungsi untuk mengecek dan install dependencies
install_dependencies() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                    CHECKING DEPENDENCIES                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Update package list
    echo -e "${CYAN}📦 Updating package repositories...${NC}"
    pkg update -y > /dev/null 2>&1
    
    # Array dependencies yang diperlukan
    local deps=("curl" "wget" "git" "termux-api")
    local missing_deps=()
    
    # Check setiap dependency
    for dep in "${deps[@]}"; do
        echo -e "${YELLOW}🔍 Checking ${dep}...${NC}"
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
            echo -e "${RED}   ❌ ${dep} not found${NC}"
        else
            echo -e "${GREEN}   ✓ ${dep} found${NC}"
        fi
    done
    
    # Install missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}📥 Installing missing dependencies...${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "${CYAN}Installing ${dep}...${NC}"
            pkg install -y "$dep" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ ${dep} installed successfully${NC}"
            else
                echo -e "${RED}❌ Failed to install ${dep}${NC}"
            fi
        done
    else
        echo -e "${GREEN}🎉 All dependencies already installed!${NC}"
    fi
    
    echo ""
}

# Fungsi untuk setup permissions
setup_permissions() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                    SETTING UP PERMISSIONS                    ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}🔐 Setting up Termux permissions...${NC}"
    
    # Setup storage permission
    echo -e "${YELLOW}📱 Requesting storage access...${NC}"
    termux-setup-storage 2>/dev/null
    
    echo -e "${YELLOW}📍 Testing location access...${NC}"
    timeout 5s termux-location -p network > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Permissions setup complete${NC}"
    echo ""
}

# Fungsi untuk download script utama
download_scanner() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                    DOWNLOADING SCANNER                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local install_dir="$HOME/website-scanner"
    local script_path="$install_dir/scanner.sh"
    
    # Buat direktori instalasi
    echo -e "${CYAN}📁 Creating installation directory...${NC}"
    mkdir -p "$install_dir"
    
    # Download script utama
    echo -e "${CYAN}⬇️  Downloading scanner script...${NC}"
    
    # Download dengan curl
    if command -v curl &> /dev/null; then
        curl -s -L "$SCRIPT_URL" -o "$script_path"
    elif command -v wget &> /dev/null; then
        wget -q "$SCRIPT_URL" -O "$script_path"
    else
        echo -e "${RED}❌ Neither curl nor wget found!${NC}"
        exit 1
    fi
    
    # Verifikasi download
    if [ -f "$script_path" ] && [ -s "$script_path" ]; then
        echo -e "${GREEN}✓ Script downloaded successfully${NC}"
        
        # Set executable permission
        chmod +x "$script_path"
        echo -e "${GREEN}✓ Executable permission set${NC}"
        
        # Simpan path untuk akses mudah
        echo "export PATH=\$PATH:$install_dir" >> "$HOME/.bashrc"
        echo -e "${GREEN}✓ Added to PATH${NC}"
        
    else
        echo -e "${RED}❌ Failed to download script${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}📍 Installation path: ${script_path}${NC}"
    echo ""
}

# Fungsi untuk membuat shortcut
create_shortcuts() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                     CREATING SHORTCUTS                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local install_dir="$HOME/website-scanner"
    local bin_dir="$PREFIX/bin"
    
    # Buat symlink untuk akses global
    echo -e "${CYAN}🔗 Creating global shortcut...${NC}"
    ln -sf "$install_dir/scanner.sh" "$bin_dir/scanner" 2>/dev/null
    ln -sf "$install_dir/scanner.sh" "$bin_dir/webscan" 2>/dev/null
    
    # Buat script launcher di home
    echo -e "${CYAN}🚀 Creating home launcher...${NC}"
    cat > "$HOME/scanner" << 'EOF'
#!/bin/bash
exec $HOME/website-scanner/scanner.sh "$@"
EOF
    chmod +x "$HOME/scanner"
    
    echo -e "${GREEN}✓ Shortcuts created successfully${NC}"
    echo ""
}

# Fungsi untuk konfigurasi Telegram
configure_telegram() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                   TELEGRAM CONFIGURATION                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}📱 Would you like to configure Telegram tracking now? [y/n]${NC}"
    read -p "Choice: " setup_telegram
    
    if [[ "$setup_telegram" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${CYAN}🤖 Enter your Telegram Bot Token:${NC}"
        read -p "Bot Token: " bot_token
        
        echo -e "${CYAN}💬 Enter your Telegram Chat ID:${NC}"
        read -p "Chat ID: " chat_id
        
        if [[ -n "$bot_token" && -n "$chat_id" ]]; then
            # Update script dengan token dan chat ID
            local script_path="$HOME/website-scanner/scanner.sh"
            sed -i "s/YOUR_BOT_TOKEN_HERE/$bot_token/g" "$script_path"
            sed -i "s/YOUR_CHAT_ID_HERE/$chat_id/g" "$script_path"
            
            echo -e "${GREEN}✓ Telegram configuration saved${NC}"
            
            # Test connection
            echo -e "${CYAN}🧪 Testing Telegram connection...${NC}"
            local test_url="https://api.telegram.org/bot${bot_token}/sendMessage"
            local test_message="🧪 Website Scanner installed successfully!"
            
            local response=$(curl -s -X POST "$test_url" \
                -d "chat_id=${chat_id}" \
                -d "text=${test_message}")
            
            if [[ "$response" == *'"ok":true'* ]]; then
                echo -e "${GREEN}✓ Telegram connection successful${NC}"
            else
                echo -e "${YELLOW}⚠️  Telegram test failed, please check your credentials${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Skipping Telegram configuration${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Telegram tracking disabled${NC}"
    fi
    
    echo ""
}

# Fungsi untuk menampilkan summary instalasi
show_installation_summary() {
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${WHITE}                    INSTALLATION COMPLETE                     ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}🎉 Website Scanner has been installed successfully!${NC}"
    echo ""
    echo -e "${WHITE}📋 Quick Start Commands:${NC}"
    echo -e "${YELLOW}   scanner          ${WHITE}- Run the scanner${NC}"
    echo -e "${YELLOW}   webscan          ${WHITE}- Alternative command${NC}"
    echo -e "${YELLOW}   ~/scanner        ${WHITE}- Run from home directory${NC}"
    echo ""
    
    echo -e "${WHITE}📁 Installation Details:${NC}"
    echo -e "${CYAN}   Location: ${HOME}/website-scanner/${NC}"
    echo -e "${CYAN}   Script: ${HOME}/website-scanner/scanner.sh${NC}"
    echo -e "${CYAN}   Shortcuts: /data/data/com.termux/files/usr/bin/scanner${NC}"
    echo ""
    
    echo -e "${WHITE}🔧 Features Installed:${NC}"
    echo -e "${GREEN}   ✓ Google Search Scanner${NC}"
    echo -e "${GREEN}   ✓ Website Analysis Tool${NC}"
    echo -e "${GREEN}   ✓ Telegram Tracking${NC}"
    echo -e "${GREEN}   ✓ Device Information${NC}"
    echo -e "${GREEN}   ✓ Location Tracking${NC}"
    echo ""
    
    echo -e "${YELLOW}🚀 Ready to start? Type: ${WHITE}scanner${NC}"
    echo ""
}

# Fungsi utama installer
main() {
    show_installer_header
    
    echo -e "${WHITE}🔍 Starting automatic installation...${NC}"
    echo ""
    
    # Step 1: Install dependencies
    install_dependencies
    loading_animation 2 "Installing packages..."
    
    # Step 2: Setup permissions
    setup_permissions
    loading_animation 1 "Configuring permissions..."
    
    # Step 3: Download scanner
    download_scanner
    loading_animation 2 "Setting up scanner..."
    
    # Step 4: Create shortcuts
    create_shortcuts
    loading_animation 1 "Creating shortcuts..."
    
    # Step 5: Configure Telegram (optional)
    configure_telegram
    
    # Step 6: Show summary
    show_installation_summary
    
    # Optional: Launch scanner
    echo -e "${CYAN}🚀 Would you like to launch the scanner now? [y/n]${NC}"
    read -p "Choice: " launch_now
    
    if [[ "$launch_now" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}🎯 Launching Website Scanner...${NC}"
        exec "$HOME/website-scanner/scanner.sh"
    else
        echo -e "${YELLOW}👋 Thanks for installing! Use 'scanner' command to start.${NC}"
    fi
}

# Jalankan installer
main
