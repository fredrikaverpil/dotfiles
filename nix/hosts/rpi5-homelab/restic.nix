{
  config,
  pkgs,
  lib,
  ...
}: {
  # Restic backup configuration for Immich (backup only)
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
          OnCalendar = "03:00";
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

          # Notify Uptime Kuma on backup completion
          if [ -f /etc/restic/immich-config ]; then
            BACKUP_PUSH_KEY=$(grep UPTIME_KUMA_BACKUP_PUSH_KEY /etc/restic/immich-config | cut -d= -f2 || echo "")
            if [ -n "$BACKUP_PUSH_KEY" ]; then
              ${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 "http://localhost:3001/api/push/$BACKUP_PUSH_KEY?status=up&msg=backup-upload-complete" || true
            fi
          fi
        '';
      };
    };
  };

  # Separate validation service
  systemd.services.restic-validation-immich = {
    description = "Immich Backup Validation";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      EnvironmentFile = "/etc/restic/immich-config";
    };
    script = ''
      export RESTIC_PASSWORD_FILE=/etc/restic/immich-password
      
      echo "Starting backup validation..."
      if /etc/homelab/scripts/restic-restore-test.sh --validate; then
        echo "✅ Backup validation successful"
        # Notify Uptime Kuma on validation success
        if [ -f /etc/restic/immich-config ]; then
          VALIDATION_PUSH_KEY=$(grep UPTIME_KUMA_VALIDATION_PUSH_KEY /etc/restic/immich-config | cut -d= -f2 || echo "")
          if [ -n "$VALIDATION_PUSH_KEY" ]; then
            ${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 "http://localhost:3001/api/push/$VALIDATION_PUSH_KEY?status=up&msg=backup-validation-complete" || true
          fi
        fi
      else
        echo "❌ Backup validation failed"
        # Notify Uptime Kuma on validation failure
        if [ -f /etc/restic/immich-config ]; then
          VALIDATION_PUSH_KEY=$(grep UPTIME_KUMA_VALIDATION_PUSH_KEY /etc/restic/immich-config | cut -d= -f2 || echo "")
          if [ -n "$VALIDATION_PUSH_KEY" ]; then
            ${pkgs.curl}/bin/curl -fsS -m 10 --retry 3 "http://localhost:3001/api/push/$VALIDATION_PUSH_KEY?status=down&msg=backup-validation-failed" || true
          fi
        fi
        exit 1
      fi
    '';
  };

  # Validation timer (runs 30 minutes after backup)
  systemd.timers.restic-validation-immich = {
    description = "Timer for Immich Backup Validation";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:30";
      Persistent = true;
    };
  };

  # Copy restore test script to system location
  environment.etc."homelab/scripts/restic-restore-test.sh" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      ${builtins.readFile ./scripts/restic-restore-test.sh}
    '';
    mode = "0755";
  };
}
