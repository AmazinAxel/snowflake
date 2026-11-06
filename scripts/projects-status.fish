#!/usr/bin/env fish
# Report which repos under ~/Projects (depth 1-2) need push (dirty/ahead) or pull (behind).
# Repos are checked in parallel; each line prints as soon as its fetch finishes.
set self (realpath (status filename))
if set -q argv[2]
    set d $argv[2]
    set -x GIT_TERMINAL_PROMPT 0
    set -x GIT_SSH_COMMAND 'ssh -o BatchMode=yes'
    git -C $d -c gc.auto=0 fetch --quiet --no-recurse-submodules 2>/dev/null; or set fetch_failed 1
    set dirty (git -C $d status --porcelain --ignore-submodules | count)
    set branch (git -C $d branch --show-current)
    set msg
    set -q fetch_failed; and set -a msg "fetch failed"
    test $dirty -gt 0; and set -a msg "$dirty uncommitted"
    if git -C $d rev-parse '@{u}' >/dev/null 2>&1
        set counts (string split \t (git -C $d rev-list --left-right --count 'HEAD...@{u}'))
        test $counts[1] -gt 0; and set -a msg "$counts[1] unpushed"
        test $counts[2] -gt 0; and set -a msg "$counts[2] to pull"
    else
        set -a msg "no upstream"
    end
    test (count $msg) -eq 0; and set msg clean
    printf '%-32s %-10s %s\n' (string replace $argv[1]/ '' $d) $branch (string join ', ' $msg)
    exit
end
set root $HOME/Projects
for g in $root/*/.git $root/*/*/.git
    fish --no-config $self $root (path dirname $g) &
end
wait
