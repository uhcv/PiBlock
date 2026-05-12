#!/bin/bash
#
# PiBlock Minecraft Server Network Installer for Linux/Debian
# curl -sSL piblock.cat/install.sh | sudo bash
#
# Components:
#   - Velocity Proxy  (port 25565/TCP) — Java Edition entry point
#   - GeyserMC         (port 19132/UDP) — Bedrock-to-Java bridge
#   - Paper Server     (port 30066/TCP) — Main game world
#   - Limbo Server     (port 30000/TCP) — Fallback when Paper restarts
#   - Elytra           (Pyrodactyl server daemon)
#   - Web Panel        (nginx + PHP, port 80)
#
# Configs are fetched from:
#   https://github.com/uhcv/PiBlock
#

set -e

# ================================
# Root check
# ================================
if [[ $EUID -ne 0 ]]; then
    echo "Error: aquest script requereix permisos de root."
    echo "Executa: curl -sSL piblock.cat/install.sh | sudo bash"
    exit 1
fi

# ================================
# Configuration
# ================================
INSTALL_PATH="/opt/piblock"
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)  ARCH_NAME="amd64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    armv7l)  ARCH_NAME="armhf" ;;
    *)       ARCH_NAME="$ARCH" ;;
esac

# GitHub raw base URL for config files
GH_RAW="https://raw.githubusercontent.com/uhcv/PiBlock/main"

# Server JAR URLs
URL_PAPER="https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/222/downloads/paper-1.21.4-222.jar"
URL_LIMBO="https://ci.loohpjames.com/job/Limbo/lastSuccessfulBuild/artifact/target/Limbo-0.7.18-ALPHA-1.21.11.jar"
URL_VELOCITY="https://api.papermc.io/v2/projects/velocity/versions/3.4.0-SNAPSHOT/builds/469/downloads/velocity-3.4.0-SNAPSHOT-469.jar"
URL_GEYSER="https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone"

# Plugin URLs
URL_FLOODGATE_SPIGOT="https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot"
URL_FLOODGATE_VELOCITY="https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/velocity"
URL_FLOODGATE_LIMBO="https://ci.loohpjames.com/job/floodgate-limbo/lastSuccessfulBuild/artifact/target/floodgate-limbo-1.0.0.jar"
URL_HURRICANE="https://download.geysermc.org/v2/projects/hurricane/versions/latest/builds/latest/downloads/spigot"
URL_PACKETEVENTS="https://ci.codemc.io/job/retrooper/job/packetevents/lastSuccessfulBuild/artifact/build/libs/packetevents-spigot-2.11.2-SNAPSHOT.jar"
URL_GEYSEREXTRAS="https://github.com/GeyserExtras/GeyserExtras/releases/download/2.0.0-BETA-11/GeyserExtras-Extension.jar"

# Architecture-dependent URLs
if [ "$ARCH_NAME" = "arm64" ]; then
    URL_ELYTRA="https://github.com/pyrohost/elytra/releases/latest/download/elytra_linux_arm64"
    RUSTIC_ARCH="aarch64"
else
    URL_ELYTRA="https://github.com/pyrohost/elytra/releases/latest/download/elytra_linux_amd64"
    RUSTIC_ARCH="x86_64"
fi

# RAM defaults (no interactive prompts)
VELOCITY_RAM="512M"
LIMBO_RAM="256M"
PAPER_RAM="4G"
GEYSER_RAM="512M"

# Installation log
LOG_PATH="/var/log/piblock-installer.log"

# ================================
# Helper Functions
# ================================

get_time() {
    date +%s%N
}

calc_time() {
    # Arguments: start_ns end_ns  →  seconds with 1 decimal
    awk "BEGIN{printf \"%.1f\", ($2 - $1) / 1000000000}"
}

