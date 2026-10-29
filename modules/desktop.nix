{ pkgs, inputs, ... }: {
  imports = with inputs.borealis.nixosModules; [
    aseprite btop bun claude discord filezilla helix iotas lazygit libreoffice prismlauncher spicetify thunderbird valent vscode yazi zen
  ];

  environment.systemPackages = with pkgs; [
    cifs-utils # Needed for mounting Samba NAS drive
    rsync # Quickly pull files from NAS drive
    (writeScriptBin "sys-sync" (builtins.readFile ../scripts/sys-sync.fish))
    (writeScriptBin "homelab-update" (builtins.readFile ../scripts/homelab-update.fish))
    (writeShellScriptBin "pass-sync" ''
      pass git pull --rebase && if [ "$(pass git rev-list '@{u}..HEAD' --count)" -gt 0 ]; then pass git push; fi
    '')
  ];

  services.udev = {
    packages = [ pkgs.platformio-core.udev ];
    extraRules = ''
      # Pi Pico
      SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
      SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666"

      # WCH CH32X035
      SUBSYSTEM=="usb", ATTR{idVendor}=="4348", ATTR{idProduct}=="55e0", MODE="0666"
      SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55e0", MODE="0666"
      SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8010", MODE="0666"
      SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8012", MODE="0666"
    '';
  };
  programs.nix-ld.enable = true; # For dynamic executables
  environment.persistence."/persist".users.alec.directories = [ ".platformio" ]; # dont break builds

  home-manager.users.alec = {
    imports = [ ../home-manager/skript.nix ];
    wayland.windowManager.sway.config.input."type:touchpad".pointer_accel = "0.3";
    programs.flurry.settings.sideview.plan = "https://alechomelab.jerboa-frog.ts.net/";
  };
}
