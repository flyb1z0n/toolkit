#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/.claude/commands"
TARGET_DIR="$HOME/.claude/commands"

mkdir -p "$TARGET_DIR"

for cmd in "$SOURCE_DIR"/*.md; do
  name="$(basename "$cmd")"
  ln -sf "$cmd" "$TARGET_DIR/$name"
  echo "Linked $name"
done

echo "Done. Commands installed to $TARGET_DIR"
