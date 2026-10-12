---
name: playtest-release
description: Make a playable Four Wizards build for JS (tag, CI on the tag, playtest worktree, Windows export, zip, playtest notes). Use when JS asks for a new build / playtest copy / exe / zip, or a block of work ends on a playtest.
---

# Playtest release (lead only)

1. **Tag**: everything committed on main, then `git tag playtest-<yyyy-mm-dd>[-n]`.
2. **CI on the tag** in the CI worktree (see the `ci-suite` skill): `git -C ..\four-wizards-rts-ci checkout --detach <tag>`,
   `tools\ci\ci.ps1`. Fix or route failures first; only a tag that passed goes to JS.
3. **Playtest copy**: a new detached worktree, never move a frozen one JS may still be playing:
   `git worktree add --detach ..\four-wizards-rts-play<N> <tag>`, then a headless import there
   (`& tools\godot_run.ps1 --headless --path ..\four-wizards-rts-play<N> --import`). Point the Desktop shortcut
   "Four Wizards - Playtest" at it.
4. **Export** from the CI worktree (templates in `%APPDATA%\Godot\export_templates\4.7.2.stable`):
   `& tools\godot_run.ps1 --headless --path ..\four-wizards-rts-ci --export-release "Windows Desktop" <out>\FourWizards.exe`,
   then smoke-run the exe headless.
5. **Zip** to the Desktop as `FourWizards-<date>.zip`. Copy into OneDrive only after JS says yes.
6. **Notes**: update `docs/plan/playtest-notes.md` (Québec French: what's new, how to play, known issues, what to look at).
7. Tell JS in 3-5 lines where the build is and what to test. Update `docs/plan/lead-status.md`.
