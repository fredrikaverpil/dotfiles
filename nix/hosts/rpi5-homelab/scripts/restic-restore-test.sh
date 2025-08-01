set -e

# Parse command line arguments
MODE=""
SNAPSHOT="latest"

while [[ $# -gt 0 ]]; do
	case $1 in
		--validate)
			MODE="validate"
			shift
			;;
		--restore)
			MODE="restore"
			shift
			;;
		--snapshot)
			SNAPSHOT="$2"
			shift 2
			;;
		--help)
			echo "Immich Backup Restore Script"
			echo ""
			echo "Usage: $0 <MODE> [OPTIONS]"
			echo ""
			echo "MODES (required):"
			echo "  --validate    Test backup integrity without affecting production"
			echo "  --restore     Restore backup to production database (DESTRUCTIVE)"
			echo ""
			echo "OPTIONS:"
			echo "  --snapshot ID Specify snapshot to use (default: latest)"
			echo "  --help        Show this help message"
			echo ""
			echo "Examples:"
			echo "  $0 --validate                    # Test latest backup"
			echo "  $0 --restore                     # Restore latest backup to production"
			echo "  $0 --validate --snapshot abc123  # Test specific snapshot"
			exit 0
			;;
		*)
			echo "❌ Unknown option: $1"
			echo "Use --help for usage information"
			exit 1
			;;
	esac
done

# Require explicit mode selection
if [ -z "$MODE" ]; then
	echo "❌ Error: You must specify either --validate or --restore"
	echo "Use --help for usage information"
	exit 1
fi

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

# Global cleanup variables
TEMP_DIR=""
TEST_DBS=()

# Enhanced error handler function
handle_error() {
	local exit_code=$?
	echo "❌ Operation failed with exit code $exit_code"
	
	# Cleanup temporary directory
	if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
		rm -rf "$TEMP_DIR" 2>/dev/null || true
	fi
	
	# Cleanup test databases
	for test_db in "${TEST_DBS[@]}"; do
		if [ -n "$test_db" ]; then
			docker exec immich_postgres dropdb -U postgres "$test_db" 2>/dev/null || true
		fi
	done
	
	if [ "$MODE" = "validate" ]; then
		send_kuma_notification "down" "restore-test-failed"
	fi
	
	exit $exit_code
}

# Set up error handling
trap handle_error ERR

# Load restic environment
source /etc/restic/immich-config
export RESTIC_REPOSITORY
export RESTIC_PASSWORD_FILE=/etc/restic/immich-password

