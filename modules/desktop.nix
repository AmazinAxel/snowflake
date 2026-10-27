{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    cifs-utils # Needed for mounting Samba NAS drive
    rsync # Quickly pull files from NAS drive
    (writeScriptBin "sys-sync" (builtins.readFile ../scripts/sys-sync.fish))
    (writeScriptBin "homelab-update" (builtins.readFile ../scripts/homelab-update.fish))
  ];

  home-manager.users.alec.programs.flurry.settings.sideview.plan = "https://alechomelab.jerboa-frog.ts.net/";
}
