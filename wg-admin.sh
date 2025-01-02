#!/bin/bash

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check for sudo rights
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run with sudo privileges.${NC}"
    exit 1
fi

# Function to display main menu
show_menu() {
    clear
    echo -e "${BLUE}=== WireGuard Administration Tool ===${NC}\n"
    echo -e "${GREEN}1.${NC} Add new device"
    echo -e "${GREEN}2.${NC} Remove device"
    echo -e "${GREEN}3.${NC} List configured devices"
    echo -e "${GREEN}4.${NC} View active connections"
    echo -e "${GREEN}5.${NC} Usage statistics"
    echo -e "${GREEN}6.${NC} Restart WireGuard"
    echo -e "${GREEN}7.${NC} Backup configurations"
    echo -e "${GREEN}8.${NC} Check service status"
    echo -e "${GREEN}0.${NC} Exit"
    echo -e "\n${YELLOW}Choose an option:${NC}"
}

# Function to add a new device
add_device() {
    echo -e "\n${BLUE}=== Adding a new device ===${NC}"
    read -p "Device name: " DEVICE_NAME
    
    # Check if name is already in use
    if [ -f "/etc/wireguard/${DEVICE_NAME}.conf" ]; then
        echo -e "${RED}A device with this name already exists!${NC}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    # Find last used IP
    LAST_IP=$(grep -h "Address" /etc/wireguard/wg0.conf /etc/wireguard/*.conf 2>/dev/null |
    grep -o "10\.0\.0\.[0-9]*" | sort -t. -k4 -n | tail -n1 | cut -d. -f4)
    NEXT_IP=$((LAST_IP + 1))
    
    # Key generation
    PRIVATE_KEY=$(wg genkey)
    PUBLIC_KEY=$(echo $PRIVATE_KEY | wg pubkey)
    SERVER_PUBLIC_KEY=$(wg show wg0 public-key)
    SERVER_IP=$(curl -s -4 ifconfig.me)
    
    # Create client configuration
    cat > "/etc/wireguard/${DEVICE_NAME}.conf" << EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = 10.0.0.$NEXT_IP/32
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
    
    # Add peer to server configuration
    echo -e "\n[Peer]\nPublicKey = $PUBLIC_KEY\nAllowedIPs = 10.0.0.$NEXT_IP/32" >> /etc/wireguard/wg0.conf
    
    # Restart service
    systemctl restart wg-quick@wg0
    
    # Display QR code
    echo -e "\n${GREEN}Configuration generated! Here's the QR code:${NC}\n"
    qrencode -t ansiutf8 -r "/etc/wireguard/${DEVICE_NAME}.conf"
    
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s -r
}

# Function to remove a device
remove_device() {
    echo -e "\n${BLUE}=== Removing a device ===${NC}"
    
    # List available devices
    echo -e "\nConfigured devices:"
    DEVICES=$(ls /etc/wireguard/*.conf | grep -v 'wg0.conf' | sed 's/.*\///' | sed 's/\.conf//')
    
    if [ -z "$DEVICES" ]; then
        echo -e "${RED}No devices configured!${NC}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    echo "$DEVICES"
    echo -e "\n${YELLOW}Enter the name of the device to remove:${NC}"
    read DEVICE_NAME
    
    if [ ! -f "/etc/wireguard/${DEVICE_NAME}.conf" ]; then
        echo -e "${RED}This device doesn't exist!${NC}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    # Get device's public key
    PUBLIC_KEY=$(grep "PublicKey" "/etc/wireguard/${DEVICE_NAME}.conf" | cut -d " " -f 3)
    
    # Remove device configuration
    rm "/etc/wireguard/${DEVICE_NAME}.conf"
    
    # Remove peer from server configuration
    sed -i "/\[Peer\]/,/AllowedIPs.*${PUBLIC_KEY}/d" /etc/wireguard/wg0.conf
    
    # Restart service
    systemctl restart wg-quick@wg0
    
    echo -e "\n${GREEN}Device successfully removed!${NC}"
    read -n 1 -s -r -p "Press any key to continue..."
}

# Function to list configured devices
list_devices() {
    echo -e "\n${BLUE}=== List of configured devices ===${NC}\n"
    
    echo -e "${YELLOW}Devices:${NC}"
    for conf in /etc/wireguard/*.conf; do
        if [ "$conf" != "/etc/wireguard/wg0.conf" ]; then
            DEVICE_NAME=$(basename "$conf" .conf)
            IP=$(grep "Address" "$conf" | cut -d " " -f 3)
            echo -e "${GREEN}$DEVICE_NAME${NC} - IP: $IP"
        fi
    done
    
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s -r
}

# Function to show active connections
show_active_connections() {
    echo -e "\n${BLUE}=== Active connections ===${NC}\n"
    wg show all
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s -r
}

# Function to display statistics
show_stats() {
    echo -e "\n${BLUE}=== Usage statistics ===${NC}\n"
    
    echo -e "${YELLOW}Traffic by device:${NC}"
    wg show all transfer
    
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s -r
}

# Function to restart WireGuard
restart_wireguard() {
    echo -e "\n${BLUE}=== Restarting WireGuard ===${NC}"
    systemctl restart wg-quick@wg0
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}WireGuard successfully restarted!${NC}"
    else
        echo -e "\n${RED}Error restarting WireGuard!${NC}"
    fi
    read -n 1 -s -r -p "Press any key to continue..."
}

# Function to backup configurations
backup_configs() {
    BACKUP_DIR="/root/wireguard_backup_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "\n${BLUE}=== Backing up configurations ===${NC}"
    mkdir -p "$BACKUP_DIR"
    cp /etc/wireguard/*.conf "$BACKUP_DIR/"
    
    echo -e "\n${GREEN}Configurations backed up to: $BACKUP_DIR${NC}"
    read -n 1 -s -r -p "Press any key to continue..."
}

# Function to check service status
check_service_status() {
    echo -e "\n${BLUE}=== WireGuard Service Status ===${NC}\n"
    systemctl status wg-quick@wg0
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s -r
}

# Main loop
while true; do
    show_menu
    read -r opt
    case $opt in
        1) add_device ;;
        2) remove_device ;;
        3) list_devices ;;
        4) show_active_connections ;;
        5) show_stats ;;
        6) restart_wireguard ;;
        7) backup_configs ;;
        8) check_service_status ;;
        0) echo -e "\n${GREEN}Goodbye!${NC}"; exit 0 ;;
        *) echo -e "\n${RED}Invalid option!${NC}"; sleep 2 ;;
    esac
done
