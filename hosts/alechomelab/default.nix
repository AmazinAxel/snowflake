{ inputs, pkgs, ... }: {
  imports = [
    ./services.nix
    inputs.borealis.nixosModules.pi
  ];

  nixpkgs.overlays = [ inputs.plan.overlays.default ]; # pkgs.plan

  systemd.tmpfiles.rules = [ # webserver (runs as alec) writes only these
    "d /media/books 0775 alec users -" # wintergreen books
    "d /media/books/.read 0775 alec users -"
    "d /media/plan 0755 alec users -"
    "Z /media/plan - alec users -"
    "f /media/airQuality.db 0644 alec users -"
    "f /media/airQuality.db-journal 0644 alec users -" # kept (journal_mode TRUNCATE): /media is read-only to it
  ];

  users.extraGroups = {
    gpio = { };
    spi = { };
  };
  users.users.alec.extraGroups = [ "gpio" "spi" ];

  hardware.deviceTree = { # spi dts display
    filter = "*rpi-zero-2*.dtb";
    overlays = [{ name = "spi0"; dtsFile = ./spi0.dts; }];
  };
  boot = {
    kernelModules = [ "spidev" ];
    extraModprobeConfig = "options spidev bufsiz=65536";
  };

  # Networking
  networking = {
    hostName = "alechomelab";
    firewall.allowedTCPPorts = [ 80 ]; # webserver
    firewall.interfaces.tailscale0.allowedTCPPorts = [ 8000 ]; # permablot
  };

  services.avahi = { # need for my iot services and wintergreen!
    enable = true;
    nssmdns4 = true; # resolve permablot.local
    settings.publish = { # module defaults publish nothing
      disable-publishing = false;
      publish-addresses = true;
      disable-user-service-publishing = false;
    };
  };

  fileSystems."/media" = { # Attached USB drive
    device = "/dev/disk/by-label/AlecHomelabDrive";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  environment = {
    systemPackages = [ pkgs.rsync ]; # desktop sync
    persistence."/persist" = {
      directories = [ "/etc/homelab" ]; # Airnow token
      users.alec.files = [ "GithubToken" ]; # github backups
    };
  };

  swapDevices = [{
    device = "/media/swapfile";
    size = 1024;
    priority = 0;
    options = [ "nofail" ];
  }];
  system.stateVersion = "25.11";

  /*
  [all]
  kernel=u-boot-rpi3.bin
  arm_64bit=1
  enable_uart=1

  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
