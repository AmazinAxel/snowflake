{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    kdePackages.kdenlive
    gnome-sound-recorder
    gnome-disk-utility
  ];
  environment.persistence."/persist".users.alec.directories = [ ".local/share/kdenlive" ];
}