print_step() {
    local label="$1"
    local result="$2"
    local len=${#label}
    local target=40
    local pad=$(( target - len ))
    if [ "$pad" -lt 3 ]; then pad=3; fi
    local dots
    dots=$(printf '%*s' "$pad" '' | tr ' ' '.')
    echo "▸ ${label} ${dots} ${result}"
}

# Download a file — reports errors, exits on failure (set -e)
dl() {
    local url="$1"
    local output="$2"
    if ! curl -fsSL -o "$output" "$url" 2>/dev/null; then
        echo "  ERROR: no s'ha pogut descarregar $url"
        return 1
    fi
}

# Download a config file from the PiBlock GitHub repo (fails on error)
dl_gh() {
    local path="$1"
    local output="$2"
    if ! curl -fsSL -o "$output" "${GH_RAW}/${path}" 2>/dev/null; then
        echo "  ERROR: no s'ha pogut descarregar ${GH_RAW}/${path}"
        return 1
    fi
}

# Check system resources (warn if below minimums)
check_resources() {
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || echo "1")
    local ram_mb
    ram_mb=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "0")
    local disk_gb
    disk_gb=$(df -BG / 2>/dev/null | awk 'NR==2 {gsub(/G/,""); print $4}' || echo "0")
    local warnings=""

    [ "$cpu_cores" -lt 2 ]  && warnings="${warnings}  ⚠ CPU: ${cpu_cores} nucli(s) (mínim recomanat: 2)\n"
    [ "$ram_mb" -lt 2048 ]   && warnings="${warnings}  ⚠ RAM: ${ram_mb}MB (mínim recomanat: 2048MB)\n"
    [ "$disk_gb" -lt 20 ]    && warnings="${warnings}  ⚠ Disc: ${disk_gb}GB lliures (mínim recomanat: 20GB)\n"

    if [ -n "$warnings" ]; then
        echo "  ⚠ Recursos del sistema per sota del mínim:"
        echo -e "$warnings"
        echo "  La instal·lació pot continuar, però el rendiment pot ser limitat."
    fi
}

# ================================
# Installation
# ================================

TOTAL_START=$(get_time)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Initialize log file
echo "PiBlock Installer — $(date)" > "$LOG_PATH" 2>/dev/null || true

# ── 1. Detect architecture ─────────────────────────────────────
print_step "Detectant arquitectura" "$ARCH_NAME"
check_resources

# ── 2. Install OpenJDK + system dependencies + Docker ──────────
STEP_START=$(get_time)

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq > /dev/null 2>&1

apt-get install -y -qq \
    openjdk-21-jre-headless \
    ca-certificates \
    curl \
    gnupg \
    ufw \
    openssl \
    avahi-daemon \
    nginx \
    php-fpm \
    php-sqlite3 \
    php-mbstring \
    php-xml \
    sqlite3 \
    > /dev/null 2>&1

# Add Docker's official GPG key and repo (required by Elytra)
# Skip if Docker is already installed
if command -v docker > /dev/null 2>&1; then
    echo "  Docker ja està instal·lat, s'omet..." >> "$LOG_PATH" 2>/dev/null
