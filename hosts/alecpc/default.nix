{ inputs, pkgs, config, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop.nix
    ../../modules/media.nix
    ../../modules/mcdev.nix
    ../../modules/playit.nix
  ];

  networking.hostName = "alecpc";
  home-manager.users.alec = {
    imports = [ ./hm.nix ];
    dconf.settings."org/gnome/SoundRecorder".audio-profile = "mp3";
  };

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  mcdev = {
    enable = true;
    serverDir = "/home/alec/Projects/nocturn";
    heapMB = 4096;
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ]; # Load nvidia drivers
    openssh.enable = true; # remote builds, tailnet only (borealis tailscale)
  };

  # Nvidia options --
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];

  boot = {
    kernelParams = [ "cpufreq.default_governor=performance" ]; # no cpupower + cpufreq.service
    extraModprobeConfig=''
      options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x1; PowerMizerDefault=0x1; PowerMizerDefaultAC=0x1"
    '';
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Arch64 cross compliation
  };

  hardware.nvidia = {
    powerManagement.enable = true;
    open = false; # GPU architecture is older than Turing
    nvidiaSettings = false; # gui pulls a second gtk/glib/icu stack from the cachyos pinned nixpkgs (~206M)
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580; # GTX 1050 Ti last supported package
  };
}
