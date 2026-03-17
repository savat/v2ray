#!/bin/bash
# ============================================================
#  V2Ray Auto Install Script - Thai Language Edition
#  พัฒนาสำหรับ Ubuntu | Port Panel: 16522
#  เวอร์ชัน: 2.0
# ============================================================

# ── สี และ สไตล์ ──────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
BLINK='\033[5m'
NC='\033[0m' # No Color

BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BG_RED='\033[41m'
BG_CYAN='\033[46m'
BG_MAGENTA='\033[45m'

# ── ตรวจสอบ root ─────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ กรุณารันสคริปต์นี้ด้วยสิทธิ์ root${NC}"
        echo -e "${YELLOW}   ใช้คำสั่ง: sudo bash $0${NC}"
        exit 1
    fi
}

# ── ตรวจสอบ OS ────────────────────────────────────────────
check_os() {
    if ! command -v apt &>/dev/null; then
        echo -e "${RED}❌ สคริปต์นี้รองรับเฉพาะ Ubuntu/Debian เท่านั้น${NC}"
        exit 1
    fi
}

# ── ฟังก์ชัน วาดกรอบ ──────────────────────────────────────
draw_line() {
    local char="${1:-─}"
    local width="${2:-70}"
    printf '%*s' "$width" '' | tr ' ' "$char"
    echo
}

draw_box_top() {
    echo -e "${CYAN}╔$(printf '═%.0s' {1..68})╗${NC}"
}

draw_box_mid() {
    echo -e "${CYAN}╠$(printf '═%.0s' {1..68})╣${NC}"
}

draw_box_bottom() {
    echo -e "${CYAN}╚$(printf '═%.0s' {1..68})╝${NC}"
}

draw_box_line() {
    local text="$1"
    local text_len=${#text}
    local pad=$(( (68 - text_len) / 2 ))
    local pad_right=$(( 68 - text_len - pad ))
    printf "${CYAN}║${NC}%${pad}s${WHITE}%s${NC}%${pad_right}s${CYAN}║${NC}\n" "" "$text" ""
}

draw_box_line_left() {
    local text="$1"
    local pad=60
    printf "${CYAN}\u2551${NC} %b%${pad}s${CYAN}\u2551${NC}\n" "$text" ""
}

# ── Banner หลัก ───────────────────────────────────────────
show_banner() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BG_BLUE}${WHITE}  ██╗   ██╗██████╗ ██████╗  █████╗ ██╗   ██╗  ${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BG_BLUE}${WHITE}  ██║   ██║╚════██╗██╔══██╗██╔══██╗╚██╗ ██╔╝  ${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BG_BLUE}${WHITE}  ██║   ██║ █████╔╝██████╔╝███████║ ╚████╔╝   ${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BG_BLUE}${WHITE}  ╚██╗ ██╔╝██╔═══╝ ██╔══██╗██╔══██║  ╚██╔╝    ${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BG_BLUE}${WHITE}   ╚████╔╝ ███████╗██║  ██║██║  ██║   ██║     ${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}   ${BG_BLUE}${WHITE}    ╚═══╝  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝     ${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}          ${YELLOW}🚀 ระบบติดตั้ง V2Ray อัตโนมัติ สำหรับ Ubuntu${NC}           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}          ${GREEN}   Panel Port: 16522  |  พัฒนาด้วย ❤️  สำหรับไทย${NC}         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── แสดงสถานะระบบ ─────────────────────────────────────────
show_system_info() {
    local hostname=$(hostname 2>/dev/null || echo "ไม่ทราบ")
    local ip_pub=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "ไม่ทราบ")
    local ip_local=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "ไม่ทราบ")
    local os_info=$(lsb_release -d 2>/dev/null | cut -d: -f2 | xargs || echo "Ubuntu")
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "?")
    local mem_total=$(free -m | awk '/Mem:/{print $2}')
    local mem_used=$(free -m | awk '/Mem:/{print $3}')
    local disk_use=$(df -h / | awk 'NR==2{print $5}' || echo "?")
    local uptime_info=$(uptime -p 2>/dev/null | sed 's/up //' || echo "?")
    local v2ray_status
    v2ray_status="ไม่ได้ติดตั้ง"
    if systemctl is-active --quiet v2ray 2>/dev/null
    then
        v2ray_status="${GREEN}Running${NC}"
    elif systemctl is-enabled --quiet v2ray 2>/dev/null
    then
        v2ray_status="${YELLOW}Stopped${NC}"
    fi

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}${YELLOW}📊 ข้อมูลระบบ${NC}                                                       ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    printf "${CYAN}║${NC}  %-18s : ${GREEN}%-48s${NC}${CYAN}║${NC}\n" "🖥  Hostname" "$hostname"
    printf "${CYAN}║${NC}  %-18s : ${CYAN}%-48s${NC}${CYAN}║${NC}\n" "🌐 IP สาธารณะ" "$ip_pub"
    printf "${CYAN}║${NC}  %-18s : ${CYAN}%-48s${NC}${CYAN}║${NC}\n" "🔌 IP ภายใน" "$ip_local"
    printf "${CYAN}║${NC}  %-18s : %-48s${CYAN}║${NC}\n" "💻 ระบบปฏิบัติการ" "$os_info"
    printf "${CYAN}║${NC}  %-18s : %-48s${CYAN}║${NC}\n" "⏱  Uptime" "$uptime_info"
    printf "${CYAN}║${NC}  %-18s : ${YELLOW}%s MB / %s MB%-35s${NC}${CYAN}║${NC}\n" "💾 RAM" "$mem_used" "$mem_total" ""
    printf "${CYAN}║${NC}  %-18s : ${YELLOW}%-48s${NC}${CYAN}║${NC}\n" "💿 Disk ที่ใช้" "$disk_use"
    echo -e "${CYAN}║${NC}  $(printf '%-18s' "⚡ V2Ray") : $(echo -e "$v2ray_status")$(printf '%48s' '')${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ── Progress Bar ──────────────────────────────────────────
