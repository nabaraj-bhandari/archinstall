#!/usr/bin/env bash
# wallpaper-init — restore last wal wallpaper on login

LAST="$HOME/.cache/wal/wal"
DEFAULT="$HOME/.wallpapers/default.png"

if [ -f "$LAST" ]; then
  wallpaper "$(cat "$LAST")"
elif [ -f "$DEFAULT" ]; then
  wallpaper "$DEFAULT"
fi
