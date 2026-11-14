#!/usr/bin/env fish

source (dirname (status filename))/logging.fish

# Check whether drive is mounted
if not mountpoint -q /media
    log "GH: no drive"
    exit 1
end

mkdir -p /media/Projects
read token </home/alec/GithubToken
set -x GIT_CONFIG_COUNT 10
set -x GIT_CONFIG_KEY_0 safe.directory
set -x GIT_CONFIG_VALUE_0 '*'

# token in env, not argv (env is owner-only in /proc)
set -x GIT_CONFIG_KEY_9 http.https://github.com/.extraHeader
set -x GIT_CONFIG_VALUE_9 "Authorization: Basic "(echo -n "AmazinAxel:$token" | base64 -w0)

# reduce mem usage
set -x GIT_CONFIG_KEY_1 pack.threads
set -x GIT_CONFIG_VALUE_1 1
set -x GIT_CONFIG_KEY_2 index.threads
set -x GIT_CONFIG_VALUE_2 1
set -x GIT_CONFIG_KEY_3 pack.windowMemory
set -x GIT_CONFIG_VALUE_3 32m
set -x GIT_CONFIG_KEY_4 pack.deltaCacheSize
set -x GIT_CONFIG_VALUE_4 16m
set -x GIT_CONFIG_KEY_5 core.packedGitLimit
set -x GIT_CONFIG_VALUE_5 64m
set -x GIT_CONFIG_KEY_6 core.packedGitWindowSize
set -x GIT_CONFIG_VALUE_6 16m
set -x GIT_CONFIG_KEY_7 gc.auto
set -x GIT_CONFIG_VALUE_7 0
set -x GIT_CONFIG_KEY_8 maintenance.auto
set -x GIT_CONFIG_VALUE_8 false

for row in (echo "Authorization: token $token" | curl -s -H @- https://api.github.com/user/repos?per_page=100 | jq -r '.[] | "\(.id)\t\(.full_name)"') # header from stdin
    set fields (string split \t $row)
    set repoId $fields[1]
    set repo $fields[2]

    string match -q 'AmazinAxel/*' $repo; or continue

    set repoName (string split '/' $repo)[2]
    set targetDir "/media/Projects/$repoName"
    set cleanUrl "https://github.com/$repo.git" # origin, auth via extraHeader

    # renames
    if not test -d "$targetDir/.git"
        for dir in /media/Projects/*/
            test -d "$dir/.git"; or continue
            if test (git -C "$dir" config --local --get homelab.repoid 2>/dev/null) = "$repoId"
                echo "Repo renamed: "(basename $dir)" -> $repoName, moving local copy"
                mv "$dir" "$targetDir"
                break
            end
        end
    end

    if test -d "$targetDir/.git"
        echo "Pulling repo $repoName"
        git -C "$targetDir" fetch "$cleanUrl"
        and git -C "$targetDir" reset --hard FETCH_HEAD
        and git -C "$targetDir" clean -fd
    else
        echo "Cloning repo $repoName"
        if git clone "$cleanUrl" "$targetDir"
            git -C "$targetDir" config --local homelab.repoid "$repoId"
        end
    end
end

log "GH: pulled repos"
