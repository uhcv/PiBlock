#!/bin/bash
#
# PiBlock Minecraft Server Network Installer for Linux/Debian
# 
# Downloads and configures all components for the PiBlock server network:
# - Velocity Proxy (port 25565)
# - Paper Server (port 30066)
# - Limbo Server (port 30000)
# - GeyserMC Standalone (port 19132)
# - All required plugins and configurations
#
# Requirements: bash, curl or wget, Java 21+
#

set -e
check_java() {
    echo -n "Checking Java version... "
    if type -p java > /dev/null; then
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        _java="$JAVA_HOME/bin/java"
    else
        echo -e "${RED}Not found${NC}"
        echo -e "${RED}Error: Java is not installed or not in PATH.${NC}"
        read -p "Continue anyway? (y/N): " confirm
        if [[ "$confirm" != "y" ]]; then exit 1; fi
        return
    fi

    if [[ "$_java" ]]; then
        version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        if [[ -z "$version" ]]; then
             version=$("$_java" -version 2>&1 | head -n 1 | awk '{print $NF}')
        fi
        
        major=$(echo "$version" | cut -d'.' -f1)
        if [[ "$major" -eq "1" ]]; then
            major=$(echo "$version" | cut -d'.' -f2)
        fi

        if [[ "$major" -ge 21 ]]; then
            echo -e "${GREEN}Found Java $major (OK)${NC}"
        else
            echo -e "${RED}Found Java $major (Too old)${NC}"
            echo -e "${RED}Error: Java 21 or later is required.${NC}"
            read -p "Continue anyway? (y/N): " confirm
            if [[ "$confirm" != "y" ]]; then exit 1; fi
        fi
    fi
}

check_java

# ================================
# Colors
# ================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# ================================
# ASCII Logo
# ================================
echo -e "${CYAN}"
cat << 'EOF'

  _____  _ ____  _            _    
 |  __ \(_)  _ \| |          | |   
 | |__) |_| |_) | | ___   ___| | __
 |  ___/| |  _ <| |/ _ \ / __| |/ /
 | |    | | |_) | | (_) | (__|   < 
 |_|    |_|____/|_|\___/ \___|_|\_\
                                   
    Minecraft Server Network Installer

EOF
echo -e "${NC}"

# ================================
# Configuration
# ================================

# Download URLs
URL_PAPER="https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/222/downloads/paper-1.21.4-222.jar"
URL_LIMBO="https://ci.loohpjames.com/job/Limbo/lastSuccessfulBuild/artifact/target/Limbo-0.7.18-ALPHA-1.21.11.jar"
URL_VELOCITY="https://api.papermc.io/v2/projects/velocity/versions/3.4.0-SNAPSHOT/builds/469/downloads/velocity-3.4.0-SNAPSHOT-469.jar"
URL_GEYSER="https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone"
URL_FLOODGATE_SPIGOT="https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot"
URL_FLOODGATE_VELOCITY="https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/velocity"
URL_FLOODGATE_LIMBO="https://ci.loohpjames.com/job/floodgate-limbo/lastSuccessfulBuild/artifact/target/floodgate-limbo-1.0.0.jar"
URL_HURRICANE="https://download.geysermc.org/v2/projects/hurricane/versions/latest/builds/latest/downloads/spigot"
URL_PACKETEVENTS="https://ci.codemc.io/job/retrooper/job/packetevents/lastSuccessfulBuild/artifact/build/libs/packetevents-spigot-2.11.2-SNAPSHOT.jar"
URL_GEYSEREXTRAS="https://github.com/GeyserExtras/GeyserExtras/releases/download/2.0.0-BETA-11/GeyserExtras-Extension.jar"

# ================================
# Helper Functions
# ================================



prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    read -p "$prompt [$default]: " result
    echo "${result:-$default}"
}

download_file() {
    local url="$1"
    local output="$2"
    local name="$3"
    
    echo -ne "  Downloading ${YELLOW}$name${NC}..."
    
    if command -v curl &> /dev/null; then
        if curl -fsSL -o "$output" "$url" 2>/dev/null; then
            echo -e " ${GREEN}Done${NC}"
        else
            echo -e " ${RED}Failed${NC}"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -q -O "$output" "$url" 2>/dev/null; then
            echo -e " ${GREEN}Done${NC}"
        else
            echo -e " ${RED}Failed${NC}"
            return 1
        fi
    else
        echo -e " ${RED}Error: Neither curl nor wget found${NC}"
        return 1
    fi
}

