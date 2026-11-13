{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./fingerprint.nix
    ../../modules/laptop.nix
    ../../modules/media.nix
  ];

  networking.hostName = "alecslaptop"; # Hostname
  home-manager.users.alec.imports = [ ./hm.nix ];

  environment.systemPackages = with pkgs; [
    maven
    orca-slicer
  ];
  programs.steam.enable = true; # Gaming

  # Vulkan renderer: needed for sway color_profile (flurry focus grayscale). Not in sway's
  # extraSessionCommands: those wrap the sway binary, so its sandboxed config check fails.
  environment.sessionVariables.WLR_RENDERER = "vulkan";

  boot.consoleLogLevel = 3; # Suppress ACPI BIOS firmware bug spam

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  environment.persistence."/persist" = {
    directories = [ "/var/lib/flatpak" ]; # Sober
    users.alec = {
      directories = [
        ".local/share/Steam" ".steam" # Steam
        ".config/OrcaSlicer"
      ];
      files = [ ".config/ponderosa/config.toml" ];
    };
  };

  services = {
    pipewire.alsa.support32Bit = true; # 32-bit games
    # rtorrent.enable = true;
    flatpak.enable = true; # For running Sober
    scx-loader.config.scheds.scx_lavd.auto_mode = [ "--autopower" ]; # scheduler for less active cores
  };
}
