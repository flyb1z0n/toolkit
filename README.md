# Toolkit

A collection of tools and commands I use in daily life with [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## What's included

Custom Claude Code commands located in `.claude/commands/`:

| Command | Description |
|---------|-------------|
| `brainstorm` | Interactive brainstorming sessions for features, components, and architecture |
| `commit-and-push` | Auto-commit all changes and push to the current branch |

## Installation

```bash
./install.sh
```

This creates symlinks from the commands in this repo to `~/.claude/commands/`, making them available globally in Claude Code. If a command already exists, you'll be prompted to replace or skip it.
