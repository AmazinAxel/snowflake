# snowflake map

Alec's hosts on top of borealis (`~/Projects/borealis`). Public repo: no private info.

## Wiring
- `flake.nix`: hosts via `genAttrs` → `hosts/<host>/default.nix`; `specialArgs = { inputs }`; `nixpkgs` follows borealis.
- `hosts/common.nix`: every host; imports `borealis.nixosModules.default`, sets `borealis.{user,flake}`, ssh key, git identity, timezone.
- `modules/desktop.nix`: NAS scripts (`sys-sync`, `homelab-update`), flurry sideview plan URL. `modules/{mcdev,mcscripts,playit}.nix`.

## Hosts
- `alecslaptop`: primary laptop (borealis laptop; hm.nix = monitors, thunderbird).
- `alecolaptop`: old laptop (laptop; hm.nix = eDP scale).
- `alecpc`: desktop, nvidia (desktop + mcdev + playit).
- `alechomelab`: Pi Zero 2W (pi, services.nix, books.nix, `webserver/` bun js, `scripts/*.fish`).
- `alecdev`: Pi 4B (pi + mcdev + mcscripts, HM fish/helix only).
- `alecvps`: Proxmox LXC, `tracker/` bun service.

## Verify
`nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`; add `--no-write-lock-file --override-input borealis git+file:///home/alec/Projects/borealis` to test local borealis. New files need `git add`. Never `path:`, never rebuild.
