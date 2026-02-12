# Toolkit

A collection of shell aliases, functions, and [Claude Code](https://docs.anthropic.com/en/docs/claude-code) commands I use daily.

## What's included

### Claude Code commands

Custom commands located in `.claude/commands/`:

| Command | Description |
|---------|-------------|
| `brainstorm` | Interactive brainstorming sessions for features, components, and architecture |
| `commit-and-push` | Auto-commit all changes and push to the current branch |

### Shell aliases

Defined in `aliases.sh`, loaded automatically via `loader.sh`:

| Alias | Description |
|-------|-------------|
| `cc` | Launch Claude Code |
| `gs` | `git status` |
| `gl` | `git log --pretty=oneline` |
| `gnb` | `git checkout -b` |
| `gwl` | `git worktree list` |
| `ll` | `ls -laG` |
| `tf` | `terraform` |
| `pp` | `ping 8.8.8.8` |
| `cdd` | `cd ~/dev` |
| `cdp` | `cd ~/dev/private` |
| `cdt` | `cd /dev/tmp` |

### Shell functions

| Function | Description |
|----------|-------------|
| `nc` | Create a git worktree for a new feature and launch Claude Code |
| `rpr <pr>` | Fetch and merge a PR locally for review |
| `arpr <pr>` | Same as `rpr` but from an alternative remote |
| `fpr` | Finish PR review (reset to HEAD) |
| `cpr` | Clean up local PR branches |
| `ttd <timestamp>` | Convert Unix timestamp to readable date |

### Auto-update

`loader.sh` is sourced from `.zshrc` and performs a background `git pull` once every 24 hours to keep the toolkit up to date.

## Installation

```bash
./install.sh
```

This creates symlinks from the commands in this repo to `~/.claude/commands/`, making them available globally in Claude Code. If a command already exists, you'll be prompted to replace or skip it.

To load aliases, add this to your `.zshrc`:

```bash
source "/path/to/toolkit/loader.sh"
```
