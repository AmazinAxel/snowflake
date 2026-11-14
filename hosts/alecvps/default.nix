{ inputs, modulesPath, pkgs, lib, ... }:
let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICh1nH79rMAd7qEySygClFNsnGRsHRabisFZCD7nKYEz axel@amazinaxel.com";
in {
  imports = [
    inputs.borealis.nixosModules.tmux
    inputs.borealis.nixosModules.headless
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  proxmoxLXC.manageHostName = true; # keep networking.hostName
  networking.wireless.iwd.enable = false; # no wifi in a container
  zramSwap.enable = false; # cant use in proxmox
  services.tailscale.interfaceName = "userspace-networking"; # no /dev/net/tun in unprivileged LXC

  services = {
    fstrim.enable = false; # Proxmox handles this
    openssh.settings.AllowTcpForwarding = true; # VSC Remote-SSH support
  };

  users.users.alec.openssh.authorizedKeys.keys = [ key ]; # login key for fast access

  programs.nix-ld.enable = true; # for vsc

  # Nocturn player count tracker
  systemd.services.tracker = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bun}/bin/bun ${./tracker}/tracker.js";
      StateDirectory = "nocturn-tracker"; # /var/lib/nocturn-tracker
      DynamicUser = true;
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ]; # port 80 as a dynamic user
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "always";
      RestartSec = 5;
    };
  };
  # port 80 from cloudflare only: https://www.cloudflare.com/ips-v4 and ips-v6
  networking.firewall.extraInputRules = ''
    ip saddr { 173.245.48.0/20, 103.21.244.0/22, 103.22.200.0/22, 103.31.4.0/22, 141.101.64.0/18, 108.162.192.0/18, 190.93.240.0/20, 188.114.96.0/20, 197.234.240.0/22, 198.41.128.0/17, 162.158.0.0/15, 104.16.0.0/13, 104.24.0.0/14, 172.64.0.0/13, 131.0.72.0/22 } tcp dport 80 accept
    ip6 saddr { 2400:cb00::/32, 2606:4700::/32, 2803:f800::/32, 2405:b500::/32, 2405:8100::/32, 2a06:98c0::/29, 2c0f:f248::/32 } tcp dport 80 accept
  '';

  nix.settings.sandbox = false; # fix builds on the vps
  fileSystems = lib.mkForce {}; # no need for noatime
  nixpkgs.hostPlatform = "x86_64-linux";

  # Networking
  networking.hostName = "alecvps";
  systemd.network.networks."20-default".enable = false; # Proxmox has ethernet!
  system.stateVersion = "25.11";
}