progress_bar() {
    local text="$1"
    local duration="${2:-2}"
    local width=50
    echo -ne "\n${YELLOW}  $text${NC}\n  ["
    for ((i=0; i<=width; i++)); do
        sleep $(echo "scale=3; $duration/$width" | bc 2>/dev/null || echo "0.04")
        echo -ne "${GREEN}█${NC}"
    done
    echo -e "] ${GREEN}✓ เสร็จแล้ว${NC}\n"
}

# ── Spinner ───────────────────────────────────────────────
spinner() {
    local pid=$!
    local text="$1"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r  ${CYAN}${spin:$i:1}${NC} ${text}..."
        sleep 0.1
    done
    printf "\r  ${GREEN}✅${NC} ${text}... ${GREEN}เสร็จแล้ว!${NC}\n"
}

# ── Log ───────────────────────────────────────────────────
LOG_FILE="/var/log/v2ray_install.log"
log_info()    { echo -e "  ${GREEN}[✓]${NC} $1"; echo "[INFO] $1" >> "$LOG_FILE" 2>/dev/null; }
log_warn()    { echo -e "  ${YELLOW}[!]${NC} $1"; echo "[WARN] $1" >> "$LOG_FILE" 2>/dev/null; }
log_error()   { echo -e "  ${RED}[✗]${NC} $1"; echo "[ERROR] $1" >> "$LOG_FILE" 2>/dev/null; }
log_step()    { echo -e "\n  ${CYAN}[→]${NC} ${BOLD}$1${NC}"; echo "[STEP] $1" >> "$LOG_FILE" 2>/dev/null; }

# ── ติดตั้ง dependencies ──────────────────────────────────
install_deps() {
    log_step "กำลังอัปเดตระบบและติดตั้ง dependencies..."
    echo ""
    apt-get update -qq >> "$LOG_FILE" 2>&1 &
    spinner "อัปเดต apt package list"
    apt-get install -y -qq curl wget unzip jq uuid-runtime qrencode nginx certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1 &
    spinner "ติดตั้ง packages ที่จำเป็น"
    log_info "ติดตั้ง dependencies สำเร็จ"
}

# ── ติดตั้ง V2Ray ─────────────────────────────────────────
install_v2ray() {
    log_step "กำลังติดตั้ง V2Ray..."
    echo ""

    if command -v v2ray &>/dev/null; then
        log_warn "V2Ray ติดตั้งอยู่แล้ว ข้ามขั้นตอนนี้"
        return 0
    fi

    # ดาวน์โหลด V2Ray ผ่าน official script
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) >> "$LOG_FILE" 2>&1 &
    spinner "ดาวน์โหลดและติดตั้ง V2Ray"

    if command -v v2ray &>/dev/null; then
        log_info "ติดตั้ง V2Ray สำเร็จ เวอร์ชัน: $(v2ray --version 2>/dev/null | head -1)"
    else
        log_error "ติดตั้ง V2Ray ล้มเหลว กรุณาตรวจสอบ log: $LOG_FILE"
        return 1
    fi
}

# ── สร้าง UUID ────────────────────────────────────────────
generate_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen
    else
        cat /proc/sys/kernel/random/uuid
    fi
}

# ── สร้าง config VMess ────────────────────────────────────
create_vmess_config() {
    local port="${1:-10086}"
    local uuid="${2:-$(generate_uuid)}"
    local alter_id="${3:-0}"

    mkdir -p /usr/local/etc/v2ray

    cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": ${port},
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "alterId": ${alter_id}
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/v2ray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF

    echo "$uuid"
}

# ── สร้าง config Vless ────────────────────────────────────
create_vless_config() {
    local port="${1:-10087}"
    local uuid="${2:-$(generate_uuid)}"

    mkdir -p /usr/local/etc/v2ray

    cat > /usr/local/etc/v2ray/config.json <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": ${port},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-direct"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

    echo "$uuid"
}

