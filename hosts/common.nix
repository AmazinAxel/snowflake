{ inputs, ... }: {
  imports = with inputs.borealis.nixosModules; [ default tailscale ];

  borealis = {
    user = "alec";
    flake = "/home/alec/Projects/snowflake";
    buildHost = "alecpc"; # nde: binfmt aarch64 + fastest builds
  };

  users.users.alec.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNtO18H89dHbyP658hIDMeFZrjdWNUbWrdcL6URrthh alec" ];
  programs.git.config = {
    github.user = "AmazinAxel"; # Github
    user.name = "AmazinAxel"; # Git
    user.email = "87440159+AmazinAxel@users.noreply.github.com";
  };
  time.timeZone = "America/Los_Angeles"; # lang also set to en_US
}
