{ inputs, pkgs, ... }: {
  imports = with inputs.borealis.nixosModules; [ bluetooth-audio flashprint kicad printing ];
  environment.systemPackages = [ pkgs.openjdk25 ];
  environment.persistence."/persist".users.alec.directories = [ ".cache/radv_builtin_shaders" ]; # amd gpu
}