# ================================
# User Prompts
# ================================

echo ""
echo -e "${MAGENTA}=== Installation Configuration ===${NC}"
echo ""

INSTALL_PATH=$(prompt_with_default "Installation folder" "./PiBlock")
VELOCITY_RAM=$(prompt_with_default "Velocity RAM (e.g. 512M, 1G)" "512M")
LIMBO_RAM=$(prompt_with_default "Limbo RAM (e.g. 256M, 512M)" "256M")
PAPER_RAM=$(prompt_with_default "Paper RAM (Recommended: 4G)" "4G")
GEYSER_RAM=$(prompt_with_default "Geyser RAM (e.g. 512M, 1G)" "512M")

# Resolve to absolute path
INSTALL_PATH=$(cd "$(dirname "$INSTALL_PATH")" 2>/dev/null && pwd)/$(basename "$INSTALL_PATH")

echo ""
echo -e "${CYAN}Installation will proceed with:${NC}"
echo -e "  Path:     ${WHITE}$INSTALL_PATH${NC}"
echo -e "  Velocity: ${WHITE}$VELOCITY_RAM${NC}"
echo -e "  Limbo:    ${WHITE}$LIMBO_RAM${NC}"
echo -e "  Paper:    ${WHITE}$PAPER_RAM${NC}"
echo -e "  Geyser:   ${WHITE}$GEYSER_RAM${NC}"
echo ""

read -p "Continue? (Y/n): " confirm
if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

# ================================
# Create Directory Structure
# ================================

echo ""
echo -e "${MAGENTA}=== Creating Directory Structure ===${NC}"

directories=(
    "$INSTALL_PATH"
    "$INSTALL_PATH/paper"
    "$INSTALL_PATH/paper/config"
    "$INSTALL_PATH/paper/plugins"
    "$INSTALL_PATH/paper/plugins/floodgate"
    "$INSTALL_PATH/limbo"
    "$INSTALL_PATH/limbo/plugins"
    "$INSTALL_PATH/limbo/plugins/floodgate"
    "$INSTALL_PATH/velocity"
    "$INSTALL_PATH/velocity/plugins"
    "$INSTALL_PATH/velocity/plugins/floodgate"
    "$INSTALL_PATH/geyser"
    "$INSTALL_PATH/geyser/extensions"
)

for dir in "${directories[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        echo -e "  ${GRAY}Created: $dir${NC}"
    fi
done

echo -e "  ${GREEN}Directory structure created.${NC}"



# ================================
# Download Server JARs
# ================================

echo ""
echo -e "${MAGENTA}=== Downloading Server Components ===${NC}"

download_file "$URL_PAPER" "$INSTALL_PATH/paper/paper.jar" "Paper Server"
download_file "$URL_LIMBO" "$INSTALL_PATH/limbo/limbo.jar" "Limbo Server"
download_file "$URL_VELOCITY" "$INSTALL_PATH/velocity/velocity.jar" "Velocity Proxy"
download_file "$URL_GEYSER" "$INSTALL_PATH/geyser/geyser.jar" "GeyserMC"

# ================================
# Download Plugins
# ================================

echo ""
echo -e "${MAGENTA}=== Downloading Plugins ===${NC}"

download_file "$URL_FLOODGATE_SPIGOT" "$INSTALL_PATH/paper/plugins/floodgate-spigot.jar" "Floodgate (Paper)"
download_file "$URL_FLOODGATE_VELOCITY" "$INSTALL_PATH/velocity/plugins/floodgate-velocity.jar" "Floodgate (Velocity)"
download_file "$URL_FLOODGATE_LIMBO" "$INSTALL_PATH/limbo/plugins/floodgate-limbo.jar" "Floodgate (Limbo)"
download_file "$URL_HURRICANE" "$INSTALL_PATH/paper/plugins/hurricane-spigot.jar" "Hurricane"
download_file "$URL_PACKETEVENTS" "$INSTALL_PATH/paper/plugins/packetevents-spigot.jar" "PacketEvents"
download_file "$URL_GEYSEREXTRAS" "$INSTALL_PATH/geyser/extensions/GeyserExtras.jar" "GeyserExtras"

# ================================
# Stage 1: Generate Forwarding Secret
# ================================

echo ""
echo -e "${MAGENTA}=== Stage 1: Generating Forwarding Secret ===${NC}"
echo -e "${YELLOW}  Starting Velocity (Initial Boot) to generate forwarding.secret...${NC}"

