{ inputs, ... }: {
  imports = with inputs.borealis.nixosModules; [ default tailscale ];

  borealis = {
    user = "alec";
    flake = "/home/alec/Projects/snowflake";
    buildHost = "alecpc"; # nx-switch/nde/nsp build here
  };

  users.users.alec.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILNtO18H89dHbyP658hIDMeFZrjdWNUbWrdcL6URrthh alec"
    "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGqVquVZortMGAlP4kEm8Kne7Z5BmZuCbPlqK5PG8vOk alecpc-deploy" # nde from alecpc: no pty/forwarding
  ];
  nix.settings.extra-trusted-public-keys = [ "alecpc-1:od07xoidBARZvsHDGBeXrkHULX7HWZPeEqCpymOM24E=" ]; # alecpc builds, signed below
  programs.git.config = {
    github.user = "AmazinAxel"; # Github
    user.name = "AmazinAxel"; # Git
    user.email = "87440159+AmazinAxel@users.noreply.github.com";
  };
  time.timeZone = "America/Los_Angeles"; # lang also set to en_US
}
