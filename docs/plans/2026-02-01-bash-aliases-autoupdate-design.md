# Bash Aliases & Auto-Update Design

## Summary

Extend the toolkit with a bash aliases file and an auto-update mechanism that pulls latest changes once per day on terminal open.

## File Structure

```
toolkit/
├── aliases.sh              # alias definitions
├── loader.sh               # sourced by .zshrc — aliases + auto-update
├── install.sh              # updated to add loader.sh sourcing to .zshrc
├── .gitignore              # contains .toolkit_last_update
└── ...
```

## New Files

### `aliases.sh`

Plain alias definitions, no logic:

```bash
alias gs='git status'
```

### `loader.sh`

Sourced from `.zshrc` on every shell open. Responsibilities:

1. Determine its own directory (repo root)
2. Read `.toolkit_last_update` for a unix timestamp
3. Apply timestamp logic (see below)
4. Source `aliases.sh`

### `.gitignore`

Add `.toolkit_last_update` entry.

## Auto-Update Timestamp Logic

The file `.toolkit_last_update` stores a single unix timestamp.

| Condition | Action |
|---|---|
| File does not exist | Pull, create file with current timestamp |
| Timestamp is in the future (greater than now) | Delete file, treat as non-existent |
| Timestamp is older than 24h | Pull, update timestamp |
| Timestamp is within 24h | Skip pull |

- `git pull` runs in background (`&`) with `--quiet`, no stdout/stderr
- Failures (offline, etc.) are silently ignored

## Install Script Changes

After existing symlink logic, handle `.zshrc`:

- Check if `# toolkit-loader` marker already exists in `~/.zshrc`
- If yes: skip (idempotent)
- If no: append `source "<repo-path>/loader.sh" # toolkit-loader`
- Report result in the summary table
