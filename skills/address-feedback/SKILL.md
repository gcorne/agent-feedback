---
name: address-feedback
description: Read and address line-anchored review feedback exported by agent_feedback to `.agent-feedback/feedback.md` files. Use when the user invokes `/address-feedback` or asks Codex to read, apply, resolve, or summarize feedback from `.agent-feedback/feedback.md`, especially blocks formatted as `@@ path:start_line,end_line @@` followed by reviewer comments.
---

# Address Feedback

## Overview

Use this skill to turn `.agent-feedback/feedback.md` review notes into code changes. The feedback file contains one or more blocks:

```text
@@ path/to/file.ext:start_line,end_line @@
Reviewer comment text
```

Treat paths as repo-relative unless they are absolute.

## Workflow

1. Locate the feedback file.
   - Use the path the user provides.
   - Otherwise read `.agent-feedback/feedback.md` from the current repository root.
   - If the user asks to process multiple repositories or workspaces, find each `.agent-feedback/feedback.md` and handle them separately.

2. Parse the feedback blocks.
   - A block starts with `@@ path:start_line,end_line @@`.
   - The block body continues until the next header or end of file.
   - Preserve the reviewer's wording when reasoning about intent.
   - If a header is malformed, inspect nearby text and infer only when the intended file and range are clear. Otherwise stop and ask for clarification.

3. Inspect the referenced code before editing.
   - Read each target file around the referenced line range with line numbers.
   - Group comments by file and consider all feedback for a file before patching it.
   - Check the worktree state before edits and preserve unrelated user changes.
   - If line numbers are stale, locate the intended code by nearby symbols, text, or review context rather than giving up immediately.

4. Apply focused fixes.
   - Make the smallest code, test, or documentation change that satisfies the feedback.
   - Prefer fixing the target code over editing the feedback file.
   - Do not delete, rewrite, or mark feedback as resolved unless the user explicitly asks or the repository has an established convention for doing so.
   - If feedback items conflict, choose the change that best preserves existing behavior and call out the conflict.
   - If a request is unsafe, out of scope, or impossible with the available context, leave the code unchanged for that item and explain why.

5. Verify the result.
   - Re-read the touched ranges and any related call sites affected by the change.
   - Run focused tests, formatting, or lint checks when the repository provides them.
   - If no relevant checks are available or they cannot run, say so in the final response.

6. Report back.
   - Summarize each feedback item as resolved, partially resolved, or unresolved.
   - List the changed files and the checks run.
   - Mention any assumptions, stale line mappings, skipped items, or remaining risks.
