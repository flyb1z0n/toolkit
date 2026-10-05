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

# --- Cursor CLI statusline installation ---
CURSOR_STATUSLINE_SOURCE="$SCRIPT_DIR/.cursor/statusline.sh"
CURSOR_STATUSLINE_TARGET="$HOME/.cursor/statusline.sh"
CURSOR_CONFIG_FILE="$HOME/.cursor/cli-config.json"

if [ -f "$CURSOR_STATUSLINE_SOURCE" ]; then
  echo ""
  echo "📊 Cursor CLI statusline available (shows dir, git branch, model, context, spend quota)"
  NAMES+=("cursor statusline.sh")

  if [ -L "$CURSOR_STATUSLINE_TARGET" ] && [ "$(readlink -f "$CURSOR_STATUSLINE_TARGET")" = "$(readlink -f "$CURSOR_STATUSLINE_SOURCE")" ]; then
    echo "✓ Cursor statusline is already installed and up to date."
    STATUSES+=("up-to-date")
  else
    read -rp "  Install Cursor CLI statusline? [y/N] " answer
    case "$answer" in
      [yY]|[yY][eE][sS])
        mkdir -p "$HOME/.cursor"
        ln -sf "$CURSOR_STATUSLINE_SOURCE" "$CURSOR_STATUSLINE_TARGET"
        STATUSES+=("installed")
        ;;
      *)
        STATUSES+=("skipped")
        ;;
    esac
  fi

  # Ensure cli-config.json points to the statusline script (the Cursor CLI creates this file on first run)
  CURSOR_EXPECTED_CMD="~/.cursor/statusline.sh"
  if [ -L "$CURSOR_STATUSLINE_TARGET" ] && [ "$(readlink -f "$CURSOR_STATUSLINE_TARGET")" = "$(readlink -f "$CURSOR_STATUSLINE_SOURCE")" ]; then
    if [ -f "$CURSOR_CONFIG_FILE" ]; then
      CURRENT_CMD=$(jq -r '.statusLine.command // ""' "$CURSOR_CONFIG_FILE" 2>/dev/null)
      if [ "$CURRENT_CMD" != "$CURSOR_EXPECTED_CMD" ]; then
        jq '.statusLine = {"type":"command","command":"~/.cursor/statusline.sh","padding":0}' "$CURSOR_CONFIG_FILE" > "$CURSOR_CONFIG_FILE.tmp" \
          && mv "$CURSOR_CONFIG_FILE.tmp" "$CURSOR_CONFIG_FILE"
        echo "  ✓ Updated statusLine config in cli-config.json"
      fi
    else
      echo "  ⚠ $CURSOR_CONFIG_FILE not found — run cursor-agent once, then re-run ./install.sh"
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

# --- Cursor skills installation ---
SKILLS_SOURCE_DIR="$SCRIPT_DIR/.cursor/skills"
SKILLS_TARGET_DIR="$HOME/.cursor/skills"

if [ -d "$SKILLS_SOURCE_DIR" ]; then
  mkdir -p "$SKILLS_TARGET_DIR"
  for skill in "$SKILLS_SOURCE_DIR"/*/; do
    skill="${skill%/}"
    name="$(basename "$skill")"
    target="$SKILLS_TARGET_DIR/$name"
    NAMES+=("cursor skill: $name")

    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$skill")" ]; then
        echo "✓ Cursor skill '$name' is already installed and up to date."
        STATUSES+=("up-to-date")
        continue
      fi

      echo ""
      echo "⚠ Cursor skill '$name' already exists at $target"
      read -rp "  Replace it? [y/N] " answer
      case "$answer" in
        [yY]|[yY][eE][sS])
          rm -rf "$target"
          ln -sfn "$skill" "$target"
          STATUSES+=("replaced")
          ;;
        *)
          STATUSES+=("skipped")
          ;;
      esac
    else
      ln -sfn "$skill" "$target"
      STATUSES+=("installed")
    fi
  done
fi

# --- Loader installation (.zshrc) ---
LOADER_SOURCE="$SCRIPT_DIR/loader.sh"
ZSHRC="$HOME/.zshrc"
LOADER_MARKER="# toolkit-loader"
LOADER_LINE="source \"$SCRIPT_DIR/loader.sh\" $LOADER_MARKER"

NAMES+=("loader.sh")
if [ -f "$ZSHRC" ] && grep -qF "$LOADER_MARKER" "$ZSHRC"; then
  echo "✓ loader.sh is already sourced in .zshrc"
  STATUSES+=("up-to-date")
else
  echo "" >> "$ZSHRC"
  echo "$LOADER_LINE" >> "$ZSHRC"
  echo "✓ Added loader.sh to .zshrc"
  STATUSES+=("installed")
fi

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
echo "Cursor skills directory: $SKILLS_TARGET_DIR"
