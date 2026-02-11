#!/usr/bin/env bash
# Sourced by .zshrc on every shell open.
# 1. Auto-updates toolkit via background git pull (once per 24h)
# 2. Sources aliases.sh

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
TIMESTAMP_FILE="$TOOLKIT_DIR/.toolkit_last_update"
NOW=$(date +%s)
INTERVAL=86400 # 24 hours

should_pull=false

if [ ! -f "$TIMESTAMP_FILE" ]; then
  should_pull=true
elif [ "$(cat "$TIMESTAMP_FILE")" -gt "$NOW" ]; then
  # Timestamp in the future — corrupted, reset
  rm "$TIMESTAMP_FILE"
  should_pull=true
elif [ $(( NOW - $(cat "$TIMESTAMP_FILE") )) -gt $INTERVAL ]; then
  should_pull=true
fi

if [ "$should_pull" = true ]; then
  echo "$NOW" > "$TIMESTAMP_FILE"
  (cd "$TOOLKIT_DIR" && git pull --quiet >/dev/null 2>&1 &)
fi

# Load aliases and functions
source "$TOOLKIT_DIR/aliases.sh"
