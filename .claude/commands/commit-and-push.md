---
allowed-tools: Bash
---

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

IMPORTANT: Do NOT ask the user for confirmation at any step. Just execute everything automatically.

IMPORTANT: NEVER commit or push directly to `main` or `master` branches. If you are on main/master, creating a new branch is REQUIRED, not optional. Always switch to a feature branch before committing.

Commit message guidelines:
1. First, check if there is a CLAUDE.md file in the repository that specifies a commit message style. If so, follow that style.
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

3. NEVER mention that this commit was created by Claude or any AI assistant
