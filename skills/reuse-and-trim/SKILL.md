---
name: reuse-and-trim
description: Second pass over a reviewed diff — first hunt reuse of code the repo already has, then prune the diff's comments to the why each one carries. Use after /code-review or a finished implementation, and when asked to check the repo for reuse, deduplicate against it, or cut comments down.
---

# Reuse and trim

Two passes over the diff, in this order. A review hunts defects; these two hunt what a review reads
past: a helper rebuilt that the repo already had, and a comment that says what the code says.

The diff is the range the review used. Without one, the merge-base with the default branch through
`HEAD`, plus the working tree.

## Pass 1 — reuse

1. **Inventory the diff's inventions.** Every function, component, hook, type, constant, class
   string and markup block the diff introduces. One list, nothing left off it.
2. **Search the repo for each entry.** Shared packages first, then the app, then the neighbours of
   the file it sits in. Search for the behaviour, since the repo's version carries another name.
   Read what you find — a near-match with the wrong shape stays a near-match.
3. **Give every entry a verdict**: replaced by what, or kept for which reason. A verdict of kept
   names the property the existing code lacks.

A string literal an enum or constant already holds is an invention. So is a class string or a
markup block that stands a second time.

## Pass 2 — trim

1. **Inventory every comment the diff adds, moves or touches.**
2. **Apply the comment rule in force** — `CLAUDE.md`, `AGENTS.md`, or the doc they point at. That
   rule is the bar, not your taste.
3. **Give every comment a verdict**: deleted, cut to its why, or kept. Deletion is the ordinary
   outcome, and each survivor states its why in the verdict.

A comment that paraphrases a type, a signature or the line beneath it is a deletion. So is one
whose why already stands in the ticket or the commit message.

## Close out

Report both verdict tables. Apply what the user agrees to, then run the package's tests, type check
and lint. Close with the counts: inventions replaced, comments deleted.
