# snowflake map

Alec's hosts on top of borealis (`~/Projects/borealis`). Public repo: no private info.

## Wiring
- `flake.nix`: hosts via `genAttrs` → `hosts/common.nix` + `hosts/<host>/default.nix`; `specialArgs = { inputs }`; `nixpkgs` follows borealis.
- `hosts/common.nix`: every host (added in flake.nix, never imported); imports `borealis.nixosModules.default`, sets `borealis.{user,flake,buildHost}`, ssh key, git identity, timezone.
- `modules/desktop.nix`: borealis desktop profile + apps + tmux, NAS scripts (`sys-sync`, `homelab-update`; rsync over ssh to `alechomelab:/media`), flurry sideview plan URL. `modules/laptop.nix`: desktop.nix + borealis laptop profile + laptop apps. `modules/media.nix`: kdenlive etc (alecpc, alecslaptop). `modules/{mcdev,mcscripts,playit}.nix`.
- Deploy: `nde <host> [switch|boot]` (borealis fish function), builds on alecpc. Headless hosts get `borealis.nixosModules.headless` (pi includes it); keep their closures free of local/emulated builds.

## Hosts
- `alecslaptop`: primary laptop (borealis laptop; hm.nix = monitors, thunderbird).
- `alecolaptop`: old laptop (laptop; hm.nix = eDP scale).
- `alecpc`: desktop, nvidia (desktop + mcdev + playit).
- `alechomelab`: Pi Zero 2W (pi, services.nix, books.nix, `webserver/` bun js, `scripts/*.fish`).
- `alecdev`: Pi 4B (pi + mcdev + mcscripts, HM fish/helix only).
- `alecvps`: Proxmox LXC, `tracker/` bun service.
- `alechandheld`: Anbernic (arm + anbernix).

## Verify
`nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`; add `--no-write-lock-file --override-input borealis git+file:///home/alec/Projects/borealis` to test local borealis. New files need `git add`. Never `path:`, never rebuild.
