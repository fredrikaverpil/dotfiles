{
  config,
  pkgs,
  ...
}:
let
  # Escalation, in consecutive failed checks (one per minute):
  # reconnect, then reload the brcmfmac driver, then reboot.
  reconnectAt = 2;
  reloadEvery = 5;
  rebootAt = 10;
  # Keeps a router outage from causing a tight reboot loop.
  minUptimeForReboot = 1800;

  watchdog = pkgs.writeShellApplication {
    name = "wifi-watchdog";
    runtimeInputs = [
      config.networking.networkmanager.package
      pkgs.coreutils
      pkgs.gawk
      pkgs.iproute2
      pkgs.iputils
      pkgs.kmod
      pkgs.systemd
    ];
    text = ''
      state=/run/wifi-watchdog/failures
      failures=$(cat "$state" 2>/dev/null || echo 0)

      # Look the device up by type; its name changes across systemd releases.
      dev=$(nmcli -t -f DEVICE,TYPE device | awk -F: '$2 == "wifi" { print $1; exit }' || true)
      gw=""
      if [[ -n $dev ]]; then
        gw=$(ip -4 route show default dev "$dev" | awk '{ print $3; exit }')
      fi

      if [[ -n $gw ]] && ping -q -c 3 -W 2 -I "$dev" "$gw" >/dev/null; then
        if ((failures > 0)); then
          echo "gateway $gw reachable again after $failures failed checks"
        fi
        echo 0 >"$state"
        exit 0
      fi

      failures=$((failures + 1))
      echo "$failures" >"$state"
      echo "gateway unreachable on ''${dev:-<no wifi device>} ($failures failed checks)"

      if ((failures >= ${toString rebootAt})); then
        uptime=$(cut -d. -f1 /proc/uptime)
        if ((uptime >= ${toString minUptimeForReboot})); then
          echo "rebooting"
          systemctl reboot
          exit 0
        fi
      fi

      if ((failures % ${toString reloadEvery} == 0)); then
        echo "reloading brcmfmac"
        modprobe -r brcmfmac_cyw brcmfmac || true
        sleep 2
        modprobe brcmfmac
      elif ((failures == ${toString reconnectAt})) && [[ -n $dev ]]; then
        echo "reconnecting $dev"
        nmcli device connect "$dev" || true
      fi
    '';
  };
in
{
  # The brcmfmac firmware can wedge under load: the link drops and scans fail
  # until the driver is reloaded or the Pi is rebooted.
  systemd.services.wifi-watchdog = {
    description = "Recover Wi-Fi when the gateway is unreachable";
    after = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${watchdog}/bin/wifi-watchdog";
      RuntimeDirectory = "wifi-watchdog";
      RuntimeDirectoryPreserve = true;
      # Log only escalations, not every run.
      SyslogLevel = "notice";
      LogLevelMax = "notice";
    };
  };

  systemd.timers.wifi-watchdog = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1min";
    };
  };
}
