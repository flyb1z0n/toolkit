# Bash Aliases & Auto-Update Design

## Summary

Extend the toolkit with a bash aliases file (migrated from toolkitv0) and an auto-update mechanism that pulls latest changes once per day on terminal open.

## File Structure

```
toolkit/
├── aliases.sh              # all aliases + functions (migrated from v0)
├── loader.sh               # sourced by .zshrc — auto-update + source aliases
├── install.sh              # updated to add loader.sh sourcing to .zshrc
├── .gitignore              # add .toolkit_last_update
└── ...
```

## aliases.sh

Contains everything from `toolkitv0/aliases.zsh`:

- Simple aliases: `gs`, `ll`, `gnb`, `gl`, `tf`, `pp`, `cdc`, `cdd`, `cdp`, etc.
- npm aliases: `npm-def`, `npm-gr`, `clt`
- Shell functions: `al()`, `rpr()`, `arpr()`, `fpr()`, `cpr()`, `get_base_branch()`, `ttd()`, `nc()`

No loading logic. Just definitions. Sourced by `loader.sh`.

## loader.sh

Sourced from `~/.zshrc` on every shell open. Two responsibilities:

### 1. Auto-update

Resolves its own directory (repo root). Reads `.toolkit_last_update` for a unix timestamp.

| Condition | Action |
|---|---|
| File does not exist | Pull, create file with current timestamp |
| Timestamp is in the future (> now) | Delete file, treat as non-existent |
| Timestamp is older than 24h | Pull, update timestamp |
| Timestamp is within 24h | Skip pull |

Key behaviors:
- `git pull` runs in background (`&`) with `--quiet`, stdout/stderr suppressed
- Timestamp written before the pull completes (prevents retry spam on failed pulls)
- Updated code takes effect on the next shell open (aliases already sourced for current session)
- Failures (offline, etc.) are silently ignored

### 2. Source aliases

```bash
source "$TOOLKIT_DIR/aliases.sh"
```

## install.sh Changes

After existing commands installation loop, before the summary table:

1. Check if `# toolkit-loader` marker exists in `~/.zshrc`
2. If yes: skip (idempotent)
3. If no: append `source "<repo-path>/loader.sh" # toolkit-loader`
4. No interactive prompt (if you run install.sh, you want the loader)
5. Add result to summary table (`loader.sh` -> installed/up-to-date)

## .gitignore

Add `.toolkit_last_update` entry.