# Ensure no existing velocity.toml
if [[ -f "$INSTALL_PATH/velocity/velocity.toml" ]]; then
    rm "$INSTALL_PATH/velocity/velocity.toml"
fi

(cd "$INSTALL_PATH/velocity" && java -jar velocity.jar > stage1.log 2> stage1_error.log) &
VELOCITY_PID=$!

SECRET_PATH="$INSTALL_PATH/velocity/forwarding.secret"
timeout=0
max_timeout=60

while [[ ! -f "$SECRET_PATH" ]]; do
    if [[ $timeout -ge $max_timeout ]]; then
        echo -e "${RED}  Timeout waiting for forwarding.secret generation!${NC}"
        kill $VELOCITY_PID 2>/dev/null
        break
    fi
    sleep 1
    timeout=$((timeout+1))
    echo -n -e "${GRAY}.${NC}"
done
echo ""

if [[ -f "$SECRET_PATH" ]]; then
    echo -e "  ${GREEN}Forwarding secret generated successfully.${NC}"
    VELOCITY_SECRET=$(cat "$SECRET_PATH")
else
    echo -e "  ${YELLOW}Failed to generate forwarding.secret. Using fallback.${NC}"
    VELOCITY_SECRET=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)
    echo -n "$VELOCITY_SECRET" > "$SECRET_PATH"
fi

# Stop Velocity
kill $VELOCITY_PID 2>/dev/null
wait $VELOCITY_PID 2>/dev/null

# ================================
# Stage 2: Deploy Configurations and Plugins
# ================================

echo ""
echo -e "${MAGENTA}=== Stage 2: Deploying Configurations and Plugins ===${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy base configs from the 'config' directory
CONFIG_DIR="$SCRIPT_DIR/config"

# Generate EULA
echo "eula=true" > "$INSTALL_PATH/paper/eula.txt"

cp "$CONFIG_DIR/paper/server.properties" "$INSTALL_PATH/paper/"
cp "$CONFIG_DIR/paper/spigot.yml" "$INSTALL_PATH/paper/"
cp "$CONFIG_DIR/paper/plugins/floodgate/config.yml" "$INSTALL_PATH/paper/plugins/floodgate/"
cp "$CONFIG_DIR/limbo/server.properties" "$INSTALL_PATH/limbo/"
cp "$CONFIG_DIR/limbo/spawn.schem" "$INSTALL_PATH/limbo/"
cp "$CONFIG_DIR/limbo/plugins/floodgate/config.yml" "$INSTALL_PATH/limbo/plugins/floodgate/"
cp "$CONFIG_DIR/velocity/velocity.toml" "$INSTALL_PATH/velocity/"
cp "$CONFIG_DIR/velocity/plugins/floodgate/config.yml" "$INSTALL_PATH/velocity/plugins/floodgate/"
cp "$CONFIG_DIR/geyser/config.yml" "$INSTALL_PATH/geyser/"
cp "$CONFIG_DIR/paper/config/paper-global.yml" "$INSTALL_PATH/paper/config/"

# Apply captured secret
cp "$SECRET_PATH" "$INSTALL_PATH/paper/forwarding.secret"
sed -i "s/forwarding-secrets=PLACEHOLDER_SECRET/forwarding-secrets=$VELOCITY_SECRET/" "$INSTALL_PATH/limbo/server.properties"
sed -i "s/secret: PLACEHOLDER_SECRET/secret: $VELOCITY_SECRET/" "$INSTALL_PATH/paper/config/paper-global.yml"

echo -e "  ${GREEN}Configurations deployed and secret applied.${NC}"

# ================================
# Stage 3: Generate Floodgate Key
# ================================

echo ""
echo -e "${MAGENTA}=== Stage 3: Generating Floodgate Key ===${NC}"
echo -e "${YELLOW}  Starting Velocity (Second Boot) to generate key.pem...${NC}"

(cd "$INSTALL_PATH/velocity" && java -jar velocity.jar > stage3.log 2> stage3_error.log) &
VELOCITY_PID=$!

KEY_PATH="$INSTALL_PATH/velocity/plugins/floodgate/key.pem"
timeout=0

while [[ ! -f "$KEY_PATH" ]]; do
    if [[ $timeout -ge $max_timeout ]]; then
        echo -e "${RED}  Timeout waiting for key.pem generation!${NC}"
        kill $VELOCITY_PID 2>/dev/null
        break
    fi
    sleep 1
    timeout=$((timeout+1))
    echo -n -e "${GRAY}.${NC}"