# ── ตั้งค่า Nginx Reverse Proxy ───────────────────────────
setup_nginx() {
    local domain="${1:-localhost}"
    local v2ray_port="${2:-10086}"
    local panel_port="${3:-16522}"

    cat > /etc/nginx/sites-available/v2ray <<EOF
# V2Ray Nginx Config - Panel Port ${panel_port}
server {
    listen 80;
    server_name ${domain};

    location /v2ray {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${v2ray_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /vless {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${v2ray_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}

# Panel Web UI - Port ${panel_port}
server {
    listen ${panel_port};
    server_name ${domain};
    root /var/www/v2ray-panel;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }

    access_log /var/log/nginx/v2ray_panel_access.log;
    error_log /var/log/nginx/v2ray_panel_error.log;
}
EOF

    ln -sf /etc/nginx/sites-available/v2ray /etc/nginx/sites-enabled/v2ray
    rm -f /etc/nginx/sites-enabled/default

    nginx -t >> "$LOG_FILE" 2>&1
    systemctl reload nginx >> "$LOG_FILE" 2>&1
    log_info "ตั้งค่า Nginx สำเร็จ"
}

# ── สร้าง Web Panel ───────────────────────────────────────
create_web_panel() {
    local uuid="$1"
    local ip_pub="$2"
    local domain="$3"
    local v2ray_port="$4"
    local panel_port="${5:-16522}"

    mkdir -p /var/www/v2ray-panel

    # สร้าง vmess link
    local vmess_json=$(echo -n "{\"v\":\"2\",\"ps\":\"V2Ray-TH\",\"add\":\"${ip_pub}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${domain}\",\"path\":\"/v2ray\",\"tls\":\"\"}" | base64 -w 0)
    local vmess_link="vmess://${vmess_json}"

    cat > /var/www/v2ray-panel/index.html <<HTMLEOF
<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>V2Ray Panel - ไทย</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Kanit:wght@300;400;600;700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
  :root {
    --bg: #0a0e1a;
    --bg2: #0f1628;
    --card: #131c35;
    --border: #1e2d52;
    --accent: #00d4ff;
    --accent2: #7c3aed;
    --accent3: #10b981;
    --accent4: #f59e0b;
    --text: #e2e8f0;
    --text-dim: #64748b;
    --danger: #ef4444;
    --glow: 0 0 30px rgba(0,212,255,0.15);
  }
  * { margin:0; padding:0; box-sizing:border-box; }
  body {
    background: var(--bg);
    color: var(--text);
    font-family: 'Kanit', sans-serif;
    min-height: 100vh;
    overflow-x: hidden;
  }
  body::before {
    content: '';
    position: fixed;
    top: -50%;
    left: -50%;
    width: 200%;
    height: 200%;
    background: radial-gradient(ellipse at 20% 20%, rgba(124,58,237,0.06) 0%, transparent 50%),
                radial-gradient(ellipse at 80% 80%, rgba(0,212,255,0.06) 0%, transparent 50%);
    pointer-events: none;
    z-index: 0;
  }
  .container { max-width: 1100px; margin: 0 auto; padding: 24px; position: relative; z-index: 1; }

  /* Header */
  .header {
    text-align: center;
    padding: 48px 0 36px;
    position: relative;
  }
  .header::after {
    content: '';
    display: block;
    width: 120px;
    height: 3px;
    background: linear-gradient(90deg, transparent, var(--accent), transparent);
    margin: 20px auto 0;
  }
  .logo-ring {
    width: 80px; height: 80px;
    border-radius: 50%;
    border: 2px solid var(--accent);
    display: flex; align-items: center; justify-content: center;
    margin: 0 auto 20px;
    box-shadow: 0 0 30px rgba(0,212,255,0.3), inset 0 0 30px rgba(0,212,255,0.05);
    animation: pulse-ring 3s ease-in-out infinite;
    font-size: 32px;
  }
  @keyframes pulse-ring {
    0%, 100% { box-shadow: 0 0 30px rgba(0,212,255,0.3), inset 0 0 30px rgba(0,212,255,0.05); }
    50%       { box-shadow: 0 0 60px rgba(0,212,255,0.5), inset 0 0 40px rgba(0,212,255,0.1); }
  }
  .header h1 { font-size: 2.2rem; font-weight: 700; letter-spacing: 2px; color: var(--accent); text-shadow: 0 0 20px rgba(0,212,255,0.4); }
  .header p { color: var(--text-dim); font-size: 0.95rem; margin-top: 6px; }

  /* Status bar */
  .status-bar {
    display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 28px;
  }
  .status-chip {
    display: flex; align-items: center; gap: 8px;
    background: var(--card); border: 1px solid var(--border);
    border-radius: 50px; padding: 8px 18px; font-size: 0.85rem;
  }
  .dot { width: 8px; height: 8px; border-radius: 50%; }
  .dot-green { background: var(--accent3); box-shadow: 0 0 8px var(--accent3); animation: blink 2s ease-in-out infinite; }
  .dot-blue  { background: var(--accent); box-shadow: 0 0 8px var(--accent); }
  .dot-purple{ background: var(--accent2); box-shadow: 0 0 8px var(--accent2); }
  @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.4} }

  /* Grid */
  .grid-2 { display: grid; grid-template-columns: repeat(auto-fit, minmax(480px, 1fr)); gap: 20px; }
  .grid-3 { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-bottom: 20px; }

  /* Cards */
  .card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 16px;
    padding: 24px;
    position: relative;
    overflow: hidden;
    transition: border-color 0.3s, box-shadow 0.3s;
  }
  .card:hover { border-color: rgba(0,212,255,0.3); box-shadow: var(--glow); }
  .card::before {
    content: '';
    position: absolute; top: 0; left: 0; right: 0; height: 2px;
    background: linear-gradient(90deg, transparent, var(--accent), transparent);
    opacity: 0; transition: opacity 0.3s;
  }
  .card:hover::before { opacity: 1; }
  .card-title {
    font-size: 0.8rem; font-weight: 600; letter-spacing: 2px;
    text-transform: uppercase; color: var(--text-dim); margin-bottom: 16px;
    display: flex; align-items: center; gap: 8px;
  }
  .card-title .icon { color: var(--accent); font-size: 1rem; }

  /* Stat cards */
  .stat-card { text-align: center; padding: 20px; }
  .stat-val { font-size: 1.8rem; font-weight: 700; color: var(--accent); font-family: 'JetBrains Mono', monospace; }
  .stat-label { font-size: 0.8rem; color: var(--text-dim); margin-top: 4px; }

  /* Info rows */
  .info-row {
    display: flex; justify-content: space-between; align-items: center;
    padding: 10px 0; border-bottom: 1px solid rgba(30,45,82,0.6);
    font-size: 0.9rem; gap: 12px;
  }
  .info-row:last-child { border-bottom: none; }
  .info-label { color: var(--text-dim); flex-shrink: 0; }
  .info-val {
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.82rem; color: var(--text);
    background: var(--bg2); border-radius: 6px;
    padding: 4px 10px; word-break: break-all; text-align: right;
    max-width: 280px;
  }
  .info-val.accent { color: var(--accent); }
  .info-val.green  { color: var(--accent3); }
  .info-val.yellow { color: var(--accent4); }

  /* VMess Link box */
  .vmess-box {
    background: var(--bg);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 14px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.75rem;
    color: var(--accent3);
    word-break: break-all;
    line-height: 1.6;
    margin-top: 12px;
    max-height: 100px;
    overflow-y: auto;
    cursor: pointer;
    transition: border-color 0.3s;
  }
  .vmess-box:hover { border-color: var(--accent); }

  /* Buttons */
  .btn {
    display: inline-flex; align-items: center; gap: 8px;
    padding: 10px 22px; border-radius: 8px; font-family: 'Kanit', sans-serif;
    font-size: 0.9rem; font-weight: 600; cursor: pointer;
    border: none; transition: all 0.25s; text-decoration: none;
  }
  .btn-primary { background: linear-gradient(135deg, var(--accent2), #5b21b6); color: white; }
  .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(124,58,237,0.4); }
  .btn-outline { background: transparent; border: 1px solid var(--accent); color: var(--accent); }
  .btn-outline:hover { background: rgba(0,212,255,0.08); transform: translateY(-2px); }
  .btn-sm { padding: 6px 14px; font-size: 0.82rem; }
  .btn-row { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 16px; }

  /* QR placeholder */
  .qr-wrap {
    display: flex; flex-direction: column; align-items: center; gap: 12px; padding: 20px 0;
  }
  .qr-box {
    width: 160px; height: 160px; border: 2px solid var(--border); border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    color: var(--text-dim); font-size: 0.8rem; text-align: center;
    background: var(--bg); position: relative; overflow: hidden;
  }
  .qr-box img { width: 100%; height: 100%; object-fit: contain; }

  /* Badge */
  .badge {
    display: inline-block; padding: 3px 10px; border-radius: 50px;
    font-size: 0.72rem; font-weight: 600; letter-spacing: 1px;
  }
  .badge-green { background: rgba(16,185,129,0.15); color: var(--accent3); border: 1px solid rgba(16,185,129,0.3); }
  .badge-blue  { background: rgba(0,212,255,0.1);  color: var(--accent);  border: 1px solid rgba(0,212,255,0.3); }
  .badge-yellow{ background: rgba(245,158,11,0.1); color: var(--accent4); border: 1px solid rgba(245,158,11,0.3); }

  /* Toast */
  .toast {
    position: fixed; bottom: 24px; right: 24px;
    background: var(--card); border: 1px solid var(--accent3);
    border-radius: 10px; padding: 14px 20px;
    color: var(--accent3); font-size: 0.9rem;
    display: flex; align-items: center; gap: 10px;
    transform: translateY(100px); opacity: 0;
    transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    z-index: 999;
  }
  .toast.show { transform: translateY(0); opacity: 1; }

  /* Tabs */
  .tabs { display: flex; gap: 4px; margin-bottom: 20px; }
  .tab {
    padding: 10px 22px; border-radius: 8px; cursor: pointer;
    font-size: 0.88rem; font-weight: 600; transition: all 0.25s;
    border: 1px solid var(--border); color: var(--text-dim);
  }
  .tab.active { background: rgba(0,212,255,0.1); border-color: var(--accent); color: var(--accent); }
  .tab-content { display: none; }
  .tab-content.active { display: block; }

  /* Footer */
  .footer { text-align: center; padding: 36px 0 24px; color: var(--text-dim); font-size: 0.82rem; }
  .footer a { color: var(--accent); text-decoration: none; }

  /* Scrollbar */
  ::-webkit-scrollbar { width: 6px; }
  ::-webkit-scrollbar-track { background: var(--bg); }
  ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--accent); }

  @media (max-width: 600px) {
    .grid-2 { grid-template-columns: 1fr; }
    .grid-3 { grid-template-columns: 1fr 1fr; }
    .header h1 { font-size: 1.6rem; }
  }
