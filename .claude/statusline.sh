#!/bin/bash
# Read JSON input from stdin
input=$(cat)

# Extract values using jq
MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
CONTEXT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | xargs printf "%.0f")

# Get directory basename
DIR_NAME=${CURRENT_DIR##*/}

# Check if we're in a git repo and get branch
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Use --no-optional-locks to avoid lock issues
    GIT_BRANCH=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    git_dirty=$(git --no-optional-locks status --porcelain 2>/dev/null)

    if [ -n "$git_dirty" ]; then
        # Dirty repo - show branch with ✗ (red branch, yellow ✗)
        GIT_INFO=$(printf " 🔀 \033[0;31m%s\033[0m \033[0;33m✗\033[0m" "$GIT_BRANCH")
    else
        # Clean repo (red branch)
        GIT_INFO=$(printf " 🔀 \033[0;31m%s\033[0m" "$GIT_BRANCH")
    fi
else
    GIT_INFO=""
fi

# Color context percentage: green <50, yellow 50-79, red 80+
if [ "$CONTEXT_USED" -ge 80 ]; then
    CONTEXT_COLOR="0;31"  # red
elif [ "$CONTEXT_USED" -ge 50 ]; then
    CONTEXT_COLOR="0;33"  # yellow
else
    CONTEXT_COLOR="0;32"  # green
fi

# Build progress bar (10 chars wide)
BAR_WIDTH=10
FILLED=$(( CONTEXT_USED * BAR_WIDTH / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
CONTEXT_INFO=$(printf "\033[${CONTEXT_COLOR}m[%s] %s%%\033[0m" "$BAR" "$CONTEXT_USED")

# Determine if git branch is too long (>30 chars) to put on new line
BRANCH_LENGTH=${#GIT_BRANCH}
if [ -n "$GIT_BRANCH" ] && [ "$BRANCH_LENGTH" -gt 30 ]; then
    # Long branch - put git info on separate line
    printf "📁 \033[0;36m%s\033[0m\n%s\n🤖 \033[0;33m[%s]\033[0m  🧠 %s" "$DIR_NAME" "$GIT_INFO" "$MODEL_DISPLAY" "$CONTEXT_INFO"
else
    # Short branch or no git - keep on same line
    printf "📁 \033[0;36m%s\033[0m%s\n🤖 \033[0;33m[%s]\033[0m  🧠 %s" "$DIR_NAME" "$GIT_INFO" "$MODEL_DISPLAY" "$CONTEXT_INFO"
fi
