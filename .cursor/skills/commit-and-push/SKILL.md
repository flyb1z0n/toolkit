---
name: commit-and-push
description: "Automatically commit all changes with a Conventional Commits message and push, without asking for confirmation. Never commits to main/master - creates a feature branch first. Use when the user invokes /commit-and-push."
disable-model-invocation: true
---

# Commit and push

Automatically commit all changes and push without asking for confirmation.

1. Run `git status` and `git diff` to see all changes
2. Check the current branch with `git branch --show-current`
3. If on `main` or `master` branch:
   - Create a new branch with a meaningful name based on the changes (e.g., `add-config-service`, `fix-webhook-handler`)
   - Do NOT use `/` in branch names
   - Switch to that branch with `git checkout -b <branch-name>`
4. Stage ALL changes with `git add -A`
5. Create a meaningful commit message based on the changes
6. Commit immediately without asking for user approval
7. Push to the current branch (use `-u origin <branch-name>` if it's a new branch)
8. Always end the reply with a PR/MR link (existing request, or a create URL if none exists). Never skip this, even when the branch was already pushed or there was nothing new to commit.
9. After the link, propose a PR/MR title and description (see "PR / MR title and description" below)

IMPORTANT: Do NOT ask the user for confirmation at any step. Just execute everything automatically.

IMPORTANT: NEVER commit or push directly to `main` or `master` branches. If you are on main/master, creating a new branch is REQUIRED, not optional. Always switch to a feature branch before committing.

IMPORTANT: NEVER use `git commit --no-verify` or otherwise bypass pre-commit hooks. If a hook fails, fix the cause and commit again.

Commit message guidelines:
1. First, check if there is an `AGENTS.md` or `CLAUDE.md` file in the repository that specifies a commit message style. If so, follow that style.
2. If no specific style is defined, use the Conventional Commits 1.0.0 convention:

   Format:
   ```
   <type>[optional scope]: <description>

   [optional body]

   [optional footer(s)]
   ```

   Types:
   - `feat`: introduces a new feature (correlates with MINOR in SemVer)
   - `fix`: patches a bug (correlates with PATCH in SemVer)
   - `docs`: documentation only changes
   - `style`: formatting, missing semi colons, etc; no code change
   - `refactor`: code change that neither fixes a bug nor adds a feature
   - `perf`: code change that improves performance
   - `test`: adding missing tests or correcting existing tests
   - `build`: changes to build system or external dependencies
   - `ci`: changes to CI configuration files and scripts
   - `chore`: other changes that don't modify src or test files
   - `revert`: reverts a previous commit

   Breaking changes:
   - Add '!' after type/scope: `feat!: breaking change description`
   - Or add footer: `BREAKING CHANGE: description`

   Examples:
   - `feat(auth): add user login validation`
   - `fix: resolve null pointer in handler`
   - `docs: correct spelling of CHANGELOG`
   - `feat!: send email to customer when product is shipped`

3. NEVER mention that this commit was created by Claude, Cursor, or any AI assistant

## PR / MR link (required)

After push, always print a clickable URL in the final reply. Do not open a browser or create the PR/MR unless the user asked.

Detect the forge from `git remote get-url origin` (GitHub vs GitLab). Resolve the current branch with `git branch --show-current`.

1. If a PR/MR already exists for this branch, use that URL:
   - GitHub: `gh pr view --json url -q .url`
   - GitLab: `glab mr view --comments=false 2>/dev/null` or `glab mr list --source-branch "$(git branch --show-current)" -F json`
2. Otherwise print a **create** URL (do not run `gh pr create` / `glab mr create`):
   - GitHub: `https://github.com/<owner>/<repo>/compare/<branch>?expand=1`
     (`gh repo view --json url -q .url` plus `/compare/<branch>?expand=1` is fine; `owner/repo` can also come from the origin URL)
   - GitLab: `https://<host>/<project>/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branch>`
     (`glab repo view -F json` or the origin URL for host/project)

URL-encode the branch name in the query string. If `gh`/`glab` is missing, build the create URL from `origin`. If origin is neither GitHub nor GitLab, still print the best compare/create URL you can derive and say which forge could not be detected.

## PR / MR title and description

After the link, propose a title and description the user can paste into the PR/MR. Never create or edit the PR/MR yourself.

- Cover the whole branch, not only the latest commit: use `git log <base>..HEAD` and `git diff <base>...HEAD`, where `<base>` is the default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`, falling back to `origin/main` or `origin/master`).
- If the repo has a PR/MR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`, `.gitlab/merge_request_templates/`), fill it in instead of using the default layout below.
- If a PR/MR already exists, propose an updated title and description only when the new commits change what it covers; otherwise say the current ones still fit.
- Title: Conventional Commits style, matching the commit convention above, under ~72 characters.
- Description, kept short:
  - 1–3 sentences on what changed and why
  - a bullet list of notable changes, only when there is more than one
  - how it was tested (commands run, new tests), or that it wasn't
- Put the title and the description in separate fenced code blocks so each copies cleanly.
- NEVER mention that the changes or description were produced by Claude, Cursor, or any AI assistant.
