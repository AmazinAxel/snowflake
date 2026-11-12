{ inputs, pkgs, ... }: {
  imports = with inputs.borealis.nixosModules; [
    laptop bluetooth-audio flashprint kicad printing
    ./desktop.nix
    ./bluetooth-devices.nix
  ];
  environment.systemPackages = [ pkgs.openjdk25 ];
  environment.persistence."/persist".users.alec.directories = [ ".cache/radv_builtin_shaders" ]; # amd gpu
}