</style>
</head>
<body>
<div class="container">

  <!-- Header -->
  <div class="header">
    <div class="logo-ring">🔒</div>
    <h1>V2RAY PANEL</h1>
    <p>ระบบจัดการ V2Ray | Panel Port: ${panel_port}</p>
  </div>

  <!-- Status chips -->
  <div class="status-bar">
    <div class="status-chip"><div class="dot dot-green"></div> V2Ray: กำลังทำงาน</div>
    <div class="status-chip"><div class="dot dot-blue"></div> Nginx: Active</div>
    <div class="status-chip"><div class="dot dot-purple"></div> Panel: Port ${panel_port}</div>
    <div class="status-chip" id="time-chip">🕐 --:--:--</div>
  </div>

  <!-- Stats -->
  <div class="grid-3">
    <div class="card stat-card">
      <div class="stat-val" id="uptime">--</div>
      <div class="stat-label">⏱ Uptime ระบบ</div>
    </div>
    <div class="card stat-card">
      <div class="stat-val" id="connections">1</div>
      <div class="stat-label">👥 Connection ที่เปิด</div>
    </div>
    <div class="card stat-card">
      <div class="stat-val">${v2ray_port}</div>
      <div class="stat-label">🔌 V2Ray Port</div>
    </div>
  </div>

  <!-- Tabs -->
  <div class="tabs">
    <div class="tab active" onclick="switchTab('vmess')">VMess</div>
    <div class="tab" onclick="switchTab('vless')">VLess</div>
    <div class="tab" onclick="switchTab('system')">ระบบ</div>
    <div class="tab" onclick="switchTab('log')">Logs</div>
  </div>

  <!-- VMess Tab -->
  <div id="tab-vmess" class="tab-content active">
    <div class="grid-2">
      <div class="card">
        <div class="card-title"><span class="icon">⚙️</span> ข้อมูลการเชื่อมต่อ VMess</div>
        <div class="info-row">
          <span class="info-label">Protocol</span>
          <span class="info-val accent">VMess</span>
        </div>
        <div class="info-row">
          <span class="info-label">🌐 Server</span>
          <span class="info-val">${ip_pub}</span>
        </div>
        <div class="info-row">
          <span class="info-label">🔌 Port</span>
          <span class="info-val green">80</span>
        </div>
        <div class="info-row">
          <span class="info-label">🔑 UUID</span>
          <span class="info-val" style="font-size:0.72rem">${uuid}</span>
        </div>
        <div class="info-row">
          <span class="info-label">🔢 Alter ID</span>
          <span class="info-val">0</span>
        </div>
        <div class="info-row">
          <span class="info-label">🔗 Network</span>
          <span class="info-val yellow">WebSocket (WS)</span>
        </div>
        <div class="info-row">
          <span class="info-label">📁 Path</span>
          <span class="info-val">/v2ray</span>
        </div>
        <div class="info-row">
          <span class="info-label">🔐 TLS</span>
          <span class="info-val">none</span>
        </div>
        <div class="card-title" style="margin-top:18px"><span class="icon">🔗</span> VMess Link</div>
        <div class="vmess-box" id="vmess-link" onclick="copyText(this.innerText, 'คัดลอก VMess link แล้ว!')" title="คลิกเพื่อคัดลอก">
          ${vmess_link}
        </div>
        <div class="btn-row">
          <button class="btn btn-outline btn-sm" onclick="copyText(document.getElementById('vmess-link').innerText, 'คัดลอกแล้ว!')">📋 คัดลอก Link</button>
          <button class="btn btn-outline btn-sm" onclick="copyText('${uuid}', 'คัดลอก UUID แล้ว!')">🔑 คัดลอก UUID</button>
        </div>
      </div>

      <div class="card">
        <div class="card-title"><span class="icon">📱</span> QR Code สำหรับสแกน</div>
        <div class="qr-wrap">
          <div class="qr-box">
            <img src="https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${vmess_link}&bgcolor=131c35&color=00d4ff&margin=8" alt="QR Code" onerror="this.parentNode.innerHTML='<div style=padding:16px;color:var(--text-dim);font-size:0.78rem>📵 ไม่มี Internet<br>สร้าง QR ไม่ได้</div>'">
          </div>
          <span class="badge badge-green">✅ สแกนด้วย V2RayNG หรือ Shadowrocket</span>
        </div>
        <div class="card-title" style="margin-top:8px"><span class="icon">📥</span> แอปที่แนะนำ</div>
        <div style="display:flex; flex-wrap:wrap; gap:8px; margin-top:8px">
          <span class="badge badge-blue">Android: V2RayNG</span>
          <span class="badge badge-blue">iOS: Shadowrocket</span>
          <span class="badge badge-yellow">Windows: V2RayN</span>
          <span class="badge badge-yellow">macOS: V2RayX</span>
        </div>
      </div>
    </div>
  </div>

  <!-- VLess Tab -->
  <div id="tab-vless" class="tab-content">
    <div class="card">
      <div class="card-title"><span class="icon">⚡</span> ข้อมูลการเชื่อมต่อ VLess</div>
      <div class="info-row">
        <span class="info-label">Protocol</span>
        <span class="info-val accent">VLess</span>
      </div>
      <div class="info-row">
        <span class="info-label">🌐 Server</span>
        <span class="info-val">${ip_pub}</span>
      </div>
      <div class="info-row">
        <span class="info-label">🔌 Port</span>
        <span class="info-val green">80</span>
      </div>
      <div class="info-row">
        <span class="info-label">🔑 UUID</span>
        <span class="info-val" style="font-size:0.72rem">${uuid}</span>
      </div>
      <div class="info-row">
        <span class="info-label">🔗 Network</span>
        <span class="info-val yellow">WebSocket (WS)</span>
      </div>
      <div class="info-row">
        <span class="info-label">📁 Path</span>
        <span class="info-val">/vless</span>
      </div>
      <div style="margin-top:16px; padding:14px; background:var(--bg2); border-radius:10px; border:1px solid var(--border);">
        <p style="color:var(--accent4); font-size:0.85rem;">⚠️ VLess ต้องใช้ TLS หรือ XTLS เพื่อความปลอดภัยสูงสุด แนะนำให้ติดตั้ง SSL certificate</p>
      </div>
    </div>
  </div>

  <!-- System Tab -->
  <div id="tab-system" class="tab-content">
    <div class="grid-2">
      <div class="card">
        <div class="card-title"><span class="icon">🖥</span> ข้อมูลเซิร์ฟเวอร์</div>
        <div class="info-row">
          <span class="info-label">🌐 IP สาธารณะ</span>
          <span class="info-val accent">${ip_pub}</span>
        </div>
        <div class="info-row">
          <span class="info-label">🔌 V2Ray Port</span>
          <span class="info-val green">${v2ray_port}</span>
        </div>
        <div class="info-row">
          <span class="info-label">🖥 Panel Port</span>
          <span class="info-val yellow">${panel_port}</span>
        </div>
        <div class="info-row">
          <span class="info-label">📄 Config Path</span>
          <span class="info-val">/usr/local/etc/v2ray/config.json</span>
        </div>
        <div class="info-row">
          <span class="info-label">📋 Log Access</span>
          <span class="info-val">/var/log/v2ray/access.log</span>
        </div>
        <div class="info-row">
          <span class="info-label">❌ Log Error</span>
          <span class="info-val">/var/log/v2ray/error.log</span>
        </div>
      </div>
      <div class="card">
        <div class="card-title"><span class="icon">🛠</span> คำสั่งจัดการระบบ</div>
        <div style="display:flex; flex-direction:column; gap:10px; margin-top:4px">
          <div style="background:var(--bg); padding:10px 14px; border-radius:8px; border-left:3px solid var(--accent3)">
            <div style="font-size:0.72rem; color:var(--text-dim); margin-bottom:4px">เริ่มบริการ</div>
            <code style="font-family:'JetBrains Mono',monospace; font-size:0.82rem; color:var(--accent3)">systemctl start v2ray</code>
          </div>
          <div style="background:var(--bg); padding:10px 14px; border-radius:8px; border-left:3px solid var(--danger)">
            <div style="font-size:0.72rem; color:var(--text-dim); margin-bottom:4px">หยุดบริการ</div>
            <code style="font-family:'JetBrains Mono',monospace; font-size:0.82rem; color:var(--danger)">systemctl stop v2ray</code>
          </div>
          <div style="background:var(--bg); padding:10px 14px; border-radius:8px; border-left:3px solid var(--accent4)">
            <div style="font-size:0.72rem; color:var(--text-dim); margin-bottom:4px">รีสตาร์ท</div>
            <code style="font-family:'JetBrains Mono',monospace; font-size:0.82rem; color:var(--accent4)">systemctl restart v2ray</code>
          </div>
          <div style="background:var(--bg); padding:10px 14px; border-radius:8px; border-left:3px solid var(--accent)">
            <div style="font-size:0.72rem; color:var(--text-dim); margin-bottom:4px">ตรวจสอบสถานะ</div>
            <code style="font-family:'JetBrains Mono',monospace; font-size:0.82rem; color:var(--accent)">systemctl status v2ray</code>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Log Tab -->
  <div id="tab-log" class="tab-content">
    <div class="card">
      <div class="card-title"><span class="icon">📋</span> ไฟล์ Log ระบบ</div>
      <div style="background:var(--bg); padding:16px; border-radius:10px; font-family:'JetBrains Mono',monospace; font-size:0.8rem; color:var(--accent3); min-height:160px; border:1px solid var(--border)">
        <div style="color:var(--text-dim); margin-bottom:10px"># Access Log: /var/log/v2ray/access.log</div>
        <div style="color:var(--text-dim)"># Error Log:  /var/log/v2ray/error.log</div>
        <div style="margin-top:16px; color:var(--accent4)">⚠️ เปิด Terminal แล้วใช้คำสั่ง:</div>
        <div style="margin-top:8px">tail -f /var/log/v2ray/access.log</div>
        <div style="margin-top:4px">journalctl -u v2ray -f</div>
      </div>
    </div>
  </div>

  <div class="footer">
    <p>V2Ray Auto Install Panel • Port <span style="color:var(--accent)">${panel_port}</span> • พัฒนาสำหรับ Ubuntu 🇹🇭</p>
    <p style="margin-top:6px"><a href="https://github.com/v2fly/v2ray-core" target="_blank">V2Ray Core</a> • <a href="https://www.v2fly.org" target="_blank">Docs</a></p>
  </div>
