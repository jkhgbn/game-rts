---
name: wave
description: Lead playbook for one block of work on Four Wizards (JS's asks -> agents -> review -> green tests -> commit). Use when the main session starts or resumes a block of work, plans agents, or merges agent results. Not for agents.
---

# Run a block of work (lead only)

You are the lead. You plan, delegate, review, merge and check. You write only glue code and the files you own
(CLAUDE.md "Who owns what"). Work comes as JS's asks (`docs/ideas/jss_asks.md`) -> labs / agents -> green tests -> commit.

## 0. Resume
Read `docs/plan/lead-status.md` (current state), `docs/plan/owner-asks.md` (questions waiting for JS) and
`docs/plan/decisions.md` (what is already decided: never re-ask those). `git status` + `git log --oneline -15`.

## 1. Budget check first
Read the plan limits with the desktop app's usage tool (`get_usage`: weekly %, 5-hour %). Above 70 % of the
5-hour meter, or near the weekly cap: say so and offer "slow down" options instead of starting. Stop launching at
~95 % of the 5-hour meter and end the block on something JS can playtest.

## 2. Pick the work
Only asks with status `todo` / `doing` in `docs/ideas/jss_asks.md`. A new ask from JS: add its line there first.

## 3. Delegate
- Every agent: Opus 5.5 MEDIUM (`fw-art-medium` agent type, or the owner agent; never Haiku, never Fable).
- Short prompt: the ask, the files it owns (say them explicitly: unlisted agent types are not folder-checked by
  the hook), the spec to read, the "done when" list. No time box.
- Up to 6 agents at once while the 5-hour meter is under 50 % (3 above, 0 above 80 %), never two on the same files.
  Art is split into small pieces (one agent per character, building, effect family...).
- Agents never run git and never call hearthbot tools (the hooks block git for subagents).
- Relay API changes between running agents with SendMessage.

## 4. When an agent returns
1. **Review**: launch the `contract-reviewer` agent with the agent's file list and the ask. It reads the diff
   against CLAUDE.md Contracts / ownership / code style and returns PASS or a list of problems. Problems -> send
   them back to the same agent once.
2. **Tests** (see the `ci-suite` skill): `tools\ci\ci_quick.ps1 -Changed`, plus the task's own tests.
   A failure goes back to the same agent once; if it still fails, stop and tell JS.
3. **Recurring bug?** If this failure is a bug class seen before, launch a root-cause agent (separate from the fix)
   that adds a test or a rule in `.claude/hooks/check_gd.ps1` so it cannot come back (CLAUDE.md "Recurring bugs").

## 5. Green
- Set the asks' status in `docs/ideas/jss_asks.md`; add a line to `docs/plan/usage-log.md` (usage before / after).
- Commit only the finished agents' files (`C:\Program Files\Git\cmd\git.exe`, add it to PATH). Push only when JS says so.
- New decision from JS (or a lead proposal JS approved) -> one line in `docs/plan/decisions.md` with who decided.
- A question for JS -> `docs/plan/owner-asks.md`; remove it there once answered (the answer goes to decisions.md).
- Rewrite `docs/plan/lead-status.md` (state, not a log: what is running, what is uncommitted, what is next).

## 6. Tell JS
3-5 lines in Québec French: what changed and what to playtest. For a playable build, use the `playtest-release` skill.
