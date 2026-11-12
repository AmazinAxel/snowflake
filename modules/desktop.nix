{ pkgs, inputs, ... }: {
  imports = with inputs.borealis.nixosModules; [
    desktop # laptop.nix adds the laptop profile on top
    aseprite btop bun claude discord filezilla helix iotas lazygit libreoffice prismlauncher spicetify thunderbird tmux valent vscode yazi zen
  ];

  environment.systemPackages = with pkgs; [
    rsync # Sync files with the NAS drive over ssh
    inputs.wintergreen.packages.${pkgs.stdenv.hostPlatform.system}.books # EPUB review → WGB → homelab
    (writeScriptBin "sys-sync" (builtins.readFile ../scripts/sys-sync.fish))
    (writeScriptBin "homelab-update" (builtins.readFile ../scripts/homelab-update.fish))
    (writeScriptBin "projects-status" (builtins.readFile ../scripts/projects-status.fish))
    (writeShellScriptBin "pass-sync" ''
      pass git pull --rebase && if [ "$(pass git rev-list '@{u}..HEAD' --count)" -gt 0 ]; then pass git push; fi
    '')
  ];

  services.udev = {
    packages = [
      pkgs.platformio-core.udev
      # logged-in seat user only, not world-writable; uaccess must run before 73-seat-late
      (pkgs.writeTextDir "lib/udev/rules.d/70-dev-boards.rules" ''
        # Pi Pico
        SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", TAG+="uaccess"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", TAG+="uaccess"

        # WCH CH32X035
        SUBSYSTEM=="usb", ATTR{idVendor}=="4348", ATTR{idProduct}=="55e0", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55e0", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8010", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8012", TAG+="uaccess"
      '')
    ];
  };
  programs.nix-ld.enable = true; # For dynamic executables
  environment.persistence."/persist".users.alec.directories = [ ".platformio" ]; # dont break builds

  home-manager.users.alec = {
    imports = [ ../home-manager/skript.nix ];
    wayland.windowManager.sway.config.input."type:touchpad".pointer_accel = "0.3";
    programs.flurry.settings = {
      sideview = {
        plan = "https://alechomelab.jerboa-frog.ts.net/";
        custom = "https://beta-docs.skriptlang.org/syntaxes/";
      };
      bluetoothNames = {
        S80A = "Touchscreen Earbuds";
        MINI_KEYBOARD = "2-key Presenter";
        K38 = "Karaoke Speaker";
        MOU-302 = "Ergo Mouse";
      };
      soundNames = {
        "Ryzen HD Audio Controller Speaker" = "Speaker";
        "Ryzen HD Audio Controller Headphones" = "Headphones";
      };
      playlists = [
        { name = "Study"; color = "red"; }
        { name = "Focus"; color = "blue3"; }
        { name = "Synthwave"; color = "purple"; }
        { name = "Liked"; color = "blue4"; }
        { name = "SynthAmbient"; color = "yellow"; }
        { name = "Ambient"; color = "blue2"; }
      ];
      mpdCrossfade = 2;
      syncCommand = [ "footclient" "-e" "fish" "-c" "sys-sync; echo 'Press a key to exit'; read --nchars=1" ];
      notificationFilters = [ "Failed to connect to server" ];
    };
  };
}
