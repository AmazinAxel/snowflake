{ inputs, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./fingerprint.nix
    ../common.nix
    inputs.borealis.nixosModules.laptop
    ../../modules/desktop.nix
    ../../modules/bluetooth-devices.nix
  ];

  networking.hostName = "alecslaptop"; # Hostname
  home-manager.users.alec.imports = [ ./hm.nix ];

  environment.systemPackages = with pkgs; [
    gnome-sound-recorder
    gnome-disk-utility
    kdePackages.kdenlive
    maven
    orca-slicer
  ];
  programs.steam.enable = true; # Gaming
  services.pipewire.alsa.support32Bit = true; # 32-bit games

  boot.consoleLogLevel = 3; # Suppress ACPI BIOS firmware bug spam

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  environment.persistence."/persist" = {
    directories = [ "/var/lib/flatpak" ]; # Sober
    users.alec = {
      directories = [
        ".local/share/Steam" ".steam" # Steam
        ".local/share/kdenlive"
        ".config/OrcaSlicer"
      ];
      files = [ ".config/ponderosa/config.toml" ];
    };
  };

  services = {
    flatpak.enable = true; # For running Sober
    scx = { # scheduler for less active cores
      enable = true;
      package = pkgs.scx.rustscheds;
      scheduler = "scx_lavd";
      extraArgs = [ "--autopower" ];
    };
  };
}
