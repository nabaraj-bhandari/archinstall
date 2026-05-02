#!/usr/bin/env bash
# wallpaper — pick via yazi or pass path directly
# usage: wallpaper [path]

set -e

WALL_DIR="$HOME/.wallpapers"
mkdir -p "$WALL_DIR"

if [ -n "$1" ]; then
  CHOSEN="$1"
else
  yazi --chooser-file=/tmp/yazi-wall "$WALL_DIR"
  CHOSEN=$(cat /tmp/yazi-wall 2>/dev/null)
  rm -f /tmp/yazi-wall
fi

[ -z "$CHOSEN" ] && exit 0
[ -f "$CHOSEN" ] || { echo "Not found: $CHOSEN"; exit 1; }

swww img "$CHOSEN" --transition-type fade --transition-duration 1
wal -i "$CHOSEN" -n -q

# reload waybar colors
pkill -SIGUSR2 waybar 2>/dev/null || true

echo "Wall: $CHOSEN"
