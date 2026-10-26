---
description: Draft a short MR review request for #students-mr-review, preview it, and post only after approval
argument-hint: "[MR/PR URLs] [reviewer names]"
---

# Request MR review in #students-mr-review

Draft a review-request message for Slack channel `#students-mr-review`, show me a preview, and post it **only after I explicitly approve**.

Arguments (all optional, free-form): $ARGUMENTS

## 1. Collect the MRs

- If URLs were given, use them.
- Otherwise detect the MR/PR for the current branch:
  - GitHub remote: `gh pr view --json url,title,body,isDraft`
  - GitLab remote: `glab mr view --output json`
- If nothing is found, ask me for the links. Don't guess.
- For each MR, get its title and description so you can write a one-line summary.

## 2. Match my style

Read my own recent messages in `#students-mr-review` with the Slack MCP tools, and copy my phrasing, casing, and how I format links. If Slack history isn't available, use the channel convention:

```
<@REVIEWER_1> <@REVIEWER_2> PTAL: <MR_URL> short lowercase summary of what changed
```

- One line per MR. For several MRs, put each on its own line, or use `also: <url> ...` for follow-ups.
- Keep it short: the text besides mentions and links is **8 words at most** per MR (e.g. "return 400 for unreadable request bodies"). Count the words before showing the draft, and shorten it if it's over.
- The summary describes what the change does in plain words. It isn't the raw MR title, has no trailing period, and doesn't mention AI.
- Don't add greetings, emoji, or bullet lists unless my recent messages use them.

## 3. Reviewers

- Use the reviewers I named. Otherwise suggest the people I tagged most recently in the channel, and say they're a suggestion.
- Resolve every name to a Slack user ID with Slack user search and mention them as `<@USER_ID>`. Never tag myself.
- For backend MRs, tag the `@students-be-eng` user group instead of individual people: `<!subteam^S08AYHYK31A>` (shown as `@students-be-eng` in the readable preview).

## 4. Preview and confirm (mandatory)

Text written before a tool call can be collapsed out of sight, so the preview goes **inside the question itself**, never only in chat text.

1. **Every** time a draft is created or edited, including when you're confident in it, call the `AskUserQuestion` tool and put the full preview in its question:
   - The exact message text as it will be posted, in a code block.
   - Below it, a readable version with `@Name` in place of each `<@USER_ID>` and `@group` in place of each `<!subteam^ID>`.
   - Any note that affects my decision (e.g. reviewers are a suggestion, Slack isn't authenticated).
2. Options:
   - `Send it`
   - `Edit` (I'll describe the changes)
   - `Cancel`
3. `Edit`: apply my changes and ask again with the new preview. Repeat until I choose `Send it` or `Cancel`.
4. `Cancel`: stop and post nothing.
5. Skipped or unanswered question: post nothing, and end with a final message (after the last tool call) that repeats the exact draft in a code block so I can still see and copy it.

**Never** post to Slack before I choose `Send it` for the current draft. Silence, an unclear answer, or approval of an earlier draft doesn't count as approval.

## 5. Send

- Post the approved text exactly as drafted to `#students-mr-review`, as a new top-level message (not a thread reply).
- Reply with the message permalink.
- If Slack isn't authenticated, say so, and leave the final draft in the chat so I can paste it myself.
