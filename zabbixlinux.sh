#!/bin/bash
set -e

# Variables
ZABBIX_AGENT_URL="https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.9/zabbix_agent-7.0.9-linux-3.0-amd64-static.tar.gz"
TMP_DIR="/tmp/zabbix_agent_install"
DOWNLOAD_FILE="/tmp/zabbix_agent.tar.gz"
INSTALL_BIN_DIR="/usr/local/sbin"
CONFIG_DIR="/etc/zabbix"
AGENT_CONFIG="${CONFIG_DIR}/zabbix_agentd.conf"
PSK_FILE="${CONFIG_DIR}/zabbix_agentd.psk"
SYSTEMD_SERVICE="/etc/systemd/system/zabbix-agent.service"

echo "Downloading Zabbix Agent from ${ZABBIX_AGENT_URL}..."
wget -O "${DOWNLOAD_FILE}" "${ZABBIX_AGENT_URL}"

echo "Creating temporary directory ${TMP_DIR} for extraction..."
mkdir -p "${TMP_DIR}"

echo "Extracting the Zabbix Agent package..."
tar -xzf "${DOWNLOAD_FILE}" -C "${TMP_DIR}"

# Find the zabbix_agentd binary in the extracted files.
ZABBIX_AGENT_BIN=$(find "${TMP_DIR}" -type f -name "zabbix_agentd" | head -n 1)
if [ -z "${ZABBIX_AGENT_BIN}" ]; then
  echo "Error: zabbix_agentd binary not found in the extracted package."
  exit 1
fi

echo "Installing zabbix_agentd to ${INSTALL_BIN_DIR}..."
cp "${ZABBIX_AGENT_BIN}" "${INSTALL_BIN_DIR}/"
chmod +x "${INSTALL_BIN_DIR}/zabbix_agentd"

echo "Ensuring configuration directory ${CONFIG_DIR} exists..."
mkdir -p "${CONFIG_DIR}"

# Prompt the user to input the PSK (in hexadecimal format)
echo "Please enter your PSK (in hexadecimal format) for the Zabbix Agent:"
read -sp "PSK: " USER_PSK
echo ""
if [ -z "${USER_PSK}" ]; then
  echo "No PSK provided. Exiting."
  exit 1
fi

echo "Creating PSK file at ${PSK_FILE}..."
echo "${USER_PSK}" > "${PSK_FILE}"
chmod 400 "${PSK_FILE}"

echo "Creating Zabbix Agent configuration file at ${AGENT_CONFIG}..."
cat > "${AGENT_CONFIG}" <<EOF
### Zabbix Agent Configuration

# Log settings
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0

# Zabbix server settings
Server=10.4.2.24
ServerActive=10.4.2.24
HostnameItem=system.hostname

# Host metadata for auto-registration or grouping
HostMetadata=LinuxVM

# TLS/PSK settings for secure communication
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=ZabbixAgentPSK
TLSPSKFile=${PSK_FILE}
EOF

echo "Creating systemd service file at ${SYSTEMD_SERVICE}..."
cat > "${SYSTEMD_SERVICE}" <<EOF
[Unit]
Description=Zabbix Agent
After=network.target

[Service]
Type=simple
ExecStart=${INSTALL_BIN_DIR}/zabbix_agentd -c ${AGENT_CONFIG}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon and enabling the Zabbix Agent service..."
systemctl daemon-reload
systemctl enable zabbix-agent
systemctl restart zabbix-agent

echo "Cleaning up temporary files..."
rm -rf "${TMP_DIR}" "${DOWNLOAD_FILE}"

echo "Zabbix Agent installation complete."
