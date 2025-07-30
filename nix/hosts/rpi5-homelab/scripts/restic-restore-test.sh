#!/usr/bin/env bash
set -e

echo "Starting monthly restore test..."
TEMP_DIR=$(mktemp -d)

# Load restic environment
source /etc/restic/immich-config
export RESTIC_PASSWORD_FILE=/etc/restic/immich-password

# Restore only database backups (minimal bandwidth)
restic restore latest --target "$TEMP_DIR" --include "/var/lib/immich-db-backup"

# Validate SQL files
VALIDATED=0
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
if [ -f /etc/restic/immich-config ]; then
	PUSH_KEY=$(grep UPTIME_KUMA_PUSH_KEY /etc/restic/immich-config | cut -d= -f2 || echo "")
	if [ -n "$PUSH_KEY" ]; then
		curl -fsS -m 10 --retry 3 "http://localhost:3001/api/push/$PUSH_KEY?status=up&msg=restore-test-success" || true
	fi
fi