</div>

<!-- Toast -->
<div class="toast" id="toast">✅ <span id="toast-text">คัดลอกแล้ว!</span></div>

<script>
  // Time
  function updateTime() {
    const now = new Date();
    document.getElementById('time-chip').innerHTML = '🕐 ' + now.toLocaleTimeString('th-TH');
  }
  updateTime(); setInterval(updateTime, 1000);

  // Uptime
  const start = Date.now();
  setInterval(() => {
    const s = Math.floor((Date.now()-start)/1000);
    const h = Math.floor(s/3600), m = Math.floor((s%3600)/60), sec = s%60;
    document.getElementById('uptime').textContent =
      (h?h+'h ':'')+String(m).padStart(2,'0')+'m '+String(sec).padStart(2,'0')+'s';
  }, 1000);

  // Tabs
  function switchTab(name) {
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.getElementById('tab-'+name).classList.add('active');
    event.target.classList.add('active');
  }

  // Copy
  function copyText(text, msg) {
    navigator.clipboard.writeText(text).then(() => showToast(msg||'คัดลอกแล้ว!'));
  }
  function showToast(msg) {
    const t = document.getElementById('toast');
    document.getElementById('toast-text').textContent = msg;
    t.classList.add('show');
    setTimeout(() => t.classList.remove('show'), 3000);
  }
