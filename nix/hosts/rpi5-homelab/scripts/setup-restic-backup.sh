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
echo -n "Backup path (e.g., /backups/immich): "
read BACKUP_PATH

# Optional: Uptime Kuma monitoring
echo
echo "Optional: Uptime Kuma monitoring"
echo "Enter push key from Uptime Kuma (leave empty to skip):"
echo -n "Push key: "
read UPTIME_KUMA_PUSH_KEY

# Create config file with repository URL and optional Uptime Kuma key
cat <<EOF | sudo tee /etc/restic/immich-config >/dev/null
RESTIC_REPOSITORY=sftp:${HETZNER_USERNAME}@${HETZNER_HOSTNAME}:${HETZNER_PORT}${BACKUP_PATH}
EOF

# Add Uptime Kuma key if provided
if [ -n "$UPTIME_KUMA_PUSH_KEY" ]; then
	echo "UPTIME_KUMA_PUSH_KEY=${UPTIME_KUMA_PUSH_KEY}" | sudo tee -a /etc/restic/immich-config >/dev/null
fi

echo "Setting permissions..."
sudo chmod 600 /etc/restic/immich-password
sudo chmod 600 /etc/restic/immich-config
sudo chown root:root /etc/restic/immich-password
sudo chown root:root /etc/restic/immich-config

echo
echo "✅ Setup complete"
echo
echo "Next steps:"
echo "1. Initialize repository: sudo systemctl start restic-backups-immich-init.service"
echo "2. Check status: sudo systemctl status restic-backups-immich-init.service"
echo "3. Test backup: sudo systemctl start restic-backups-immich.service"
echo "4. Test restore: sudo systemctl start restic-restore-test.service"
echo "5. View logs: sudo journalctl -u restic-backups-immich.service -f"
echo
echo "Store the password safely - required for restore"
echo "Daily backups run at 02:00 AM"
echo "Monthly restore tests run automatically"
