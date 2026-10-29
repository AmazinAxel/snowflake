function log
    # new log on top, keep the last 5
    read -z -l old </home/alec/logs.txt
    printf '%s\n' "$argv" (string split -n \n -- $old)[1..4] >/home/alec/logs.txt
end