if [ "$MODE" = "validate" ]; then
	echo "🧪 Starting backup validation test..."
	TEMP_DIR=$(mktemp -d)
	
	# Restore only database backups (minimal bandwidth)
	echo "Restoring database backup files..."
	restic restore "$SNAPSHOT" --target "$TEMP_DIR" --include "/var/lib/immich-db-backup"
	
	# Validate SQL files by loading into PostgreSQL
	VALIDATED=0
	echo "Validating restored SQL files with PostgreSQL..."
	
	for sql_file in "$TEMP_DIR"/var/lib/immich-db-backup/*.sql.gz; do
		if [ -f "$sql_file" ]; then
			echo "Testing file: $(basename "$sql_file")"
			
			# Create unique test database name
			TEST_DB="restic_test_$(date +%s)_$$"
			TEST_DBS+=("$TEST_DB")
			
			# Test gzip integrity first
			if ! gunzip -t "$sql_file"; then
				echo "❌ Gzip integrity check failed for $(basename "$sql_file")"
				continue
			fi
			
			# Create temporary database
			if ! docker exec immich_postgres createdb -U postgres "$TEST_DB"; then
				echo "❌ Failed to create test database for $(basename "$sql_file")"
				continue
			fi
			
			# Load SQL dump into test database
			if gunzip -c "$sql_file" | docker exec -i immich_postgres psql -U postgres -d "$TEST_DB" >/dev/null 2>&1; then
				# Verify essential Immich tables exist
				TABLE_COUNT=$(docker exec immich_postgres psql -U postgres -d "$TEST_DB" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
				
				if [ "$TABLE_COUNT" -gt 0 ]; then
					echo "✅ Validated: $(basename "$sql_file") ($TABLE_COUNT tables)"
					VALIDATED=$((VALIDATED + 1))
				else
					echo "❌ No tables found in $(basename "$sql_file")"
				fi
			else
				echo "❌ Failed to load SQL dump: $(basename "$sql_file")"
			fi
			
			# Cleanup test database
			docker exec immich_postgres dropdb -U postgres "$TEST_DB" 2>/dev/null || true
		fi
	done
	
	if [ $VALIDATED -eq 0 ]; then
		echo "❌ No SQL files successfully validated"
		exit 1
	fi
	
	echo "✅ Backup validation completed successfully ($VALIDATED files validated)"
	rm -rf "$TEMP_DIR"
	
	# Notify Uptime Kuma on successful validation
	send_kuma_notification "up" "restore-test-success"

elif [ "$MODE" = "restore" ]; then
	echo "⚠️  PRODUCTION RESTORE MODE"
	echo "This will REPLACE your current Immich database!"
	echo ""
	
	# Check if PostgreSQL container exists and is running
	if ! docker ps | grep -q immich_postgres; then
		echo "❌ immich_postgres container not found or not running"
		exit 1
	fi
	
	# Get confirmation
	read -p "Are you absolutely sure you want to restore to production? (type 'yes' to continue): " confirm
	if [ "$confirm" != "yes" ]; then
		echo "❌ Restore cancelled"
		exit 1
	fi
	
	TEMP_DIR=$(mktemp -d)
	
	# Restore database backup files
	echo "📦 Restoring database backup files..."
	restic restore "$SNAPSHOT" --target "$TEMP_DIR" --include "/var/lib/immich-db-backup"
	
	# Find the most recent SQL file
	SQL_FILE=$(find "$TEMP_DIR"/var/lib/immich-db-backup -name "*.sql.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
	
	if [ -z "$SQL_FILE" ] || [ ! -f "$SQL_FILE" ]; then
		echo "❌ No SQL backup file found"
		exit 1
	fi
	
	echo "📄 Using backup file: $(basename "$SQL_FILE")"
	
	# Check if immich database exists and back it up
	DB_EXISTS=$(docker exec immich_postgres psql -U postgres -lqt | cut -d \| -f 1 | grep -w immich | wc -l)
	
	if [ "$DB_EXISTS" -gt 0 ]; then
		echo "💾 Backing up current database..."
		BACKUP_FILE="/tmp/immich-backup-$(date +%Y%m%d_%H%M%S).sql.gz"
		docker exec immich_postgres pg_dumpall -U postgres | gzip > "$BACKUP_FILE"
		echo "✅ Current database backed up to: $BACKUP_FILE"
	else
		echo "ℹ️  No existing immich database found"
	fi
	
	# Stop Immich services
	echo "🛑 Stopping Immich services..."
	for service in immich_server immich_microservices immich_machine_learning; do
		if docker ps | grep -q "$service"; then
			echo "  Stopping $service..."
			docker stop "$service"
		fi
	done
	
	# Drop and recreate database
	if [ "$DB_EXISTS" -gt 0 ]; then
		echo "🗑️  Dropping existing database..."
		docker exec immich_postgres dropdb -U postgres immich
	fi
	
	echo "🏗️  Creating fresh database..."
	docker exec immich_postgres createdb -U postgres immich
	
	# Restore from backup
	echo "🔄 Restoring database from backup..."
	if gunzip -c "$SQL_FILE" | docker exec -i immich_postgres psql -U postgres >/dev/null; then
		echo "✅ Database restore completed successfully"
	else
		echo "❌ Database restore failed"
		exit 1
	fi
	
	# Start services
	echo "🚀 Starting Immich services..."
	for service in immich_server immich_microservices immich_machine_learning; do
		if docker ps -a | grep -q "$service"; then
			echo "  Starting $service..."
			docker start "$service"
		fi
	done
	
	echo "✅ Production restore completed successfully"
	rm -rf "$TEMP_DIR"
fi