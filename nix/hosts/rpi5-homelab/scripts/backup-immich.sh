#!/usr/bin/env bash
set -e

# Immich Backup Script
# Handles backup preparation and cleanup phases

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly POSTGRES_CONTAINER="immich_postgres"
readonly IMMICH_SERVER="immich_server"

# Logging functions
log_info() { echo "ℹ️  $*"; }
log_success() { echo "✅ $*"; }
log_warning() { echo "⚠️  $*"; }
log_error() { echo "❌ $*" >&2; }
log_progress() { echo "🔄 $*"; }

# Send Uptime Kuma notification
send_backup_notification() {
	local status="$1"
	local message="$2"
	
	if [ -f /etc/restic/immich-config ]; then
		BACKUP_PUSH_KEY=$(grep UPTIME_KUMA_BACKUP_PUSH_KEY /etc/restic/immich-config 2>/dev/null | cut -d= -f2 || echo "")
		if [ -n "$BACKUP_PUSH_KEY" ]; then
			timeout 30 curl -fsS -m 10 --retry 3 \
				"http://localhost:3001/api/push/$BACKUP_PUSH_KEY?status=$status&msg=$message" >/dev/null 2>&1 || true
		fi
	fi
}

# Backup preparation phase
backup_prepare() {
	log_progress "Starting backup preparation..."
	
	# Stop Immich server
	log_progress "Stopping Immich server..."
	if docker ps --format "{{.Names}}" | grep -q "^$IMMICH_SERVER$"; then
		if timeout 60 docker stop "$IMMICH_SERVER" >/dev/null 2>&1; then
			log_success "Immich server stopped"
		else
			log_error "Failed to stop Immich server"
			return 1
		fi
	else
		log_warning "Immich server not running"
	fi
	
	# Create backup directory
	log_progress "Creating backup directory..."
	mkdir -p /var/lib/immich-db-backup
	
	# Create PostgreSQL dump
	log_progress "Creating PostgreSQL dump..."
	if docker ps --format "{{.Names}}" | grep -q "^$POSTGRES_CONTAINER$"; then
		local dump_file="/var/lib/immich-db-backup/immich-$(date +%Y%m%d_%H%M%S).sql.gz"
		if timeout 600 docker exec "$POSTGRES_CONTAINER" pg_dumpall --clean --if-exists --username=postgres 2>/dev/null | gzip > "$dump_file"; then
			log_success "PostgreSQL dump created: $(basename "$dump_file")"
		else
			log_error "Failed to create PostgreSQL dump"
			# Try to restart Immich server on failure
			docker start "$IMMICH_SERVER" >/dev/null 2>&1 || true
			return 1
		fi
	else
		log_error "PostgreSQL container not running"
		return 1
	fi
	
	log_success "Backup preparation completed"
}

# Backup cleanup phase
backup_cleanup() {
	log_progress "Starting backup cleanup..."
	
	# Start Immich server
	log_progress "Starting Immich server..."
	if docker ps -a --format "{{.Names}}" | grep -q "^$IMMICH_SERVER$"; then
		if timeout 60 docker start "$IMMICH_SERVER" >/dev/null 2>&1; then
			log_success "Immich server started"
		else
			log_warning "Failed to start Immich server"
		fi
	else
		log_warning "Immich server container not found"
	fi
	
	# Send backup completion notification
	log_progress "Sending backup completion notification..."
	send_backup_notification "up" "backup-upload-complete"
	
	log_success "Backup cleanup completed"
}

# Show help
show_help() {
	cat << EOF
Immich Backup Script

Usage: $SCRIPT_NAME <PHASE>

PHASES:
  prepare    Prepare for backup (stop services, create DB dump)
  cleanup    Cleanup after backup (start services, send notifications)
  help       Show this help message

Examples:
  $SCRIPT_NAME prepare    # Run before restic backup
  $SCRIPT_NAME cleanup    # Run after restic backup
EOF
}

# Main execution
main() {
	case "${1:-}" in
		prepare)
			backup_prepare
			;;
		cleanup)
			backup_cleanup
			;;
		help|--help|-h)
			show_help
			;;
		*)
			log_error "Invalid phase: ${1:-}"
			echo "Use '$SCRIPT_NAME help' for usage information"
			exit 1
			;;
	esac
}

# Run main function with all arguments
main "$@"