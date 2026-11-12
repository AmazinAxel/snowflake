{ inputs, lib, config, ... }: {
  imports = [
    ../../modules/mcscripts.nix
    inputs.borealis.nixosModules.pi
    inputs.borealis.nixosModules.helix
    inputs.borealis.nixosModules.tmux
    ../../modules/mcdev.nix
  ];

  programs.fish.shellAliases.pf = "hx ${config.mcdev.serverDir}/plugins/Skript/scripts";

  home-manager.users.alec = {
    imports = [ ../../home-manager/skript.nix ];
    programs.helix.extraPackages = lib.mkForce [ ]; # no web/markdown LSPs (node, dotnet, harper)
  };

  mcdev = {
    enable = true;
    serverDir = "/var/lib/minecraft";
    heapMB = 2048;
  };

  environment.persistence."/persist".directories = [ config.mcdev.serverDir ];
  boot.kernelParams = [ "cpufreq.default_governor=performance" ]; # better performance, no cpupower + cpufreq.service

  # Networking
  networking.hostName = "alecdev";
  system.stateVersion = "26.05";


  /*
  [all]
  # Pi 4
  kernel=u-boot-rpi4.bin
  enable_gic=1
  armstub=armstub8-gic.bin
  arm_boost=1

  # For proper boot
  arm_64bit=1
  enable_uart=1

  # Disable hdmi output
  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2

  # Faster boot
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
