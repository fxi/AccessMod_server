#!/bin/sh \\

# http://askubuntu.com/questions/323131/setting-timezone-from-terminal
wget -qO - http://geoip.ubuntu.com/lookup | sed -n -e 's/.*<TimeZone>\(.*\)<\/TimeZone>.*/\1/p' | xargs sudo timedatectl set-timezone