else
    # Detect distro and codename first — Ubuntu needs a different repo URL
    DOCKER_DISTRO="debian"
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        CODENAME="${VERSION_CODENAME:-bookworm}"
        case "${ID:-}" in
            ubuntu) DOCKER_DISTRO="ubuntu" ;;
            raspbian) DOCKER_DISTRO="debian" ;;
            debian) DOCKER_DISTRO="debian" ;;
            *) DOCKER_DISTRO="debian" ;;
        esac
    else
        CODENAME="bookworm"
    fi

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" -o /etc/apt/keyrings/docker.asc 2>/dev/null
    chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DOCKER_DISTRO} ${CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list

    apt-get update -qq > /dev/null 2>&1
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
fi
systemctl enable --now docker > /dev/null 2>&1

STEP_END=$(get_time)
print_step "Instal·lant OpenJDK" "$(calc_time $STEP_START $STEP_END) s"

# ── 3. Download Paper ──────────────────────────────────────────
STEP_START=$(get_time)

mkdir -p \
    "$INSTALL_PATH/paper/plugins/floodgate" \
    "$INSTALL_PATH/paper/config" \
    "$INSTALL_PATH/velocity/plugins/floodgate" \
    "$INSTALL_PATH/limbo/plugins/floodgate" \
    "$INSTALL_PATH/geyser/extensions" \
    "$INSTALL_PATH/backups"

dl "$URL_PAPER" "$INSTALL_PATH/paper/paper.jar"
echo "eula=true" > "$INSTALL_PATH/paper/eula.txt"

STEP_END=$(get_time)
print_step "Descarregant Paper" "$(calc_time $STEP_START $STEP_END) s"

# ── 4. Download Velocity ───────────────────────────────────────
STEP_START=$(get_time)

dl "$URL_VELOCITY" "$INSTALL_PATH/velocity/velocity.jar"

STEP_END=$(get_time)
print_step "Descarregant Velocity" "$(calc_time $STEP_START $STEP_END) s"

# ── 5. Plugins · Geyser + Floodgate ───────────────────────────
STEP_START=$(get_time)

dl "$URL_GEYSER"              "$INSTALL_PATH/geyser/geyser.jar"
dl "$URL_FLOODGATE_SPIGOT"    "$INSTALL_PATH/paper/plugins/floodgate-spigot.jar"
dl "$URL_FLOODGATE_VELOCITY"  "$INSTALL_PATH/velocity/plugins/floodgate-velocity.jar"
dl "$URL_FLOODGATE_LIMBO"     "$INSTALL_PATH/limbo/plugins/floodgate-limbo.jar"
dl "$URL_HURRICANE"           "$INSTALL_PATH/paper/plugins/hurricane-spigot.jar"
dl "$URL_PACKETEVENTS"        "$INSTALL_PATH/paper/plugins/packetevents-spigot.jar"
dl "$URL_GEYSEREXTRAS"        "$INSTALL_PATH/geyser/extensions/GeyserExtras.jar"

STEP_END=$(get_time)
print_step "Plugins · Geyser + Floodgate" "$(calc_time $STEP_START $STEP_END) s"

# ── 6. Limbo (servidor d'espera) ──────────────────────────────
STEP_START=$(get_time)

dl "$URL_LIMBO" "$INSTALL_PATH/limbo/limbo.jar"

STEP_END=$(get_time)
print_step "Limbo (servidor d'espera)" "$(calc_time $STEP_START $STEP_END) s"

# ── 7. Elytra (daemon Pyrodactyl) ─────────────────────────────
STEP_START=$(get_time)

# Download Elytra binary
dl "$URL_ELYTRA" "/usr/local/bin/elytra"
chmod u+x /usr/local/bin/elytra

# Verify binary works and save version
ELYTRA_VER="unknown"
if /usr/local/bin/elytra --version > /dev/null 2>&1; then
    ELYTRA_VER=$(/usr/local/bin/elytra --version 2>/dev/null | head -1 || echo "unknown")
fi
mkdir -p /etc/pyrodactyl
echo "$ELYTRA_VER" > /etc/pyrodactyl/elytra-version

# Download and install Rustic (deduplicated encrypted backups)
# Fetch latest version from GitHub API instead of hardcoding
mkdir -p /tmp/rustic-install
RUSTIC_VER=$(curl -fsSL "https://api.github.com/repos/rustic-rs/rustic/releases/latest" 2>/dev/null \
    | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")
if [ -n "$RUSTIC_VER" ] && [ "$RUSTIC_VER" != "null" ]; then
    URL_RUSTIC="https://github.com/rustic-rs/rustic/releases/download/${RUSTIC_VER}/rustic-${RUSTIC_VER}-${RUSTIC_ARCH}-unknown-linux-musl.tar.gz"
    if curl -fsSL "$URL_RUSTIC" 2>/dev/null | tar -xz -C /tmp/rustic-install 2>/dev/null; then
        if [ -f /tmp/rustic-install/rustic ]; then
            mv /tmp/rustic-install/rustic /usr/local/bin/rustic
            chmod +x /usr/local/bin/rustic
        fi
    else
        echo "  Avís: Rustic ${RUSTIC_VER} no s'ha pogut instal·lar (els backups usaran tar)"
    fi
else
    # Fallback to hardcoded version if API fails
    URL_RUSTIC="https://github.com/rustic-rs/rustic/releases/download/v0.10.0/rustic-v0.10.0-${RUSTIC_ARCH}-unknown-linux-musl.tar.gz"
    if curl -fsSL "$URL_RUSTIC" 2>/dev/null | tar -xz -C /tmp/rustic-install 2>/dev/null; then
        if [ -f /tmp/rustic-install/rustic ]; then
            mv /tmp/rustic-install/rustic /usr/local/bin/rustic
            chmod +x /usr/local/bin/rustic
        fi
    else
        echo "  Avís: Rustic no s'ha pogut instal·lar (els backups usaran tar)"
    fi
fi
rm -rf /tmp/rustic-install

# Create pyrodactyl system group and user with UID/GID 8888
# (Required by Elytra for container volume permissions)
if ! getent group pyrodactyl > /dev/null 2>&1; then
    groupadd --gid 8888 pyrodactyl 2>/dev/null || groupadd --system pyrodactyl
fi
if ! id -u pyrodactyl > /dev/null 2>&1; then
    useradd --system --no-create-home --shell /usr/sbin/nologin \
            --uid 8888 --gid 8888 \
            --comment "Elytra/Pyrodactyl system user" pyrodactyl 2>/dev/null || \
    useradd --system --no-create-home --shell /usr/sbin/nologin \
            --comment "Elytra/Pyrodactyl system user" pyrodactyl
fi

# Add pyrodactyl user to docker group (required for container management)
usermod -aG docker pyrodactyl 2>/dev/null || true

# Elytra config and data directories
mkdir -p /etc/elytra
mkdir -p /var/lib/elytra/volumes
mkdir -p /var/lib/elytra/archives
mkdir -p /var/lib/elytra/backups

# Elytra systemd service
cat > /etc/systemd/system/elytra.service << 'ELYTRAEOF'
[Unit]
Description=Pyrodactyl Elytra Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/elytra
LimitNOFILE=4096
PIDFile=/var/run/elytra/daemon.pid
ExecStart=/usr/local/bin/elytra
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
ELYTRAEOF

STEP_END=$(get_time)
print_step "Elytra (daemon Pyrodactyl)" "$(calc_time $STEP_START $STEP_END) s"

# ── 8. Configurant systemd · firewall ─────────────────────────
STEP_START=$(get_time)

# ---- 8a. Generate secrets (no server boot needed) ----

# Velocity forwarding secret (random 12-char alphanumeric)
VELOCITY_SECRET=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)
echo -n "$VELOCITY_SECRET" > "$INSTALL_PATH/velocity/forwarding.secret"
cp "$INSTALL_PATH/velocity/forwarding.secret" "$INSTALL_PATH/paper/forwarding.secret"

# Floodgate key.pem (EC P-384 in PKCS#8 — compatible with Floodgate/Java)
KEY_TMP=$(mktemp)
if openssl ecparam -genkey -name secp384r1 -noout -out "$KEY_TMP" 2>/dev/null \
   && openssl pkcs8 -topk8 -nocrypt -in "$KEY_TMP" -out "$INSTALL_PATH/velocity/plugins/floodgate/key.pem" 2>/dev/null; then
    rm -f "$KEY_TMP"
else
    rm -f "$KEY_TMP"
    echo "  ERROR: no s'ha pogut generar key.pem per a Floodgate"
    exit 1
fi
cp "$INSTALL_PATH/velocity/plugins/floodgate/key.pem" "$INSTALL_PATH/paper/plugins/floodgate/key.pem"
cp "$INSTALL_PATH/velocity/plugins/floodgate/key.pem" "$INSTALL_PATH/limbo/plugins/floodgate/key.pem"
cp "$INSTALL_PATH/velocity/plugins/floodgate/key.pem" "$INSTALL_PATH/geyser/key.pem"

# ---- 8b. Download configs from GitHub ----

# Velocity
dl_gh "config/velocity/velocity.toml"              "$INSTALL_PATH/velocity/velocity.toml"
dl_gh "config/velocity/plugins/floodgate/config.yml" "$INSTALL_PATH/velocity/plugins/floodgate/config.yml"

# Paper
dl_gh "config/paper/server.properties"              "$INSTALL_PATH/paper/server.properties"
dl_gh "config/paper/spigot.yml"                     "$INSTALL_PATH/paper/spigot.yml"
dl_gh "config/paper/config/paper-global.yml"        "$INSTALL_PATH/paper/config/paper-global.yml"
dl_gh "config/paper/plugins/floodgate/config.yml"   "$INSTALL_PATH/paper/plugins/floodgate/config.yml"

# Limbo
dl_gh "config/limbo/server.properties"              "$INSTALL_PATH/limbo/server.properties"
dl_gh "config/limbo/spawn.schem"                    "$INSTALL_PATH/limbo/spawn.schem"
dl_gh "config/limbo/plugins/floodgate/config.yml"   "$INSTALL_PATH/limbo/plugins/floodgate/config.yml"

# Geyser
dl_gh "config/geyser/config.yml"                    "$INSTALL_PATH/geyser/config.yml"

# ---- 8c. Apply secret placeholders ----

sed -i "s/forwarding-secrets=PLACEHOLDER_SECRET/forwarding-secrets=${VELOCITY_SECRET}/" \
    "$INSTALL_PATH/limbo/server.properties"
sed -i "s/secret: PLACEHOLDER_SECRET/secret: ${VELOCITY_SECRET}/" \
    "$INSTALL_PATH/paper/config/paper-global.yml"

# ---- 8d. Systemd services for Minecraft servers ----

# Velocity
cat > /etc/systemd/system/piblock-velocity.service << EOF
[Unit]
Description=PiBlock Velocity Proxy
After=network.target

[Service]
User=root
WorkingDirectory=${INSTALL_PATH}/velocity
ExecStart=/usr/bin/java --enable-native-access=ALL-UNNAMED -Xms${VELOCITY_RAM} -Xmx${VELOCITY_RAM} -jar velocity.jar
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Paper
cat > /etc/systemd/system/piblock-paper.service << EOF
[Unit]
Description=PiBlock Paper Server
After=network.target piblock-velocity.service

[Service]
User=root
WorkingDirectory=${INSTALL_PATH}/paper
ExecStart=/usr/bin/java -Xms${PAPER_RAM} -Xmx${PAPER_RAM} -jar paper.jar --nogui
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Limbo
cat > /etc/systemd/system/piblock-limbo.service << EOF
[Unit]
Description=PiBlock Limbo Server
After=network.target piblock-velocity.service

[Service]
User=root
WorkingDirectory=${INSTALL_PATH}/limbo
ExecStart=/usr/bin/java --enable-native-access=ALL-UNNAMED -Xms${LIMBO_RAM} -Xmx${LIMBO_RAM} -jar limbo.jar --nogui
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Geyser
cat > /etc/systemd/system/piblock-geyser.service << EOF
[Unit]
Description=PiBlock GeyserMC (Bedrock bridge)
After=network.target piblock-velocity.service

[Service]
User=root
WorkingDirectory=${INSTALL_PATH}/geyser
ExecStart=/usr/bin/java --enable-native-access=ALL-UNNAMED -Xms${GEYSER_RAM} -Xmx${GEYSER_RAM} -jar geyser.jar
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload > /dev/null 2>&1
systemctl enable piblock-velocity piblock-paper piblock-limbo piblock-geyser > /dev/null 2>&1

# ---- 8e. Hostname + mDNS (piblock.cat) ----

hostnamectl set-hostname piblock 2>/dev/null || echo "piblock" > /etc/hostname
# Ensure avahi publishes the hostname
sed -i 's/#host-name=.*/host-name=piblock/' /etc/avahi/avahi-daemon.conf 2>/dev/null || true
systemctl enable --now avahi-daemon > /dev/null 2>&1 || true

# ---- 8f. UFW Firewall ----

ufw allow 22/tcp    > /dev/null 2>&1   # SSH
ufw allow 80/tcp    > /dev/null 2>&1   # Web panel
ufw allow 443/tcp   > /dev/null 2>&1   # HTTPS (optional)
ufw allow 25565/tcp > /dev/null 2>&1   # Velocity (Java)
ufw allow 19132/udp > /dev/null 2>&1   # Geyser (Bedrock)
ufw allow 8080/tcp  > /dev/null 2>&1   # Elytra daemon (Pyrodactyl)
ufw --force enable  > /dev/null 2>&1
# Nota: Paper (30066) i Limbo (30000) NO s'obren — només accessibles via Velocity (localhost)

# ---- 8g. Web Panel (nginx + PHP) ----

mkdir -p /var/www/piblock

for f in admin_users.php auth.php config.php dashboard.php db.php \
         delete_users.php login.php logout.php logs.php register.php style.css; do
    dl_gh "web/${f}" "/var/www/piblock/${f}" 2>/dev/null || true
done
chown -R www-data:www-data /var/www/piblock

# Detect PHP-FPM socket version
PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || echo "8.2")