</script>
</body>
</html>
HTMLEOF

    log_info "สร้าง Web Panel สำเร็จ"
}

# ── ตั้งค่า Firewall ──────────────────────────────────────
setup_firewall() {
    local panel_port="${1:-16522}"
    log_step "ตั้งค่า Firewall..."

    if command -v ufw &>/dev/null; then
        ufw allow 22/tcp   >> "$LOG_FILE" 2>&1
        ufw allow 80/tcp   >> "$LOG_FILE" 2>&1
        ufw allow 443/tcp  >> "$LOG_FILE" 2>&1
        ufw allow "$panel_port"/tcp >> "$LOG_FILE" 2>&1
        ufw --force enable >> "$LOG_FILE" 2>&1
        log_info "ตั้งค่า UFW firewall สำเร็จ (port 22, 80, 443, $panel_port)"
    else
        log_warn "ไม่พบ ufw ข้ามขั้นตอนนี้"
    fi
}

# ── แสดงสรุปผล ────────────────────────────────────────────
show_summary() {
    local uuid="$1"
    local ip_pub="$2"
    local domain="$3"
    local v2ray_port="$4"
    local panel_port="${5:-16522}"

    local vmess_json=$(echo -n "{\"v\":\"2\",\"ps\":\"V2Ray-TH\",\"add\":\"${ip_pub}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"${domain}\",\"path\":\"/v2ray\",\"tls\":\"\"}" | base64 -w 0)

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}                                                                      ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}   ${BOLD}${GREEN}🎉 ติดตั้ง V2Ray สำเร็จเรียบร้อย!${NC}                                    ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                                      ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    printf "${GREEN}║${NC}  ${CYAN}%-22s${NC}: ${WHITE}%-44s${NC}${GREEN}║${NC}\n" "🌐 Server IP" "$ip_pub"
    printf "${GREEN}║${NC}  ${CYAN}%-22s${NC}: ${YELLOW}%-44s${NC}${GREEN}║${NC}\n" "🔑 UUID" "$uuid"
    printf "${GREEN}║${NC}  ${CYAN}%-22s${NC}: ${WHITE}%-44s${NC}${GREEN}║${NC}\n" "📡 Protocol" "VMess + WebSocket"
    printf "${GREEN}║${NC}  ${CYAN}%-22s${NC}: ${WHITE}%-44s${NC}${GREEN}║${NC}\n" "🔌 V2Ray Port" "$v2ray_port"
    printf "${GREEN}║${NC}  ${CYAN}%-22s${NC}: ${WHITE}%-44s${NC}${GREEN}║${NC}\n" "📁 WS Path" "/v2ray"
    printf "${GREEN}║${NC}  ${CYAN}%-22s${NC}: ${GREEN}%-44s${NC}${GREEN}║${NC}\n" "🖥 Panel URL" "http://${ip_pub}:${panel_port}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}${YELLOW}VMess Link (คัดลอกไปวางในแอป):${NC}                                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}vmess://${vmess_json:0:60}${NC}  ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${DIM}(link เต็มอยู่ใน Web Panel)${NC}                                          ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}คำสั่งที่ควรรู้:${NC}                                                      ${GREEN}║${NC}"
    printf "${GREEN}║${NC}  ${YELLOW}%-32s${NC} %-36s${GREEN}║${NC}\n" "systemctl status v2ray" "# ตรวจสอบสถานะ"
    printf "${GREEN}║${NC}  ${YELLOW}%-32s${NC} %-36s${GREEN}║${NC}\n" "systemctl restart v2ray" "# รีสตาร์ท"
    printf "${GREEN}║${NC}  ${YELLOW}%-32s${NC} %-36s${GREEN}║${NC}\n" "journalctl -u v2ray -f" "# ดู log แบบ realtime"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ════════════════════════════════════════════════════════════