done
echo ""

if [[ -f "$KEY_PATH" ]]; then
    echo -e "  ${GREEN}Floodgate key generated successfully.${NC}"
    
    # Distribute key
    cp "$KEY_PATH" "$INSTALL_PATH/paper/plugins/floodgate/"
    cp "$KEY_PATH" "$INSTALL_PATH/limbo/plugins/floodgate/"
    cp "$KEY_PATH" "$INSTALL_PATH/geyser/"
    echo -e "  ${GREEN}Distributed key.pem to Paper, Limbo, and Geyser.${NC}"
fi

# Stop Velocity
kill $VELOCITY_PID 2>/dev/null
wait $VELOCITY_PID 2>/dev/null




# ================================
# Create Start Scripts
# ================================

echo ""
echo -e "${MAGENTA}=== Creating Start/Stop Scripts ===${NC}"

# Start All Script
cat > "$INSTALL_PATH/start_all.sh" << EOF
#!/bin/bash
#
# PiBlock Server Network - Start All Servers
#

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

echo "Starting PiBlock Server Network..."
echo ""

echo "[1/4] Starting Velocity Proxy..."
cd "\$SCRIPT_DIR/velocity"
screen -dmS velocity java --enable-native-access=ALL-UNNAMED -Xms$VELOCITY_RAM -Xmx$VELOCITY_RAM -jar velocity.jar
sleep 5

echo "[2/4] Starting Limbo Server..."
cd "\$SCRIPT_DIR/limbo"
screen -dmS limbo java --enable-native-access=ALL-UNNAMED -Xms$LIMBO_RAM -Xmx$LIMBO_RAM -jar limbo.jar --nogui
sleep 3

echo "[3/4] Starting Paper Server..."
cd "\$SCRIPT_DIR/paper"
screen -dmS paper java -Xms$PAPER_RAM -Xmx$PAPER_RAM -jar paper.jar --nogui
sleep 5

echo "[4/4] Starting GeyserMC..."
cd "\$SCRIPT_DIR/geyser"
screen -dmS geyser java --enable-native-access=ALL-UNNAMED -Xms$GEYSER_RAM -Xmx$GEYSER_RAM -jar geyser.jar

echo ""
echo "All servers started!"
echo ""
echo "Ports:"
echo "  Java Edition:    25565 (Velocity)"
echo "  Bedrock Edition: 19132 (Geyser)"
echo ""
echo "Use 'screen -r <name>' to attach to a server console."
echo "Available screens: velocity, limbo, paper, geyser"
EOF

chmod +x "$INSTALL_PATH/start_all.sh"
echo -e "  ${GREEN}Created start_all.sh${NC}"

# Stop All Script
cat > "$INSTALL_PATH/stop_all.sh" << 'EOF'
#!/bin/bash
#
# PiBlock Server Network - Stop All Servers
#

echo "Stopping PiBlock Server Network..."
echo ""

for session in velocity paper limbo geyser; do
    if screen -list | grep -q "$session"; then
        screen -S "$session" -X quit
        echo "  Stopped $session"
    fi
done

echo ""
echo "All servers stopped."
EOF

chmod +x "$INSTALL_PATH/stop_all.sh"
echo -e "  ${GREEN}Created stop_all.sh${NC}"

# ================================
# Post-Installation Notes
# ================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo ""

echo -e "${CYAN}1. START THE NETWORK:${NC}"
echo -e "   Run: ${WHITE}$INSTALL_PATH/start_all.sh${NC}"
echo ""
echo -e "${CYAN}2. PORTS:${NC}"

echo -e "   - Java Edition:    25565 (Velocity Proxy)"
echo -e "   - Bedrock Edition: 19132 (GeyserMC)"
echo ""
echo -e "${CYAN}3. START THE NETWORK:${NC}"
echo -e "   Run: ${WHITE}$INSTALL_PATH/start_all.sh${NC}"
echo ""
echo -e "${CYAN}4. SECRETS LOCATION:${NC}"
echo -e "   All secrets are stored locally in your installation folder."
echo -e "   ${YELLOW}Never share forwarding.secret or key.pem files!${NC}"
echo ""
echo -e "${CYAN}5. SCREEN SESSIONS:${NC}"
echo -e "   Use 'screen -r <name>' to attach to server consoles."
echo -e "   Available: velocity, limbo, paper, geyser"
echo ""
