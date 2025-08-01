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
        backupPrepareCommand = "/etc/homelab/scripts/backup-immich.sh prepare";
        backupCleanupCommand = "/etc/homelab/scripts/backup-immich.sh cleanup";
      };
    };
  };

  # Add required packages to the restic backup service PATH
  systemd.services.restic-backups-immich.path = with pkgs; [ docker gzip curl coreutils gnugrep openssh ];

  # Separate validation service
  systemd.services.restic-validation-immich = {
    description = "Immich Backup Validation";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ docker curl gzip restic coreutils util-linux gnugrep gnused openssh ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      /etc/homelab/scripts/validate-immich.sh --validate
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

  # Copy backup and validation scripts to system location
  environment.etc."homelab/scripts/backup-immich.sh" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      ${builtins.readFile ./scripts/backup-immich.sh}
    '';
    mode = "0755";
  };

  environment.etc."homelab/scripts/validate-immich.sh" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      ${builtins.readFile ./scripts/validate-immich.sh}
    '';
    mode = "0755";
  };
}