cat > /etc/nginx/sites-available/piblock << NGINXEOF
server {
    listen 80 default_server;
    server_name piblock.cat _;

    root /var/www/piblock;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VER}-fpm.sock;
    }

    location ~ /\\.ht {
        deny all;
    }
}
NGINXEOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/piblock /etc/nginx/sites-enabled/piblock
nginx -t > /dev/null 2>&1 && systemctl enable --now nginx "php${PHP_VER}-fpm" > /dev/null 2>&1 || true

# ---- 8h. Convenience scripts ----

cat > "$INSTALL_PATH/start_all.sh" << 'STARTEOF'
#!/bin/bash
echo "Iniciant PiBlock..."
systemctl start piblock-velocity
sleep 3
systemctl start piblock-limbo piblock-paper
sleep 2
systemctl start piblock-geyser
echo "✓ Tot en marxa."
echo "  Java:    piblock.cat:25565"
echo "  Bedrock: piblock.cat:19132"
STARTEOF

cat > "$INSTALL_PATH/stop_all.sh" << 'STOPEOF'
#!/bin/bash
echo "Aturant PiBlock..."
systemctl stop piblock-geyser piblock-paper piblock-limbo piblock-velocity
echo "✓ Tot aturat."
STOPEOF

chmod +x "$INSTALL_PATH/start_all.sh" "$INSTALL_PATH/stop_all.sh"

