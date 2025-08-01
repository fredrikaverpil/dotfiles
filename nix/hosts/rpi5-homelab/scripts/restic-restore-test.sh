set -e

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly POSTGRES_CONTAINER="immich_postgres"
readonly IMMICH_SERVICES="immich_server immich_microservices immich_machine_learning"
readonly TIMEOUT_SECONDS=300
readonly MAX_RETRIES=3

# Global state tracking (POSIX compatible)
TEMP_DIR=""
TEMP_DB_LIST=""
BACKUP_FILE=""
SERVICES_STOPPED=""
MODE=""
SNAPSHOT="latest"

# Logging functions
log_info() { echo "ℹ️  $*"; }
log_success() { echo "✅ $*"; }
log_warning() { echo "⚠️  $*"; }
log_error() { echo "❌ $*" >&2; }
log_progress() { echo "🔄 $*"; }

# Parse command line arguments
parse_arguments() {
	while [ $# -gt 0 ]; do
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
				[ -z "$2" ] && { log_error "Snapshot ID required"; exit 1; }
				SNAPSHOT="$2"
				shift 2
				;;
			--help)
				show_help
				exit 0
				;;
			*)
				log_error "Unknown option: $1"
				echo "Use --help for usage information"
				exit 1
				;;
		esac
	done

	# Require explicit mode selection
	if [ -z "$MODE" ]; then
		log_error "You must specify either --validate or --restore"
		echo "Use --help for usage information"
		exit 1
	fi
}

show_help() {
	cat << EOF
Immich Backup Restore Script

Usage: $SCRIPT_NAME <MODE> [OPTIONS]

MODES (required):
  --validate    Test backup integrity without affecting production
  --restore     Restore backup to production database (DESTRUCTIVE)

OPTIONS:
  --snapshot ID Specify snapshot to use (default: latest)
  --help        Show this help message

Examples:
  $SCRIPT_NAME --validate                    # Test latest backup
  $SCRIPT_NAME --restore                     # Restore latest backup to production
  $SCRIPT_NAME --validate --snapshot abc123  # Test specific snapshot

SAFETY:
  - Validation mode creates temporary test databases that are automatically cleaned up
  - Restore mode backs up existing database before making changes
  - All operations include rollback capabilities on failure
EOF
}

# Uptime Kuma notification
send_kuma_notification() {
	local status="$1"
	local message="$2"
	
	if [ -f /etc/restic/immich-config ]; then
		PUSH_KEY=$(grep UPTIME_KUMA_PUSH_KEY /etc/restic/immich-config 2>/dev/null | cut -d= -f2 || echo "")
		if [ -n "$PUSH_KEY" ]; then
			timeout 30 curl -fsS -m 10 --retry 3 \
				"http://localhost:3001/api/push/$PUSH_KEY?status=$status&msg=$message" >/dev/null 2>&1 || true
		fi
	fi
}

# Container validation
validate_container() {
	local container="$1"
	local required="$2"
	
	if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
		return 0
	elif [ "$required" = "true" ]; then
		log_error "Required container '$container' not found or not running"
		return 1
	else
		log_warning "Optional container '$container' not found"
		return 1
	fi
}

# POSIX-compatible test database tracking
add_test_db() {
	local db_name="$1"
	if [ -z "$TEMP_DB_LIST" ]; then
		TEMP_DB_LIST="$db_name"
	else
		TEMP_DB_LIST="$TEMP_DB_LIST $db_name"
	fi
}

cleanup_test_databases() {
	if [ -n "$TEMP_DB_LIST" ]; then
		log_progress "Cleaning up test databases..."
		for db_name in $TEMP_DB_LIST; do
			if [ -n "$db_name" ]; then
				timeout 30 docker exec "$POSTGRES_CONTAINER" dropdb -U postgres "$db_name" 2>/dev/null || true
			fi
		done
		TEMP_DB_LIST=""
	fi
}

