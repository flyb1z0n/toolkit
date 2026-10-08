#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Extract values in a single jq pass (unit-separator delimited, so empty fields survive)
IFS=$'\x1f' read -r MODEL_DISPLAY PARAM_SUMMARY MAX_MODE CURRENT_DIR CONTEXT_RAW WORKTREE_NAME AUTORUN <<< "$(
    echo "$input" | jq -r '[
        (.model.display_name // "unknown"),
        (.model.param_summary // ""),
        (.model.max_mode // false),
        (.workspace.current_dir // .cwd // ""),
        (.context_window.used_percentage // 0),
        (.worktree.name // ""),
        (.autorun // false)
    ] | map(tostring) | join("\u001f")'
)"
CONTEXT_USED=$(printf "%.0f" "$CONTEXT_RAW" 2>/dev/null || echo 0)

BAR_WIDTH=10

# Color a percentage: green <50, yellow 50-79, red 80+
pct_color() {
    if [ "$1" -ge 80 ]; then echo "0;31"
    elif [ "$1" -ge 50 ]; then echo "0;33"
    else echo "0;32"
    fi
}

# Build a progress bar of BAR_WIDTH chars for a 0-100 percentage
make_bar() {
    local pct=$1 filled empty bar="" i
    [ "$pct" -gt 100 ] && pct=100
    filled=$(( pct * BAR_WIDTH / 100 ))
    empty=$(( BAR_WIDTH - filled ))
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "$bar"
}

file_age() {
    local mtime
    mtime=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || { echo 999999; return; }
    echo $(( $(date +%s) - mtime ))
}

# --- Cursor spend quota ---
# Fetched from the Cursor dashboard API with the CLI's keychain token, cached on disk,
# and refreshed in the background so the status line never waits on the network.
QUOTA_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/cursor-statusline"
QUOTA_CACHE="$QUOTA_DIR/quota.json"
QUOTA_STAMP="$QUOTA_DIR/quota.attempt"
QUOTA_TTL=300

refresh_quota() {
    local cfg="$HOME/.cursor/cli-config.json" team user email token body
    team=$(jq -r '.authInfo.activeTeamId // .authInfo.teamId // empty' "$cfg" 2>/dev/null)
    user=$(jq -r '.authInfo.userId // empty' "$cfg" 2>/dev/null)
    email=$(jq -r '.authInfo.email // empty' "$cfg" 2>/dev/null)
    [ -n "$team" ] && [ -n "$user" ] || return 1
    token=$(security find-generic-password -s cursor-access-token -w 2>/dev/null) || return 1
    body=$(jq -nc --argjson t "$team" --arg s "$email" '{teamId: $t, searchTerm: $s}')

    # Token goes through curl's stdin config, not argv, so it never shows up in `ps`
    curl -s -m 10 -K - -X POST \
        "https://api2.cursor.sh/aiserver.v1.DashboardService/GetTeamSpend" \
        -H "Content-Type: application/json" -H "Connect-Protocol-Version: 1" \
        -d "$body" <<< "header = \"Authorization: Bearer $token\"" \
    | jq -e --argjson u "$user" '
        [.teamMemberSpend[]? | select(.userId == $u)][0]
        | select(. != null)
        | {spent_cents: (.overallSpendCents // 0),
           limit_dollars: (.effectivePerUserLimitDollars // .monthlyLimitDollars // .hardLimitOverrideDollars)}
        | select(.limit_dollars != null)' > "$QUOTA_CACHE.tmp" \
    && mv "$QUOTA_CACHE.tmp" "$QUOTA_CACHE"
    rm -f "$QUOTA_CACHE.tmp"
}

mkdir -p "$QUOTA_DIR"
if [ "$(file_age "$QUOTA_STAMP")" -ge "$QUOTA_TTL" ]; then
    touch "$QUOTA_STAMP"
    # Fully detached: the CLI kills this script on every update and waits for stdout to close
    ( refresh_quota ) </dev/null >/dev/null 2>&1 &
    disown
fi

QUOTA_INFO=""
if [ -f "$QUOTA_CACHE" ] && [ "$(file_age "$QUOTA_CACHE")" -lt 86400 ]; then
    IFS=$'\x1f' read -r SPENT_CENTS LIMIT_DOLLARS <<< "$(jq -r '[.spent_cents, .limit_dollars] | map(tostring) | join("\u001f")' "$QUOTA_CACHE" 2>/dev/null)"
    if [ -n "$LIMIT_DOLLARS" ] && [ "$LIMIT_DOLLARS" -gt 0 ] 2>/dev/null; then
        # cents / dollars == percent
        QUOTA_USED=$(( SPENT_CENTS / LIMIT_DOLLARS ))
        QUOTA_INFO=$(printf "  🪙 \033[$(pct_color "$QUOTA_USED")m[%s] %s%%\033[0m \033[0;90m\$%d/\$%d\033[0m" \
            "$(make_bar "$QUOTA_USED")" "$QUOTA_USED" "$(( SPENT_CENTS / 100 ))" "$LIMIT_DOLLARS")
    fi
fi

# Get directory basename
DIR_NAME=${CURRENT_DIR##*/}

# Check if we're in a git repo and get branch
cd "$CURRENT_DIR" 2>/dev/null
GIT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Use --no-optional-locks to avoid lock issues
    GIT_BRANCH=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    git_dirty=$(git --no-optional-locks status --porcelain 2>/dev/null)
    BRANCH_ICON="🔀"
    [ -n "$WORKTREE_NAME" ] && BRANCH_ICON="🖥️"

    if [ -n "$git_dirty" ]; then
        # Dirty repo - show branch with ✗ (red branch, yellow ✗)
        GIT_INFO=$(printf " %s \033[0;31m%s\033[0m \033[0;33m✗\033[0m" "$BRANCH_ICON" "$GIT_BRANCH")
    else
        # Clean repo (red branch)
        GIT_INFO=$(printf " %s \033[0;31m%s\033[0m" "$BRANCH_ICON" "$GIT_BRANCH")
    fi
else
    GIT_INFO=""
fi

CONTEXT_INFO=$(printf "\033[$(pct_color "$CONTEXT_USED")m[%s] %s%%\033[0m" "$(make_bar "$CONTEXT_USED")" "$CONTEXT_USED")

# Model extras: param summary, MAX mode, autorun
MODEL_EXTRA=""
[ -n "$PARAM_SUMMARY" ] && MODEL_EXTRA+=$(printf " \033[0;90m%s\033[0m" "$PARAM_SUMMARY")
[ "$MAX_MODE" = "true" ] && MODEL_EXTRA+=$(printf " \033[1;35mMAX\033[0m")
[ "$AUTORUN" = "true" ] && MODEL_EXTRA+=$(printf "  ⚡ \033[0;33mautorun\033[0m")

# Determine if git branch is too long (>30 chars) to put on new line
BRANCH_LENGTH=${#GIT_BRANCH}
if [ -n "$GIT_BRANCH" ] && [ "$BRANCH_LENGTH" -gt 30 ]; then
    # Long branch - put git info on separate line
    printf "📁 \033[0;36m%s\033[0m\n%s\n🤖 \033[0;33m[%s]\033[0m%s\n🧠 %s%s" "$DIR_NAME" "$GIT_INFO" "$MODEL_DISPLAY" "$MODEL_EXTRA" "$CONTEXT_INFO" "$QUOTA_INFO"
else
    # Short branch or no git - keep on same line
    printf "📁 \033[0;36m%s\033[0m%s\n🤖 \033[0;33m[%s]\033[0m%s\n🧠 %s%s" "$DIR_NAME" "$GIT_INFO" "$MODEL_DISPLAY" "$MODEL_EXTRA" "$CONTEXT_INFO" "$QUOTA_INFO"
fi
