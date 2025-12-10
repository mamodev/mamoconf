# Get count for official Arch packages
OFFICIAL_UPDATES=$(checkupdates | wc -l)

# Get count for AUR packages (using yay)
AUR_UPDATES=$(yay -Qau 2>/dev/null | wc -l)

TOTAL_UPDATES=$(( OFFICIAL_UPDATES + AUR_UPDATES ))

if [ "$TOTAL_UPDATES" -gt 0 ]; then
    /usr/bin/notify-send -a 'System Updates' "Total $TOTAL_UPDATES Packages Ready" \
    "Arch: $OFFICIAL_UPDATES | AUR: $AUR_UPDATES. Run 'yay' to update."
fi
