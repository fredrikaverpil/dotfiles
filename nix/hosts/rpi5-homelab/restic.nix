{
  config,
  pkgs,
  lib,
  ...
}: {
  # Restic backup configuration for Immich
  services.restic = {
    backups = {
      immich = {
        # Dummy repository (will be overridden by RESTIC_REPOSITORY in environmentFile)
        repository = "dummy";
        # Environment file contains RESTIC_REPOSITORY and other variables
        environmentFile = "/etc/restic/immich-config";
        passwordFile = "/etc/restic/immich-password";
        paths = [
          "/mnt/homelab-data/services/immich/data/library"
          "/mnt/homelab-data/services/immich/data/upload"
          "/mnt/homelab-data/services/immich/data/profile"
          "/var/lib/immich-db-backup"
        ];
        exclude = [
          "/mnt/homelab-data/services/immich/data/thumbs"
          "/mnt/homelab-data/services/immich/data/encoded-video"
        ];
        timerConfig = {
          OnCalendar = "03:00";  # immich postgres db dump runs at 2:00 AM
          Persistent = true;
        };
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
        backupPrepareCommand = ''
          ${pkgs.docker}/bin/docker stop immich_server
          mkdir -p /var/lib/immich-db-backup
          ${pkgs.docker}/bin/docker exec immich_postgres pg_dumpall --clean --if-exists --username=postgres | ${pkgs.gzip}/bin/gzip > /var/lib/immich-db-backup/immich-$(date +%Y%m%d_%H%M%S).sql.gz
        '';
        backupCleanupCommand = ''
          ${pkgs.docker}/bin/docker start immich_server

          # Run restore test after backup completion
          echo "Running restore test to validate backup..."
          if /etc/homelab/scripts/restic-restore-test.sh; then
            echo "✅ Backup and restore test both successful"
            # Notify Uptime Kuma on complete success (backup + restore test)
            if [ -f /etc/restic/immich-config ]; then
              PUSH_KEY=$(grep UPTIME_KUMA_PUSH_KEY /etc/restic/immich-config | cut -d= -f2 || echo "")
              if [ -n "$PUSH_KEY" ]; then
                ${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 "http://localhost:3001/api/push/$PUSH_KEY?status=up&msg=backup-complete" || true
              fi
            fi
          else
            echo "❌ Backup succeeded but restore test failed"
            # Notify Uptime Kuma on partial success (backup OK, restore test failed)
            if [ -f /etc/restic/immich-config ]; then
              PUSH_KEY=$(grep UPTIME_KUMA_PUSH_KEY /etc/restic/immich-config | cut -d= -f2 || echo "")
              if [ -n "$PUSH_KEY" ]; then
                ${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 "http://localhost:3001/api/push/$PUSH_KEY?status=down&msg=backup-partial" || true
              fi
            fi
          fi
        '';
      };
    };
  };



  # Copy restore test script to system location
  environment.etc."homelab/scripts/restic-restore-test.sh" = {
    source = ./scripts/restic-restore-test.sh;
    mode = "0755";
  };
}

