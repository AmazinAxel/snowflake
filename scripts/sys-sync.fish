#!/usr/bin/env fish

set nas alec@alechomelab:/media # USB drive, rsync over ssh
read -g -P "[Sync] Enter password: " passwd --silent
echo

function s --inherit-variable passwd
    echo $passwd | sudo -S -p '' $argv
end

echo \n"[Sync] Pulling music from NAS"
if rsync -av --ignore-existing "$nas/Music/" /home/alec/Music/
    echo \n"[Sync] Syncing wallpapers with NAS"
    rsync -av --ignore-existing "$nas/Wallpapers/" /home/alec/Wallpapers/
    rsync -av --ignore-existing /home/alec/Wallpapers/ "$nas/Wallpapers/"
else
    echo \n"[Sync] NAS unreachable - skipping music and wallpapers"
end

echo \n"[Sync] Syncing passwords"
pass-sync

set sshDir /home/alec/.ssh
mkdir -p $sshDir
chmod 700 $sshDir
set keyEntries /home/alec/.password-store/ssh/*.gpg # if this is empty it wont loop
for f in $keyEntries
    set name (basename $f .gpg)
    test -e $sshDir/$name; and continue # skip if installed?
    string match -q '*.pub' $name; and set mode 644; or set mode 600 # .pub is not secret
    pass show ssh/$name | install -m $mode /dev/stdin $sshDir/$name
    and echo "[Sync] Installed ssh key $name"
end

## Rebuild latest
cd /home/alec/Projects/snowflake/
set isDirty (git status --porcelain)

if test -n "$isDirty"
    echo \n"[Sync] System flake is dirty - not updating system"
else
    git pull
    s nixos-rebuild boot --flake .
end

# Flurry
mkdir -p ~/.local/state/flurry
date +%s%3N >~/.local/state/flurry/lastSync
