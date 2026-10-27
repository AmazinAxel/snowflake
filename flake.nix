{
  inputs = {
    borealis.url = "github:AmazinAxel/borealis";
    nixpkgs.follows = "borealis/nixpkgs";
    playit = {
      url = "github:pedorich-n/playit-nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # my programs
    homelab = {
      url = "github:AmazinAxel/homelab";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wintergreen = {
      url = "github:AmazinAxel/wintergreen";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plan.url = "github:AmazinAxel/plan";
  };

  outputs = { nixpkgs, ... }@inputs: {
    # headless devices
    # nixos-rebuild switch --flake .#<hostname> --sudo --ask-sudo-password --build-host alec@alecpc --target-host alec@<hostname>
    nixosConfigurations = nixpkgs.lib.genAttrs [
      "alecslaptop" # Primary laptop
      "alecolaptop" # Old laptop
      "alecpc" # Desktop/compute server
      "alechomelab" # Homelab (Zero 2W)
      "alecdev" # Pi 4B dev server
      "alecvps" # VPS
    ] (host: nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ ./hosts/${host}/default.nix ];
    });
  };
}
