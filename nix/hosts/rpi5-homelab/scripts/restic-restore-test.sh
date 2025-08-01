set -e

# Function to send Uptime Kuma notification
send_kuma_notification() {
	local status="$1"
	local message="$2"

	if [ -f /etc/restic/immich-config ]; then
		PUSH_KEY=$(grep UPTIME_KUMA_PUSH_KEY /etc/restic/immich-config | cut -d= -f2 || echo "")
		if [ -n "$PUSH_KEY" ]; then
			curl -fsS -m 10 --retry 3 "http://localhost:3001/api/push/$PUSH_KEY?status=$status&msg=$message" || true
		fi
	fi
}

# Error handler function
handle_error() {
	local exit_code=$?
	echo "❌ Restore test failed with exit code $exit_code"
	send_kuma_notification "down" "restore-test-failed"
	rm -rf "$TEMP_DIR" 2>/dev/null || true
	exit $exit_code
}

# Set up error handling
trap handle_error ERR

echo "Starting restore test..."
TEMP_DIR=$(mktemp -d)

# Load restic environment
source /etc/restic/immich-config
export RESTIC_REPOSITORY
export RESTIC_PASSWORD_FILE=/etc/restic/immich-password

# Restore only database backups (minimal bandwidth)
echo "Restoring database backup files..."
restic restore latest --target "$TEMP_DIR" --include "/var/lib/immich-db-backup"

# Validate SQL files
VALIDATED=0
echo "Validating restored SQL files..."
for sql_file in "$TEMP_DIR"/var/lib/immich-db-backup/*.sql.gz; do
	if [ -f "$sql_file" ]; then
		# Test gzip integrity
		gunzip -t "$sql_file"
		# Verify SQL structure
		gunzip -c "$sql_file" | head -100 | grep -q "CREATE TABLE"
		echo "✅ Validated: $(basename "$sql_file")"
		VALIDATED=$((VALIDATED + 1))
	fi
done

if [ $VALIDATED -eq 0 ]; then
	echo "❌ No SQL files found to validate"
	exit 1
fi

echo "✅ Restore test completed successfully ($VALIDATED files validated)"
rm -rf "$TEMP_DIR"

# Notify Uptime Kuma on successful restore test
send_kuma_notification "up" "restore-test-success"
