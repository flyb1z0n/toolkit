# Git aliases
alias gwl="git worktree list"
alias gs="git status"
alias gnb="git checkout -b"
alias gl="git log --pretty=oneline"
unalias gcm 2>/dev/null
gcm() {
    local base_branch=$(get_base_branch)
    git checkout "$base_branch" && git pull origin "$base_branch"
}

# Claude Code aliases
alias cc='claude'

# General aliases
alias ll="ls -laG"
alias redock="killall Dock"
alias sshdo="ssh devops@164.92.90.35"
alias tcpu="sudo powermetrics --samplers smc |grep -i 'CPU'"
alias tf="terraform"
alias pp="ping 8.8.8.8"
alias cdd="cd ~/dev"
alias cdp="cd ~/dev/private"
alias cdt="cd ~/dev/tmp"

# Review PR - fetch and merge PR locally
# Usage: rpr <pr_number>
rpr() {
    BASE_BRANCH=$(get_base_branch)
    git checkout $BASE_BRANCH;
    git pull origin $BASE_BRANCH;
    DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S"`
    git fetch origin merge-requests/"$1"/head:PR-"$DATE_WITH_TIME"-"$1";
    git merge --squash PR-"$DATE_WITH_TIME"-"$1";
}

# Get base branch (main or master)
get_base_branch() {
    if [ "$(git branch --list master)" != "" ]; then
        echo "master"
    elif [ "$(git branch --list main)" != "" ]; then
        echo "main"
    else
        echo "base branch not found"
    fi
}

# Finish PR review - reset to HEAD
fpr() {
    git reset --hard HEAD
}

# Timestamp to date - convert Unix timestamp to readable date
# Usage: ttd <timestamp>
ttd() {
    if [ -z "$1" ]; then
        echo "Usage: ttd <timestamp>"
        exit 1
    fi

    timestamp=$1
    echo "UTC   : $(TZ=UTC date -r "$timestamp" "+%d %b %Y %H:%M:%S %Z")"
    echo "Local : $(date -r "$timestamp" "+%d %b %Y %H:%M:%S %Z")"
}

# Review PR (alternative remote)
# Usage: arpr <pr_number>
arpr() {
    BASE_BRANCH=$(get_base_branch)
    git checkout $BASE_BRANCH;
    git pull grc $BASE_BRANCH;
    DATE_WITH_TIME=`date "+%Y%m%d-%H%M%S"`
    git fetch grc pull/"$1"/head:PR-"$DATE_WITH_TIME"-"$1";
    git merge --squash PR-"$DATE_WITH_TIME"-"$1";
}

# Clean PR branches - delete all local PR branches
cpr() {
    git branch -l | grep PR- | xargs git branch -D
}

# New Claude - Start feature development in git worktree
nc() {
  # Check if we're in a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Detect base branch (main or master)
  local base_branch=""
  if git show-ref --verify --quiet refs/remotes/origin/main; then
    base_branch="main"
  elif git show-ref --verify --quiet refs/remotes/origin/master; then
    base_branch="master"
  else
    echo "Error: Could not find main or master branch in origin"
    return 1
  fi

  # Fetch latest changes from origin
  echo "Fetching latest changes from origin..."
  if ! git fetch origin; then
    echo "Error: Could not fetch from origin"
    return 1
  fi

  # Generate default identifier
  local project_name=$(basename "$PWD")
  local timestamp=$(date +%Y-%m-%d-%H-%M-%S)

  # Prompt for feature identifier (timestamp is default)
  local feature_id=""
  read "feature_id?Feature name [$timestamp]: "
  feature_id=${feature_id:-$timestamp}

  # Sanitize input: replace spaces with underscores
  feature_id=${feature_id// /_}

  # Construct full name: <projectname>_feature_<identifier>
  local feature_name="${project_name}_feature_${feature_id}"

  # Check if branch already exists
  if git show-ref --verify --quiet refs/heads/"$feature_name"; then
    echo "Error: Branch '$feature_name' already exists"
    return 1
  fi

  # Create worktree in parent directory
  local worktree_path="$(dirname "$PWD")/$feature_name"
  echo "Creating worktree at $worktree_path..."
  if ! git worktree add "$worktree_path" -b "$feature_name" "origin/$base_branch"; then
    echo "Error: Could not create worktree"
    return 1
  fi

  echo "Worktree created successfully!"
  echo "Launching Claude Code..."

  # Change to new directory and launch Claude Code
  cd "$worktree_path"
  claude
}