#  เมนูหลัก
# ════════════════════════════════════════════════════════════

menu_install() {
    show_banner
    echo -e "${CYAN}[ ขั้นตอนที่ 1/5 ]${NC} ตั้งค่าข้อมูลการติดตั้ง"
    echo ""

    # รับ domain หรือ IP
    local ip_pub=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
    echo -e "  ${YELLOW}IP สาธารณะของเซิร์ฟเวอร์:${NC} ${GREEN}${ip_pub}${NC}"
    echo ""
    read -rp "  กรอก Domain (หรือกด Enter เพื่อใช้ IP: ${ip_pub}): " input_domain
    local domain="${input_domain:-$ip_pub}"

    read -rp "  กรอก Port V2Ray (default: 10086): " input_port
    local v2ray_port="${input_port:-10086}"

    echo ""
    echo -e "  ${CYAN}Panel Port:${NC} ${GREEN}16522${NC} (ถูกกำหนดไว้แล้ว)"
    local panel_port="16522"

    echo ""
    echo -e "${CYAN}[ สรุปการตั้งค่า ]${NC}"
    echo -e "  Domain/IP     : ${GREEN}${domain}${NC}"
    echo -e "  V2Ray Port    : ${GREEN}${v2ray_port}${NC}"
    echo -e "  Panel Port    : ${GREEN}${panel_port}${NC}"
    echo ""
    read -rp "  ยืนยันการติดตั้ง? (y/N): " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && echo -e "  ${YELLOW}ยกเลิกการติดตั้ง${NC}" && return

    echo ""
    # ขั้นตอนการติดตั้ง
    echo -e "${CYAN}[ ขั้นตอนที่ 2/5 ]${NC} ติดตั้ง dependencies"
    install_deps

    echo -e "${CYAN}[ ขั้นตอนที่ 3/5 ]${NC} ติดตั้ง V2Ray"
    install_v2ray || return 1

    echo -e "${CYAN}[ ขั้นตอนที่ 4/5 ]${NC} สร้างและตั้งค่า"
    local uuid=$(create_vmess_config "$v2ray_port")
    setup_nginx "$domain" "$v2ray_port" "$panel_port"
    create_web_panel "$uuid" "$ip_pub" "$domain" "$v2ray_port" "$panel_port"
    setup_firewall "$panel_port"

    echo -e "${CYAN}[ ขั้นตอนที่ 5/5 ]${NC} เริ่มบริการ"
    systemctl enable v2ray  >> "$LOG_FILE" 2>&1
    systemctl restart v2ray >> "$LOG_FILE" 2>&1
    systemctl restart nginx >> "$LOG_FILE" 2>&1
    log_info "เริ่มบริการ V2Ray และ Nginx สำเร็จ"

    show_summary "$uuid" "$ip_pub" "$domain" "$v2ray_port" "$panel_port"

    read -rp "  กด Enter เพื่อกลับเมนูหลัก..."
}

