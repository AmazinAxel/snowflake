{ pkgs, inputs, config, ... }:

let
  service = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
  };
  # sandboxing both units share
  sandbox = {
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    PrivateTmp = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    ProtectHostname = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [ "@system-service" ];
  };
in {
  systemd = {
    services = {
      # /etc/homelab/webserver.env AIRNOW_TOKEN= AIRNOW_ZIP= and optional BOOKSYNC_TOKEN= AIRQUALITY_TOKEN=
      webserver = service // {
        environment = {
          PLAN_SERVER = "${pkgs.plan}/server.js";
          PLAN_DATA_DIR = "/media/plan";
        };
        serviceConfig = service.serviceConfig // sandbox // {
          EnvironmentFile = "/etc/homelab/webserver.env"; # read by systemd, before dropping to alec
          ExecStartPre = "+${config.systemd.package}/bin/systemd-tmpfiles --create --prefix=/media"; # nofail drive can mount after boot tmpfiles
          ExecStart = "${pkgs.bun}/bin/bun --smol ${./webserver}/webserver.js";
          MemoryMin = "32M"; # resident
          User = "alec"; # books (uploaded over ssh as alec) must stay deletable by booksync
          Group = "users";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ]; # port 80
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          ProtectHome = true;
          PrivateDevices = true;
          ProtectKernelLogs = true;
          ProtectClock = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
          SystemCallFilter = sandbox.SystemCallFilter ++ [ "~@privileged @resources" ];
          ReadWritePaths = map (p: "-/media/${p}") [ "books" "plan" "airQuality.db" "airQuality.db-journal" ]; # rest of /media read-only
        };
      };
      # root: `systemctl poweroff` needs it (no polkit), /dev/gpiochip0 and /dev/spidev0.0 are root-only
      homelabDisplay = service // {
        serviceConfig = service.serviceConfig // sandbox // {
          ExecStart = "${inputs.homelab.packages.aarch64-linux.homelabDisplay}/bin/homelabDisplay";
          MemoryMin = "8M";
          ReadWritePaths = [ "/home/alec" ]; # hold to wipe logs.txt, which may only appear after start (tmpfs home)
          RestrictAddressFamilies = [ "AF_UNIX" ]; # systemctl
          MemoryDenyWriteExecute = true;
        };
      };
      daily = {
        path = with pkgs; [ util-linux curl jq fish gitMinimal ];
        script = ''
          fish ${./scripts}/githubBackup.fish
          date +%s > /home/alec/lastSynced
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "alec";
          Group = "users";
          MemoryHigh = "190M";
          MemoryMax = "240M"; # ceiling
          MemorySwapMax = "200M"; # prefer fast zram off usb swap
          ManagedOOMMemoryPressure = "kill";
          OOMScoreAdjust = 1000;
          IOSchedulingClass = "idle";
          IOWeight = 10;
          IOReadBandwidthMax = "/media 24M";
          IOWriteBandwidthMax = "/media 10M";
          IOReadIOPSMax = "/media 1200";
          IOWriteIOPSMax = "/media 600";
          CPUWeight = 10;
          CPUQuota = "200%";
          Nice = 19;
          TimeoutStopSec = "1m";
        };
      };
    };

    # tailnet alechomelab:8000
    sockets.permablot = {
      wantedBy = [ "sockets.target" ];
      listenStreams = [ "8000" ];
    };
    services.permablot = {
      requires = [ "permablot.socket" ];
      serviceConfig = {
        ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd --exit-idle-time=1min permablot.local:80";
        DynamicUser = true;
        MemoryMax = "16M";
      };
    };

    services.sshd.serviceConfig = {
      OOMScoreAdjust = -900; # NEVER OOM SSH
      MemoryMin = "16M";
    };

    timers."daily" = { # Every morning at 3AM PT
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
        RandomizedDelaySec = "5m";
      };
    };
  };
}
