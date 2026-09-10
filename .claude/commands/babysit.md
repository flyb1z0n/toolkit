---
description: "Babysit a PR/MR: watch CI failures and try to fix them, triage review comments and draft concise replies for approval. Never posts anything without explicit confirmation."
argument-hint: "<pr-url-or-number>"
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Task, TodoWrite
---

# Babysit PR

Babysit the pull request / merge request given as `$ARGUMENTS` until it is green and all review
comments are addressed.

## Absolute rules

1. **NEVER post, reply to, or resolve a comment, review, or approval on your own.** You draft the
   reply, show it to me, and wait for an explicit "yes"/"send it". No exceptions, not even for
   "obvious" one-word answers like "Done".
2. **NEVER merge the PR**, never force-push, never push to `main`/`master`.
3. **Drafted replies must be concise** — 1-3 sentences, no greetings, no restating the reviewer's
   comment back at them, no AI-assistant flourishes ("Great catch!", "You're absolutely right!").
   Plain engineer-to-engineer tone. Reference `file:line` where useful.
4. **Never mention Claude or AI** in commits, replies, or PR text.
5. Only touch code in service of this PR. Don't drive-by refactor.

## 1. Resolve the target

`$ARGUMENTS` may be a full URL, or a bare number (then use the current repo).

- GitHub (`github.com/<owner>/<repo>/pull/<n>`) → use `gh`.
- GitLab (`.../-/merge_requests/<n>`) → use `glab` if available, otherwise `curl` the API.

If the tool is missing or unauthenticated, say so and stop — don't guess at the PR state.

Check out the PR branch locally so you can actually build and test:

```bash
gh pr checkout <n>   # inside the correct repo clone
```

If the current working directory is not that repo, tell me and stop rather than cloning somewhere
random.

Then print a short status header: PR title, author, branch, mergeable state, CI summary, number of
unresolved comments.

## 2. CI/CD failures

```bash
gh pr checks <n>
```

For every failing (or errored) check:

1. Fetch the log: `gh run view <run-id> --log-failed` (or `gh api` for the job log). For GitLab:
   `glab ci trace <job>`.
2. Read the actual failure — the assertion, the compiler error, the lint rule, the exit code. Don't
   speculate from the job name.
3. Classify it:
   - **Fixable by me** — test failure caused by this PR's code, lint/format violation, type error,
     missing snapshot/lockfile update, broken build.
   - **Flake / infra** — timeout, network error, runner died, unrelated failing job, secret missing.
     Do NOT "fix" these by weakening the check. Report them and, if it's clearly a flake, offer to
     re-run: `gh run rerun <run-id> --failed`. Ask before re-running.
   - **Needs a human decision** — the failure reveals a design problem, requires new product
     behaviour, or the "fix" would change the PR's intent. Stop and ask.
4. Fix it properly. Never disable a test, add a blanket `eslint-disable`, `# type: ignore`,
   `--no-verify`, `continue-on-error`, or relax an assertion just to get green. If that's genuinely
   the right answer, ask me first and explain why.
5. Reproduce locally when it's cheap (run the failing test/lint command) before and after the fix.
6. Commit with a focused Conventional Commits message and push to the PR branch. Follow the
   repo's own commit style from its `CLAUDE.md` if it has one.

Group related fixes into one commit; don't spam the branch with one commit per file.

## 3. Review comments

Collect everything unresolved:

```bash
gh pr view <n> --comments
gh api repos/<owner>/<repo>/pulls/<n>/comments   # inline review comments, with paths + line numbers
gh api repos/<owner>/<repo>/pulls/<n>/reviews
```

Skip bot noise that needs no answer (coverage bots, changelog bots) unless it's blocking. Skip
threads already marked resolved.

For each comment, read the code it points at, then bucket it:

- **Actionable & clear** → make the change, then draft a reply saying what you changed.
- **Question** → answer it from the code. Draft the answer. No code change.
- **Disagree** → draft a short, factual counter-argument with the reason. Don't cave just to be
  agreeable, and don't be combative.
- **Ambiguous or opinion-level** → don't guess. Ask me what I want before drafting.

Then present a single review table:

| # | Reviewer | File:line | Ask | Action taken | Draft reply |
|---|----------|-----------|-----|--------------|-------------|

Followed by the full draft replies, each in its own fenced block so I can edit them:

```
[#3 → @reviewer on src/api/handler.ts:88]
Moved the nil check above the deref. Added a regression test in handler_test.ts:142.
```

Then ask, one prompt covering all of them:

> Send these replies? (`all` / numbers, e.g. `1,3` / `edit N` / `none`)

Only after I answer do you post — and only the ones I named:

```bash
gh pr comment <n> --body "..."                     # top-level
gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments/<comment-id>/replies -f body="..."   # inline thread reply
```

Do not resolve threads. That's mine to do.

## 4. Loop

After pushing fixes, wait for CI and re-check:

```bash
gh pr checks <n> --watch
```

Repeat sections 2-3 until CI is green and every comment is either answered (with my approval) or
parked on a question to me. Cap it at 3 fix attempts per distinct failure — if a failure survives
three honest attempts, stop and hand it back with what you tried and what you learned.

## 5. Final report

End with:

- **CI**: green / still failing (which checks, why)
- **Fixed**: commits pushed, one line each
- **Replies**: posted / awaiting my approval
- **Blocked on you**: the specific questions you need answered
- **Not done**: anything you deliberately left alone, and why

Keep it short. No recap of things you already said.
