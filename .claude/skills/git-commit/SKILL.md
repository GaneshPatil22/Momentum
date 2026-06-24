---
name: git-commit
description: "Stage every unstaged & untracked change and create one commit with a feature-style title plus a 2-3 line description of what changed and why. Use whenever the user says /git-commit, 'commit my changes', 'wrap this up with a commit', etc."
---

# /git-commit

One-shot helper: looks at the working tree, stages everything that isn't already staged, and creates a single well-formatted commit.

## When to invoke

The user typed `/git-commit`, or asked you in plain English to commit the current changes. Do **not** invoke autonomously after editing files — only when the user asks for it.

## Procedure

Run the discovery commands in parallel first:

1. `git status --short` — list staged, unstaged, and untracked files.
2. `git diff --stat` and `git diff --cached --stat` — quick size view.
3. `git diff` and `git diff --cached` — full diff for message-writing context.
4. `git log -5 --oneline` — match the repo's existing commit-message style.

Then:

5. **Safety screen.** If the diff includes anything that looks like a secret (`.env`, `*.pem`, `*.p12`, API keys, OAuth tokens, signing certs, `*.mobileprovision`, `GoogleService-Info.plist` with live keys), STOP and ask the user before staging it. Never auto-commit secrets.
6. **Stage by name, not `-A`.** Build the file list from `git status --short` and pass paths explicitly to `git add` so unrelated junk (e.g. `.DS_Store`, IDE state) doesn't sneak in. If untracked files clearly shouldn't be committed, ask first.
7. **Draft the message.** Format:

   ```
   <Feature title in sentence case, <=70 chars, imperative mood>

   <Line 1 — what changed, concretely.>
   <Line 2 — why it changed / the user-visible effect.>
   <Optional line 3 — anything non-obvious a reviewer needs.>
   ```

   The title should read like a feature name, not a verb dump (e.g. `Add onboarding swipe flow` not `Various changes to onboarding`). Keep the body to 2–3 lines max, focused on *why*, not a file list — `git show` already shows files.

8. **Commit** with a HEREDOC so newlines survive:

   ```bash
   git commit -m "$(cat <<'EOF'
   <title>

   <body>
   EOF
   )"
   ```

9. `git status` afterwards to confirm a clean tree, and print the resulting `git log -1 --oneline` to the user.

## Hard rules

- **Never** use `--amend`, `--no-verify`, `-c commit.gpgsign=false`, or any flag that bypasses hooks/signing. If a pre-commit hook fails, fix the underlying issue, re-stage, and create a NEW commit.
- **Never** `git push`. This skill ends at the local commit.
- **Never** stage files matching the `.gitignore` patterns by force (`git add -f`).
- If there is nothing to commit, say so and stop — don't create an empty commit.
- One commit per invocation. If the diff is clearly two unrelated changes, ask the user whether to split before committing.