STEP_END=$(get_time)
print_step "Configurant systemd · firewall" "$(calc_time $STEP_START $STEP_END) s"

# ── 9. Primer backup ──────────────────────────────────────────
STEP_START=$(get_time)

if command -v rustic > /dev/null 2>&1; then
    export RUSTIC_PASSWORD="piblock_backup_key"
    rustic init -r "$INSTALL_PATH/backups" > /dev/null 2>&1 || true
    rustic backup "$INSTALL_PATH/paper" -r "$INSTALL_PATH/backups" --tag initial > /dev/null 2>&1 || true
    unset RUSTIC_PASSWORD
else
    # Fallback: simple tar backup if rustic is unavailable
    tar -czf "$INSTALL_PATH/backups/initial-paper-backup.tar.gz" \
        -C "$INSTALL_PATH" paper/ > /dev/null 2>&1 || true
fi

STEP_END=$(get_time)
print_step "Primer backup" "$(calc_time $STEP_START $STEP_END) s"

# ================================
# Summary
# ================================
TOTAL_END=$(get_time)
TOTAL_TIME=$(calc_time $TOTAL_START $TOTAL_END)
TOTAL_SEC=$(printf "%.0f" "$TOTAL_TIME")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ A punt en ${TOTAL_SEC} s."
echo "Panell:  http://piblock.cat"
echo "Server: piblock.cat · 25565 (Java)"
echo "       piblock.cat · 19132 (Bedrock)"
echo ""
echo "Per arrencar els servidors Minecraft:"
echo "  $INSTALL_PATH/start_all.sh"
echo ""
echo "⚠ Elytra està instal·lat però NO configurat."
echo "  Per engegar-lo, has de seguir aquests passos:"
echo "  1. Afegeix un node al teu panell de Pyrodactyl"
echo "  2. Copia l'ordre auto-deploy (botó Configuration)"
echo "  3. Executa:  cd /etc/elytra && elytra configure --panel-url <URL> --token <TOKEN> --node <ID>"
echo "  4. Activa:    systemctl enable --now elytra"
echo ""
echo "Log d'instal·lació: $LOG_PATH"
