# WireGuard Toolbox

A command-line tool for managing WireGuard VPN server configurations. This tool simplifies the process of adding and removing devices, monitoring connections, and managing your WireGuard VPN server.

## Features

- Easy device management (add/remove)
- Automatic QR code generation for mobile devices
- Connection monitoring and statistics
- Service management
- Configuration backup
- Built-in security checks

## Prerequisites

Before installing this tool, make sure you have the following packages installed:

```bash
sudo apt update
sudo apt install -y wireguard qrencode curl
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/marc-alexis-com/Wireguard-Toolbox.git
```

2. Move to the installation directory:
```bash
cd Wireguard-Toolbox
```

3. Make the script executable:
```bash
chmod +x wg-admin
```

4. Install the script to your system:
```bash
sudo cp wg-admin /usr/local/sbin/
```

## Usage

Run the tool with sudo privileges:

```bash
sudo wg-admin
```

### Main Menu Options

1. **Add new device**
   - Creates a new WireGuard configuration
   - Generates QR code for mobile devices
   - Automatically assigns IP addresses
   - Updates server configuration

2. **Remove device**
   - Removes device configuration
   - Updates server configuration
   - Cleans up related settings

3. **List configured devices**
   - Shows all configured devices
   - Displays assigned IP addresses

4. **View active connections**
   - Displays currently connected devices
   - Shows connection status

5. **Usage statistics**
   - Shows data transfer statistics
   - Monitors connection usage

6. **Restart WireGuard**
   - Restarts the WireGuard service
   - Applies configuration changes

7. **Backup configurations**
   - Creates timestamped backups
   - Saves all configuration files

8. **Check service status**
   - Shows WireGuard service status
   - Displays any error messages

## Security Features

- Requires sudo privileges
- Validates all inputs
- Checks for configuration conflicts
- Securely generates encryption keys
- Creates automatic backups

## File Structure

```
/etc/wireguard/
├── wg0.conf           # Server configuration
└── devices/           # Client configurations
    ├── device1.conf
    ├── device2.conf
    └── ...
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   sudo chmod +x /usr/local/sbin/wg-admin
   ```

2. **WireGuard Service Won't Start**
   ```bash
   sudo systemctl status wg-quick@wg0
   ```

3. **QR Code Not Displaying**
   - Ensure `qrencode` is installed
   - Check terminal supports UTF-8

## Acknowledgments

- WireGuard® is a registered trademark of Jason A. Donenfeld
