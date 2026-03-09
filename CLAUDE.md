# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal developer toolkit: shell aliases/functions (`aliases.sh`), a shell loader (`loader.sh`), Claude Code custom commands (`.claude/commands/`), a custom statusline (`.claude/statusline.sh`), and an installer (`install.sh`).

There is no build system, test suite, or package manager. All files are plain shell scripts.

## Installation

```bash
./install.sh
```

Creates symlinks from `.claude/commands/*.md` → `~/.claude/commands/` and `.claude/statusline.sh` → `~/.claude/statusline.sh`, updates `~/.claude/settings.json` for the statusline, and appends a `source` line to `~/.zshrc` for `loader.sh`.

To load aliases manually, add to `.zshrc`:
```bash
source "/path/to/toolkit/loader.sh"
```

## Architecture

### loader.sh
Sourced by `.zshrc` on every shell open. Does two things:
1. Background `git pull` once every 24 hours (tracked via `.toolkit_last_update` timestamp file)
2. Sources `aliases.sh`

### aliases.sh
All shell aliases and functions. Key functions:
- `nc` — creates a git worktree in the parent directory (`../projectname_feature_<id>`), then launches `claude` in it
- `rpr <mr_number_or_url>` — fetches a GitLab MR (supports both number and URL) and squash-merges it locally for review; uses `get_base_branch` to detect `main` vs `master`
- `arpr` — same as `rpr` but fetches from the `grc` remote instead of `origin`
- `fpr` — `git reset --hard HEAD` to discard review changes
- `cpr` — deletes all local `PR-*` branches

### .claude/commands/
Custom slash commands available in Claude Code (globally after install):
- `brainstorm.md` — interactive design/brainstorming workflow; saves output to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- `commit-and-push.md` — auto-commits and pushes; uses Conventional Commits; never commits directly to `main`/`master`

### .claude/statusline.sh
Claude Code statusline script. Reads JSON from stdin and outputs: directory name, git branch (with dirty indicator), model name, and a color-coded context window progress bar.

## Commit style

Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, etc.). See `.claude/commands/commit-and-push.md` for full spec.
