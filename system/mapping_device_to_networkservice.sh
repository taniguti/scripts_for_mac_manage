#!/bin/sh
# vi: set ts=4 sw=4 sts=0 et ft=sh fenc=utf-8 ff=unix :

for d in $(networksetup -listnetworkserviceorder | grep '(Hardware Port:' | awk '$(NF - 1) == "Device:" {print $NF}' | tr -d ')' | sort); do
    echo "${d}: $(networksetup -listnetworkserviceorder | grep -B 1 "${d})" | head -1 | awk '{$1 = ""; print }')" | xargs
done