# Enhanced cleanup function
cleanup_all() {
	local exit_code=${1:-0}
	
	# Cleanup temporary directory
	if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
		log_progress "Cleaning up temporary directory..."
		rm -rf "$TEMP_DIR" 2>/dev/null || true
		TEMP_DIR=""
	fi
	
	# Cleanup test databases
	cleanup_test_databases
	
	# If this was a failed restore, attempt rollback
	if [ "$exit_code" -ne 0 ] && [ "$MODE" = "restore" ] && [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
		log_warning "Attempting database rollback..."
		rollback_database || log_error "Rollback failed - manual intervention required"
	fi
	
	# Restart services if they were stopped
	if [ -n "$SERVICES_STOPPED" ]; then
		log_progress "Restarting Immich services..."
		start_immich_services
	fi
}

# Error handler with comprehensive cleanup
handle_error() {
	local exit_code=$?
	log_error "Operation failed with exit code $exit_code"
	
	cleanup_all $exit_code
	
	if [ "$MODE" = "validate" ]; then
		send_kuma_notification "down" "restore-test-failed"
	fi
	
	exit $exit_code
}

# Service management
stop_immich_services() {
	log_progress "Stopping Immich services..."
	local stopped_services=""
	
	for service in $IMMICH_SERVICES; do
		if validate_container "$service" "false"; then
			log_info "Stopping $service..."
			if timeout 60 docker stop "$service" >/dev/null 2>&1; then
				stopped_services="$stopped_services $service"
			else
				log_warning "Failed to stop $service"
			fi
		fi
	done
	
	SERVICES_STOPPED="$stopped_services"
}

start_immich_services() {
	if [ -n "$SERVICES_STOPPED" ]; then
		log_progress "Starting Immich services..."
		for service in $SERVICES_STOPPED; do
			if docker ps -a --format "table {{.Names}}" | grep -q "^$service$"; then
				log_info "Starting $service..."
				timeout 60 docker start "$service" >/dev/null 2>&1 || log_warning "Failed to start $service"
			fi
		done
		SERVICES_STOPPED=""
	fi
}

# Database operations
backup_current_database() {
	local db_exists
	db_exists=$(timeout 30 docker exec "$POSTGRES_CONTAINER" psql -U postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -w immich | wc -l)
	
	if [ "$db_exists" -gt 0 ]; then
		log_progress "Backing up current database..."
		BACKUP_FILE="/tmp/immich-backup-$(date +%Y%m%d_%H%M%S).sql.gz"
		
		if timeout 600 docker exec "$POSTGRES_CONTAINER" pg_dumpall -U postgres 2>/dev/null | gzip > "$BACKUP_FILE"; then
			log_success "Current database backed up to: $BACKUP_FILE"
			return 0
		else
			log_error "Failed to backup current database"
			return 1
		fi
	else
		log_info "No existing immich database found"
		return 0
	fi
}

rollback_database() {
	if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
		log_progress "Rolling back database from backup..."
		
		# Drop current database
		timeout 30 docker exec "$POSTGRES_CONTAINER" dropdb -U postgres immich 2>/dev/null || true
		
		# Recreate and restore
		if timeout 30 docker exec "$POSTGRES_CONTAINER" createdb -U postgres immich 2>/dev/null; then
			if gunzip -c "$BACKUP_FILE" | timeout 600 docker exec -i "$POSTGRES_CONTAINER" psql -U postgres >/dev/null 2>&1; then
				log_success "Database rollback completed"
				return 0
			fi
		fi
		
		log_error "Database rollback failed"
		return 1
	else
		log_warning "No backup file available for rollback"
		return 1
	fi
}

# File operations
find_latest_sql_file() {
	local backup_dir="$1"
	local latest_file=""
	local latest_time=0
	
	# Find newest file by modification time (POSIX compatible)
	for file in "$backup_dir"/*.sql.gz; do
		if [ -f "$file" ]; then
			# Get file modification time
			file_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo 0)
			if [ "$file_time" -gt "$latest_time" ]; then
				latest_time="$file_time"
				latest_file="$file"
			fi
		fi
	done
	
	echo "$latest_file"
}

# Validation functions
validate_sql_file() {
	local sql_file="$1"
	local test_db="restic_test_$(date +%s)_$$"
	
	log_info "Testing file: $(basename "$sql_file")"
	
	# Test gzip integrity
	if ! timeout 30 gunzip -t "$sql_file" 2>/dev/null; then
		log_error "Gzip integrity check failed for $(basename "$sql_file")"
		return 1
	fi
	
	# Create test database
	if ! timeout 30 docker exec "$POSTGRES_CONTAINER" createdb -U postgres "$test_db" 2>/dev/null; then
		log_error "Failed to create test database for $(basename "$sql_file")"
		return 1
	fi
	
	add_test_db "$test_db"
	
	# Load SQL dump
	if timeout 600 gunzip -c "$sql_file" | docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$test_db" >/dev/null 2>&1; then
		# Verify tables exist
		local table_count
		table_count=$(timeout 30 docker exec "$POSTGRES_CONTAINER" psql -U postgres -d "$test_db" -t -c \
			"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo 0)
		
		if [ "$table_count" -gt 0 ]; then
			log_success "Validated: $(basename "$sql_file") ($table_count tables)"
			
			# Cleanup this test database immediately
			timeout 30 docker exec "$POSTGRES_CONTAINER" dropdb -U postgres "$test_db" 2>/dev/null || true
			return 0
		else
			log_error "No tables found in $(basename "$sql_file")"
		fi
	else
		log_error "Failed to load SQL dump: $(basename "$sql_file")"
	fi
	
	# Cleanup failed test database
	timeout 30 docker exec "$POSTGRES_CONTAINER" dropdb -U postgres "$test_db" 2>/dev/null || true
	return 1
}

# Main validation function
run_validation() {
	log_info "Starting backup validation test (snapshot: $SNAPSHOT)..."
	
	# Validate prerequisites
	validate_container "$POSTGRES_CONTAINER" "true" || return 1
	
	# Create temporary directory
	TEMP_DIR=$(mktemp -d) || { log_error "Failed to create temporary directory"; return 1; }
	
	# Restore database backup files
	log_progress "Restoring database backup files..."
	if ! timeout 1800 restic restore "$SNAPSHOT" --target "$TEMP_DIR" --include "/var/lib/immich-db-backup" 2>/dev/null; then
		log_error "Failed to restore backup files"
		return 1
	fi
	
	# Validate SQL files
	local validated=0
	local backup_dir="$TEMP_DIR/var/lib/immich-db-backup"
	
	if [ ! -d "$backup_dir" ]; then
		log_error "Backup directory not found in restored files"
		return 1
	fi
	
	log_progress "Validating restored SQL files with PostgreSQL..."
	
	for sql_file in "$backup_dir"/*.sql.gz; do
		if [ -f "$sql_file" ]; then
			if validate_sql_file "$sql_file"; then
				validated=$((validated + 1))
			fi
		fi
	done
	
	if [ $validated -eq 0 ]; then
		log_error "No SQL files successfully validated"
		return 1
	fi
	
	log_success "Backup validation completed successfully ($validated files validated)"
	send_kuma_notification "up" "restore-test-success"
	return 0
}

# Main restore function
run_restore() {
	log_warning "PRODUCTION RESTORE MODE"
	log_warning "This will REPLACE your current Immich database!"
	echo ""
	
	# Validate prerequisites
	validate_container "$POSTGRES_CONTAINER" "true" || return 1
	
	# Get confirmation
	printf "Are you absolutely sure you want to restore to production? (type 'yes' to continue): "
	read -r confirm
	if [ "$confirm" != "yes" ]; then
		log_error "Restore cancelled"
		return 1
	fi
	
	# Create temporary directory
	TEMP_DIR=$(mktemp -d) || { log_error "Failed to create temporary directory"; return 1; }
	
	# Restore database backup files
	log_progress "Restoring database backup files..."
	if ! timeout 1800 restic restore "$SNAPSHOT" --target "$TEMP_DIR" --include "/var/lib/immich-db-backup" 2>/dev/null; then
		log_error "Failed to restore backup files"
		return 1
	fi
	
	# Find latest SQL file
	local sql_file
	sql_file=$(find_latest_sql_file "$TEMP_DIR/var/lib/immich-db-backup")
	
	if [ -z "$sql_file" ] || [ ! -f "$sql_file" ]; then
		log_error "No SQL backup file found"
		return 1
	fi
	
	log_info "Using backup file: $(basename "$sql_file")"
	
	# Backup current database
	backup_current_database || return 1
	
	# Stop services
	stop_immich_services
	
	# Drop existing database
	log_progress "Dropping existing database..."
	timeout 30 docker exec "$POSTGRES_CONTAINER" dropdb -U postgres immich 2>/dev/null || true
	
	# Create fresh database
	log_progress "Creating fresh database..."
	if ! timeout 30 docker exec "$POSTGRES_CONTAINER" createdb -U postgres immich 2>/dev/null; then
		log_error "Failed to create database"
		return 1
	fi
	
	# Restore from backup
	log_progress "Restoring database from backup..."
	if timeout 1800 gunzip -c "$sql_file" | docker exec -i "$POSTGRES_CONTAINER" psql -U postgres >/dev/null 2>&1; then
		log_success "Database restore completed successfully"
	else
		log_error "Database restore failed"
		return 1
	fi
	
	# Start services
	start_immich_services
	
	log_success "Production restore completed successfully"
	return 0
}

# Main execution
main() {
	# Set up error handling
	trap handle_error ERR
	trap 'cleanup_all 0' EXIT
	
	# Parse arguments
	parse_arguments "$@"
	
	# Load restic environment
	if [ -f /etc/restic/immich-config ]; then
		# shellcheck source=/dev/null
		. /etc/restic/immich-config
		export RESTIC_REPOSITORY
		export RESTIC_PASSWORD_FILE=/etc/restic/immich-password
	else
		log_error "Restic configuration not found at /etc/restic/immich-config"
		exit 1
	fi
	
	# Execute based on mode
	case "$MODE" in
		validate)
			run_validation
			;;
		restore)
			run_restore
			;;
		*)
			log_error "Invalid mode: $MODE"
			exit 1
			;;
	esac
}

# Run main function with all arguments
main "$@"