#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.claude/commands"
TARGET_DIR="$HOME/.claude/commands"

mkdir -p "$TARGET_DIR"

# Track results for summary table
declare -a NAMES=()
declare -a STATUSES=()

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