menu_status() {
    show_banner
    show_system_info
    echo -e "${CYAN}[ สถานะบริการ ]${NC}"
    echo ""
    for svc in v2ray nginx; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            printf "  ${GREEN}✅${NC} %-12s: ${GREEN}กำลังทำงาน${NC}\n" "$svc"
        else
            printf "  ${RED}❌${NC} %-12s: ${RED}หยุดทำงาน${NC}\n" "$svc"
        fi
    done
    echo ""
    if [[ -f /usr/local/etc/v2ray/config.json ]]; then
        local uuid=$(jq -r '.inbounds[0].settings.clients[0].id' /usr/local/etc/v2ray/config.json 2>/dev/null || echo "ไม่พบ")
        local port=$(jq -r '.inbounds[0].port' /usr/local/etc/v2ray/config.json 2>/dev/null || echo "ไม่พบ")
        echo -e "  ${YELLOW}UUID  :${NC} ${WHITE}${uuid}${NC}"
        echo -e "  ${YELLOW}Port  :${NC} ${WHITE}${port}${NC}"
        echo -e "  ${YELLOW}Panel :${NC} ${GREEN}http://$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}'):16522${NC}"
    fi
    echo ""
    read -rp "  กด Enter เพื่อกลับเมนูหลัก..."
}

menu_manage() {
    while true; do
        show_banner
        echo -e "${CYAN}╔══════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}  ${BOLD}จัดการบริการ V2Ray${NC}               ${CYAN}║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}1.${NC} เริ่มบริการ V2Ray               ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}2.${NC} หยุดบริการ V2Ray               ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${BLUE}3.${NC} รีสตาร์ท V2Ray                 ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${MAGENTA}4.${NC} ดู Log แบบ realtime           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${RED}5.${NC} ถอนการติดตั้ง V2Ray            ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${WHITE}0.${NC} กลับเมนูหลัก                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════╝${NC}"
        echo ""
        read -rp "  เลือก [0-5]: " choice
        case "$choice" in
            1) systemctl start v2ray   && log_info "เริ่ม V2Ray สำเร็จ" || log_error "ล้มเหลว" ;;
            2) systemctl stop v2ray    && log_info "หยุด V2Ray สำเร็จ"  || log_error "ล้มเหลว" ;;
            3) systemctl restart v2ray && log_info "รีสตาร์ทสำเร็จ"     || log_error "ล้มเหลว" ;;
            4) echo -e "\n  ${CYAN}กด Ctrl+C เพื่อออก${NC}\n"; journalctl -u v2ray -f ;;
            5)
                read -rp "  ${RED}⚠️  ยืนยันถอนการติดตั้ง V2Ray? (y/N): ${NC}" del
                if [[ "$del" =~ ^[Yy]$ ]]; then
                    systemctl stop v2ray 2>/dev/null
                    systemctl disable v2ray 2>/dev/null
                    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --remove >> "$LOG_FILE" 2>&1
                    rm -rf /usr/local/etc/v2ray /var/www/v2ray-panel
                    log_info "ถอนการติดตั้ง V2Ray สำเร็จ"
                fi
                ;;
            0) break ;;
            *) log_warn "ตัวเลือกไม่ถูกต้อง" ;;
        esac
        [[ "$choice" != "4" ]] && read -rp "  กด Enter เพื่อดำเนินการต่อ..."
    done
}

menu_cert() {
    show_banner
    echo -e "${CYAN}[ SSL Certificate - Let's Encrypt ]${NC}"
    echo ""
    read -rp "  กรอก Domain ที่ต้องการ SSL: " ssl_domain
    read -rp "  กรอก Email สำหรับ Let's Encrypt: " ssl_email
    if [[ -z "$ssl_domain" || -z "$ssl_email" ]]; then
        log_error "กรุณากรอก domain และ email"
        read -rp "  กด Enter..."; return
    fi
    echo ""
    log_step "ขอ SSL certificate สำหรับ ${ssl_domain}..."
    certbot --nginx -d "$ssl_domain" --email "$ssl_email" --agree-tos --non-interactive >> "$LOG_FILE" 2>&1
    if [[ $? -eq 0 ]]; then
        log_info "ออก SSL certificate สำเร็จ!"
        log_info "HTTPS: https://${ssl_domain}"
    else
        log_error "ออก SSL certificate ล้มเหลว ตรวจสอบ log: $LOG_FILE"
    fi
    read -rp "  กด Enter เพื่อกลับเมนูหลัก..."
}

# ════════════════════════════════════════════════════════════
#  Main Menu
# ════════════════════════════════════════════════════════════
main_menu() {
    while true; do
        show_banner
        show_system_info

        echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}  ${BOLD}${WHITE}เมนูหลัก${NC}                                                             ${CYAN}║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}                                                                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}   ${BG_GREEN}${WHITE} 1 ${NC}  ${BOLD}ติดตั้ง V2Ray พร้อม Web Panel (Port 16522)${NC}                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}   ${BG_BLUE}${WHITE} 2 ${NC}  ${BOLD}ตรวจสอบสถานะและข้อมูลการเชื่อมต่อ${NC}                          ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}   ${BG_MAGENTA}${WHITE} 3 ${NC}  ${BOLD}จัดการบริการ (Start/Stop/Restart/Log)${NC}                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}   ${YELLOW}${BOLD} 4 ${NC}  ${BOLD}ติดตั้ง SSL Certificate (Let's Encrypt)${NC}                    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}   ${RED}${BOLD} 0 ${NC}  ${BOLD}ออกจากสคริปต์${NC}                                              ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                                      ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -rp "  ${BOLD}เลือกเมนู [0-4]: ${NC}" choice
        echo ""
        case "$choice" in
            1) menu_install ;;
            2) menu_status  ;;
            3) menu_manage  ;;
            4) menu_cert    ;;
            0) echo -e "  ${GREEN}ขอบคุณที่ใช้งาน V2Ray Auto Install 🇹🇭${NC}\n"; exit 0 ;;
            *) log_warn "กรุณาเลือก 0-4"; sleep 1 ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  Entry Point
# ════════════════════════════════════════════════════════════
check_root
check_os
touch "$LOG_FILE" 2>/dev/null
main_menu
