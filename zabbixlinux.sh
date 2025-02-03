#!/bin/bash
# This script installs and configures Zabbix Agent 2 on Debian/Ubuntu systems
# with PSK encryption, using the following parameters:
#   - Zabbix Server: 10.4.2.24
#   - HostMetadata: LinuxVM
#   - TLSPSKIdentity: ZabbixAgentPSK
# It prompts for the PSK client secret and saves it securely.

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (or via sudo)."
  exit 1
fi

# Prompt the user for the PSK client secret (hidden input)
read -rsp "Enter PSK client secret: " PSK_SECRET < /dev/tty
echo

# Download the latest Zabbix repository package for Debian 12/Ubuntu
REPO_DEB="/tmp/zabbix-release.deb"
wget -O "$REPO_DEB" "https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest_7.0+debian12_all.deb"
if [ $? -ne 0 ]; then
  echo "Error: Failed to download the Zabbix repository package."
  exit 1
fi

# Install the repository package
dpkg -i "$REPO_DEB"
if [ $? -ne 0 ]; then
  echo "Error: Failed to install the Zabbix repository package."
  exit 1
fi

# Update package lists
apt update

# Install Zabbix Agent 2
apt install -y zabbix-agent2
if [ $? -ne 0 ]; then
  echo "Error: Failed to install zabbix-agent2."
  exit 1
fi

# (Optional) Install Zabbix Agent 2 plugins if desired
apt install -y zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql

# Define the configuration file location
CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"

# Backup the original configuration file
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# Remove any existing lines for these keys to prevent duplicates.
# (This assumes that lines you want to update start at the beginning of the line.)
sed -i '/^Server=/d' "$CONFIG_FILE"
sed -i '/^ServerActive=/d' "$CONFIG_FILE"
sed -i '/^HostMetadata=/d' "$CONFIG_FILE"
sed -i '/^TLSConnect=/d' "$CONFIG_FILE"
sed -i '/^TLSAccept=/d' "$CONFIG_FILE"
sed -i '/^TLSPSKIdentity=/d' "$CONFIG_FILE"
sed -i '/^TLSPSKFile=/d' "$CONFIG_FILE"

# Append the new configuration block
cat <<EOF >> "$CONFIG_FILE"

# --- Custom configuration added by install_zabbix_agent.sh ---
Server=10.4.2.24
ServerActive=10.4.2.24
HostMetadata=LinuxVM
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=ZabbixAgentPSK
TLSPSKFile=/etc/zabbix/zabbix_agent2.psk
EOF

# Create the PSK file with the client secret provided by the user.
echo -n "$PSK_SECRET" > /etc/zabbix/zabbix_agent2.psk
chmod 600 /etc/zabbix/zabbix_agent2.psk
chown zabbix:zabbix /etc/zabbix/zabbix_agent2.psk

# Enable the agent to start at boot and restart the service now
systemctl enable zabbix-agent2
systemctl restart zabbix-agent2

echo "Zabbix Agent 2 installation and configuration completed successfully."
