#!/usr/bin/env bash
set -e

echo "=== Immich Restic Backup Setup ==="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
	echo "Run as regular user (not root)"
	exit 1
fi

# Check if restic service exists
if ! systemctl list-unit-files | grep -q "restic-backups-immich.service"; then
	echo "Restic service not found. Deploy NixOS config first: nixos-rebuild switch"
	exit 1
fi

echo "Creating directories..."
sudo mkdir -p /etc/restic
sudo mkdir -p /var/lib/immich-db-backup

echo "Enter restic repository password (encrypts backups):"
echo -n "Password: "
read -s RESTIC_PASSWORD
echo
echo -n "Confirm: "
read -s RESTIC_PASSWORD_CONFIRM
echo

if [[ "$RESTIC_PASSWORD" != "$RESTIC_PASSWORD_CONFIRM" ]]; then
	echo "Passwords don't match"
	exit 1
fi

if [[ ${#RESTIC_PASSWORD} -lt 8 ]]; then
	echo "Password must be at least 8 characters"
	exit 1
fi

echo "$RESTIC_PASSWORD" | sudo tee /etc/restic/immich-password >/dev/null

echo "Enter Hetzner Storage Box details:"
echo -n "Username (e.g., u123456): "
read HETZNER_USERNAME
echo -n "Hostname (e.g., u123456.your-storagebox.de): "
read HETZNER_HOSTNAME
echo -n "SSH port (usually 23): "
read HETZNER_PORT
echo -n "Backup path (e.g., /home/backups/immich): "
read BACKUP_PATH

# Optional: Uptime Kuma monitoring
echo
echo "=== Uptime Kuma Integration ==="
echo "Create two push monitors in Uptime Kuma:"
echo "1. 'Immich Backup Upload' - tracks backup uploads to Hetzner"
echo "2. 'Immich Backup Validation' - tracks backup integrity validation"
echo ""
echo "Enter push keys from Uptime Kuma (leave empty to skip):"
echo -n "Backup job monitor push key: "
read UPTIME_KUMA_BACKUP_PUSH_KEY
echo -n "Validation/restore job monitor push key: "
read UPTIME_KUMA_VALIDATION_PUSH_KEY

# Create config file with repository URL and optional Uptime Kuma keys
cat <<EOF | sudo tee /etc/restic/immich-config >/dev/null
RESTIC_REPOSITORY=sftp://${HETZNER_USERNAME}@${HETZNER_HOSTNAME}:${HETZNER_PORT}${BACKUP_PATH}
EOF

# Add Uptime Kuma keys if provided
if [ -n "$UPTIME_KUMA_BACKUP_PUSH_KEY" ]; then
	echo "UPTIME_KUMA_BACKUP_PUSH_KEY=${UPTIME_KUMA_BACKUP_PUSH_KEY}" | sudo tee -a /etc/restic/immich-config >/dev/null
fi

if [ -n "$UPTIME_KUMA_VALIDATION_PUSH_KEY" ]; then
	echo "UPTIME_KUMA_VALIDATION_PUSH_KEY=${UPTIME_KUMA_VALIDATION_PUSH_KEY}" | sudo tee -a /etc/restic/immich-config >/dev/null
fi

echo "Setting permissions..."
sudo chmod 755 /etc/restic
sudo chown root:root /etc/restic
sudo chmod 600 /etc/restic/immich-password
sudo chmod 644 /etc/restic/immich-config
sudo chown root:root /etc/restic/immich-password
sudo chown root:root /etc/restic/immich-config

echo "Setting up SSH keys for passwordless authentication..."
# Ensure root has .ssh directory
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh

# Copy user's SSH keys to root (needed for automated backups)
if [ -f ~/.ssh/id_ed25519 ]; then
	echo "Copying SSH keys to root..."
	sudo cp ~/.ssh/id_ed25519 /root/.ssh/
	sudo cp ~/.ssh/id_ed25519.pub /root/.ssh/
	sudo chown root:root /root/.ssh/id_ed25519
	sudo chown root:root /root/.ssh/id_ed25519.pub
	sudo chmod 600 /root/.ssh/id_ed25519
	sudo chmod 644 /root/.ssh/id_ed25519.pub
else
	echo "WARNING: No SSH key found at ~/.ssh/id_ed25519"
	echo "You may need to generate one or copy your existing key to /root/.ssh/"
	echo "Use the following command to generate a new key:"
	echo "ssh-keygen -t ed25519 -C \"fredrik@rpi5-homelab\""
fi

echo
echo "✅ Setup complete"
