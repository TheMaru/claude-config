Chat tone — length, fragments, where prose is wanted — lives in the active output
style, not here. Two styles exist: `~/.claude/output-styles/ste-brief.md` (English,
Simplified Technical English, ASCII diagrams) and
`~/.claude/output-styles/kurz-und-einfach.md` (German). Switch with `/config`.

Only while the German style is active: "full orthographic correctness" means
diacritics (ä/ö/ü/ß) and spelling. It does not demand complete sentences — a fragment
with correct spelling is correct German.

Code comments: default to none. Most code needs no comment at all. Write one only for a
non-obvious "why" that the code itself cannot state — never to restate what the code
does. Prefer deleting a comment over shortening it.

## Skill framework (mattpocock-skills)

Most of the workflow's spine is user-invoke-only (`disable-model-invocation: true`) and never
appears in your skill list. Absence from that list is not evidence a skill is missing — check
`~/.claude/plugins/cache/mattpocock/mattpocock-skills/*/skills/**/SKILL.md` before saying so.

Main flow: `/grill-with-docs` → `/to-spec` → `/to-tickets` → `/implement`, one ticket per context
window, cleared between. `/implement` drives `/tdd` at the agreed seams, then `/code-review`, then
commits. Don't hand-roll those steps, and never substitute a visible skill for a hidden one — the
visible ones are the leaves of the flow, not the flow.

**Two additions of mine to that flow.** In `/implement`, before the first edit of a ticket,
summarize what it asks for in my words, hold it up with an illustration — ASCII mockup, state
table, before/after — and wait for my go-ahead. In `/implement-spec`, do this once up front: one
summary of all tickets with their open decisions, then wait for my go-ahead before any implementer
starts. And after `/code-review`, run `/reuse-and-trim`, both passes.

You can invoke: tdd, code-review, prototype, research, domain-modeling, codebase-design,
diagnosing-bugs, grilling, resolving-merge-conflicts, reuse-and-trim.
I must type: ask-matt, implement, to-spec, to-tickets, grill-with-docs, wayfinder, triage, handoff,
improve-codebase-architecture, grill-me, teach.
Propose these by name when they're the right step.

When unsure of the next step, say so and suggest `/ask-matt` rather than guessing.
