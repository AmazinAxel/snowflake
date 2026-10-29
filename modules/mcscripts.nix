{ pkgs, config, ... }:
let
  git = "sudo -u alec git -C ${config.mcdev.serverDir}";
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "mc-sync" ''
      set -euo pipefail

      sudo systemctl stop minecraft-server

      # stash only in case of something bad
      ${git} stash clear
      ${git} stash

      ${git} pull --rebase

      sudo systemctl start minecraft-server
    '')

    (pkgs.writeShellScriptBin "mc-stop" ''
      set -euo pipefail

      sudo systemctl stop minecraft-server

      ${git} pull --rebase || true
      ${git} add -A
      ${git} reset -q -- 'Permafrost' 'Permafrost/*' 'world' 'world/*' 'server.properties' 2>/dev/null || true

      # commit message
      if ! ${git} diff --cached --quiet; then
        date_str=$(date +%-m/%-d/%y)

        # total, added, removed, path; biggest first
        stats=$(${git} diff --cached --numstat \
          | awk -F'\t' '$1 != "-" { print $1+$2"\t"$1"\t"$2"\t"$3 }' \
          | sort -rn)

        top_files=$(head -3 <<< "$stats" | awk -F'\t' '{ n = split($4, p, "/"); printf "%s%s", (NR > 1 ? ", " : ""), p[n] }')
        description=$(awk -F'\t' '{ printf "- %s (+%s/-%s)\n", $4, $2, $3 }' <<< "$stats")

        msg="sync $date_str $top_files"

        ${git} commit -m "$msg" -m "$description"
        ${git} push
      fi

      sudo systemctl poweroff
    '')
  ];
}
