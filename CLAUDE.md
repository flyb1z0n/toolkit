# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal developer toolkit: shell aliases/functions (`aliases.sh`), a shell loader (`loader.sh`), Claude Code custom commands (`.claude/commands/`), a custom statusline (`.claude/statusline.sh`), and an installer (`install.sh`).

There is no build system, test suite, or package manager. All files are plain shell scripts.

## Installation

```bash
./install.sh
```

Creates symlinks from `.claude/commands/*.md` → `~/.claude/commands/` and `.claude/statusline.sh` → `~/.claude/statusline.sh`, updates `~/.claude/settings.json` for the statusline, does the same for `.cursor/statusline.sh` → `~/.cursor/statusline.sh` and `~/.cursor/cli-config.json`, and appends a `source` line to `~/.zshrc` for `loader.sh`.

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
- `rpr <mr_number_or_url>` — fetches a GitLab MR or GitHub PR (supports bare number, GitLab `merge_requests/N` URLs, or GitHub `pull/N` URLs, including `/changes` and `/commits` suffixes) and squash-merges it locally for review; uses `get_base_branch` to detect `main` vs `master`
- `arpr` — same as `rpr` but fetches from the `grc` remote instead of `origin`
- `fpr` — `git reset --hard HEAD` to discard review changes
- `cpr` — deletes all local `PR-*` branches

### .claude/commands/
Custom slash commands available in Claude Code (globally after install). `install.sh` symlinks every
`*.md` in this directory, so adding a new command file is all that's needed — no installer change.
- `babysit.md` — takes a PR/MR URL or number; investigates and fixes CI failures, triages review comments, and drafts concise replies that must be explicitly approved before posting. Never posts, resolves threads, or merges on its own
- `brainstorm.md` — interactive design/brainstorming workflow; saves output to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- `commit-and-push.md` — auto-commits and pushes; uses Conventional Commits; never commits directly to `main`/`master`

### .cursor/skills/
Cursor Agent Skills — the same three workflows as `.claude/commands/`, in `SKILL.md` format
(`babysit/`, `brainstorm/`, `commit-and-push/`). `install.sh` symlinks each skill directory into
`~/.cursor/skills/`. When changing a command, update its `.cursor/skills/<name>/SKILL.md` twin too.

### .claude/statusline.sh
Claude Code statusline script. Reads JSON from stdin and outputs: directory name, git branch (with dirty indicator), model name, and a color-coded context window progress bar.

### .cursor/statusline.sh
Cursor CLI twin of the Claude statusline (symlinked to `~/.cursor/statusline.sh`, wired up via `statusLine` in
`~/.cursor/cli-config.json`). Same layout, plus model params / MAX / autorun / worktree. Instead of the Claude
5-hour quota (not in the Cursor payload), it shows monthly team spend vs. per-user limit, fetched from
`DashboardService/GetTeamSpend` with the CLI's keychain token (`cursor-access-token`, macOS only). The result is
cached in `~/.cache/cursor-statusline/quota.json` and refreshed in a detached background job at most every 5 min,
because the CLI kills the script on every update and times it out after 2s. When changing shared layout, update
both statusline scripts.

## Commit style

Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, etc.). See `.claude/commands/commit-and-push.md` for full spec.
