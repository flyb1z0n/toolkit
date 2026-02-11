#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.claude/commands"
TARGET_DIR="$HOME/.claude/commands"

mkdir -p "$TARGET_DIR"

# Track results for summary table
declare -a NAMES=()
declare -a STATUSES=()

# --- Statusline installation ---
STATUSLINE_SOURCE="$SCRIPT_DIR/.claude/statusline.sh"
STATUSLINE_TARGET="$HOME/.claude/statusline.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

install_statusline=false
if [ -f "$STATUSLINE_SOURCE" ]; then
  echo ""
  echo "📊 Custom statusline available (shows dir, git branch, model)"

  if [ -L "$STATUSLINE_TARGET" ] && [ "$(readlink -f "$STATUSLINE_TARGET")" = "$(readlink -f "$STATUSLINE_SOURCE")" ]; then
    echo "✓ Statusline is already installed and up to date."
    NAMES+=("statusline.sh")
    STATUSES+=("up-to-date")
  else
    read -rp "  Install custom statusline? [y/N] " answer
    case "$answer" in
      [yY]|[yY][eE][sS])
        ln -sf "$STATUSLINE_SOURCE" "$STATUSLINE_TARGET"
        NAMES+=("statusline.sh")
        STATUSES+=("installed")
        ;;
      *)
        NAMES+=("statusline.sh")
        STATUSES+=("skipped")
        ;;
    esac
  fi

  # Ensure settings.json points to the correct statusline script
  # (runs whenever the symlink is in place, not just on fresh install)
  EXPECTED_CMD="~/.claude/statusline.sh"
  if [ -L "$STATUSLINE_TARGET" ] && [ "$(readlink -f "$STATUSLINE_TARGET")" = "$(readlink -f "$STATUSLINE_SOURCE")" ]; then
    if [ -f "$SETTINGS_FILE" ]; then
      CURRENT_CMD=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE" 2>/dev/null)
      if [ "$CURRENT_CMD" != "$EXPECTED_CMD" ]; then
        jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh","padding":0}' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp" \
          && mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "  ✓ Updated statusLine config in settings.json"
      fi
    else
      cat > "$SETTINGS_FILE" <<'SETTINGSEOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
SETTINGSEOF
      echo "  ✓ Created settings.json with statusLine config"
    fi
  fi
fi

# --- Commands installation ---
for cmd in "$SOURCE_DIR"/*.md; do
  name="$(basename "$cmd")"
  target="$TARGET_DIR/$name"
  NAMES+=("$name")

  if [ -e "$target" ] || [ -L "$target" ]; then
    # Check if it already points to the same source
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$cmd")" ]; then
      echo "✓ $name is already installed and up to date."
      STATUSES+=("up-to-date")
      continue
    fi

    echo ""
    echo "⚠ Command '$name' already exists at $target"
    read -rp "  Replace it? [y/N] " answer
    case "$answer" in
      [yY]|[yY][eE][sS])
        ln -sf "$cmd" "$target"
        STATUSES+=("replaced")
        ;;
      *)
        STATUSES+=("skipped")
        ;;
    esac
  else
    ln -sf "$cmd" "$target"
    STATUSES+=("installed")
  fi
done

# Print summary table
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  %-30s %s\n" "Command" "Status"
echo "  ─────────────────────────────────────────────"

for i in "${!NAMES[@]}"; do
  case "${STATUSES[$i]}" in
    installed)   icon="✅ Installed"   ;;
    replaced)    icon="🔄 Replaced"    ;;
    skipped)     icon="⏭️  Skipped"     ;;
    up-to-date)  icon="✅ Up to date"  ;;
  esac
  printf "  %-30s %s\n" "${NAMES[$i]}" "$icon"
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Commands directory: $TARGET_DIR"
